#!/usr/bin/env python3
"""
Starlink Web Dashboard Server

Simple web server that reads from the D-Bus service and serves
a browser-accessible dashboard for Starlink monitoring and control.
"""

import os
import sys
import json
import logging
import argparse
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# Add VenusOS packages path
sys.path.insert(1, '/opt/victronenergy/dbus-systemcalc-py/ext/velib_python')

try:
    import dbus
    DBUS_AVAILABLE = True
except ImportError:
    dbus = None
    DBUS_AVAILABLE = False

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('starlink-web')

# D-Bus service name
SERVICE_NAME = 'com.victronenergy.starlink'

# Web server defaults
DEFAULT_PORT = 8088
DEFAULT_HOST = '0.0.0.0'


class StarlinkDbusReader:
    """Reads Starlink data from D-Bus service."""

    def __init__(self):
        self._bus = None
        self._service = None

    def connect(self) -> bool:
        """Connect to D-Bus."""
        if not DBUS_AVAILABLE:
            logger.error("dbus module not available")
            return False

        try:
            self._bus = dbus.SystemBus()
            return True
        except Exception as e:
            logger.error(f"Failed to connect to D-Bus: {e}")
            return False

    def get_value(self, path: str):
        """Get a single value from D-Bus."""
        if not self._bus:
            if not self.connect():
                return None

        try:
            obj = self._bus.get_object(SERVICE_NAME, path)
            return obj.GetValue()
        except dbus.exceptions.DBusException as e:
            if 'UnknownObject' in str(e) or 'ServiceUnknown' in str(e):
                return None
            logger.debug(f"D-Bus error for {path}: {e}")
            return None
        except Exception as e:
            logger.debug(f"Error getting {path}: {e}")
            return None

    def get_all_status(self) -> dict:
        """Get all Starlink status data."""
        paths = {
            # Connection
            'connected': '/Connected',
            'state': '/State',
            'stateText': '/StateText',

            # Device info
            'deviceId': '/DeviceId',
            'hardwareVersion': '/HardwareVersion',
            'softwareVersion': '/SoftwareVersion',
            'countryCode': '/CountryCode',

            # Performance
            'downlinkThroughput': '/DownlinkThroughput',
            'uplinkThroughput': '/UplinkThroughput',
            'popPingLatencyMs': '/PopPingLatencyMs',
            'popPingDropRate': '/PopPingDropRate',

            # Obstruction
            'obstructed': '/Obstructed',
            'obstructedPercent': '/ObstructedPercent',
            'fractionObstructed': '/FractionObstructed',

            # Uptime
            'uptime': '/Uptime',
            'bootcount': '/Bootcount',

            # GPS
            'gpsValid': '/Gps/Valid',
            'gpsSatellites': '/Gps/Satellites',
            'latitude': '/Gps/Latitude',
            'longitude': '/Gps/Longitude',
            'altitude': '/Gps/Altitude',

            # Attitude
            'heading': '/Attitude/Heading',
            'tilt': '/Attitude/Tilt',
            'roll': '/Attitude/Roll',
            'azimuth': '/Attitude/Azimuth',
            'elevation': '/Attitude/Elevation',
            'speed': '/Attitude/Speed',

            # Alerts
            'alertThermalThrottle': '/Alerts/ThermalThrottle',
            'alertThermalShutdown': '/Alerts/ThermalShutdown',
            'alertMotorsStuck': '/Alerts/MotorsStuck',
            'alertMastNotVertical': '/Alerts/MastNotVertical',
            'alertSlowEthernet': '/Alerts/SlowEthernet',
            'alertRoaming': '/Alerts/Roaming',
            'alertIsHeating': '/Alerts/IsHeating',
            'alertPowerSaveIdle': '/Alerts/PowerSaveIdle',

            # Command status
            'commandResult': '/CommandResult',
        }

        result = {}
        for key, path in paths.items():
            value = self.get_value(path)
            # Convert dbus types to Python types
            if value is not None:
                if isinstance(value, dbus.String):
                    value = str(value)
                elif isinstance(value, (dbus.Int32, dbus.Int64, dbus.UInt32, dbus.UInt64)):
                    value = int(value)
                elif isinstance(value, dbus.Double):
                    value = float(value)
                elif isinstance(value, dbus.Boolean):
                    value = bool(value)
            result[key] = value

        return result

    def send_command(self, command: int) -> bool:
        """Send a command to the dish."""
        if not self._bus:
            if not self.connect():
                return False

        try:
            obj = self._bus.get_object(SERVICE_NAME, '/Command')
            obj.SetValue(dbus.Int32(command))
            return True
        except Exception as e:
            logger.error(f"Failed to send command: {e}")
            return False


# Global D-Bus reader instance
dbus_reader = StarlinkDbusReader()


class StarlinkRequestHandler(SimpleHTTPRequestHandler):
    """HTTP request handler for Starlink dashboard."""

    def __init__(self, *args, **kwargs):
        # Set the directory for static files
        self.directory = os.path.dirname(os.path.abspath(__file__))
        super().__init__(*args, directory=self.directory, **kwargs)

    def do_GET(self):
        """Handle GET requests."""
        parsed = urlparse(self.path)

        if parsed.path == '/api/status':
            self.send_json_response(dbus_reader.get_all_status())
        elif parsed.path == '/' or parsed.path == '/index.html':
            self.serve_dashboard()
        else:
            super().do_GET()

    def do_POST(self):
        """Handle POST requests."""
        parsed = urlparse(self.path)

        if parsed.path == '/api/command':
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode('utf-8')

            try:
                data = json.loads(body)
                command = int(data.get('command', 0))

                if command in [1, 2, 3]:  # Reboot, Stow, Unstow
                    success = dbus_reader.send_command(command)
                    self.send_json_response({'success': success})
                else:
                    self.send_json_response({'success': False, 'error': 'Invalid command'}, 400)
            except Exception as e:
                self.send_json_response({'success': False, 'error': str(e)}, 500)
        else:
            self.send_error(404)

    def send_json_response(self, data: dict, status: int = 200):
        """Send a JSON response."""
        response = json.dumps(data)
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', len(response))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(response.encode('utf-8'))

    def serve_dashboard(self):
        """Serve the main dashboard HTML."""
        html_path = os.path.join(self.directory, 'index.html')
        if os.path.exists(html_path):
            with open(html_path, 'rb') as f:
                content = f.read()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.send_header('Content-Length', len(content))
            self.end_headers()
            self.wfile.write(content)
        else:
            self.send_error(404, "Dashboard not found")

    def log_message(self, format, *args):
        """Override to use our logger."""
        logger.debug("%s - %s", self.address_string(), format % args)


def main():
    parser = argparse.ArgumentParser(description='Starlink Web Dashboard Server')
    parser.add_argument('--host', default=DEFAULT_HOST, help=f'Host to bind to (default: {DEFAULT_HOST})')
    parser.add_argument('--port', type=int, default=DEFAULT_PORT, help=f'Port to listen on (default: {DEFAULT_PORT})')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')

    args = parser.parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    # Connect to D-Bus
    if not dbus_reader.connect():
        logger.warning("Could not connect to D-Bus, will retry on requests")

    # Start web server
    server = HTTPServer((args.host, args.port), StarlinkRequestHandler)
    logger.info(f"Starlink Web Dashboard running at http://{args.host}:{args.port}")
    logger.info("Access from browser: http://<device-ip>:%d", args.port)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down")
        server.shutdown()


if __name__ == '__main__':
    main()
