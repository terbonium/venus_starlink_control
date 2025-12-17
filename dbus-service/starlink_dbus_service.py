#!/usr/bin/env python3
"""
Starlink D-Bus Service for VenusOS

Exposes Starlink dish status and control via D-Bus for integration
with VenusOS GUI-v2 plugins.
"""

import os
import sys
import argparse
import logging
import time
from typing import Optional

# Add path for VenusOS packages
sys.path.insert(1, '/opt/victronenergy/dbus-systemcalc-py/ext/velib_python')

try:
    from vedbus import VeDbusService
    from settingsdevice import SettingsDevice
    import dbus
    import dbus.mainloop.glib
    from gi.repository import GLib
except ImportError as e:
    print(f"Error importing VenusOS dependencies: {e}")
    print("This service is designed to run on VenusOS")
    sys.exit(1)

from starlink_grpc_client import (
    create_client, DEFAULT_DISH_ADDRESS,
    SNOW_MELT_OFF, SNOW_MELT_FORCE, SNOW_MELT_AUTO
)

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('starlink-dbus')

# Service name on D-Bus
SERVICE_NAME = 'com.victronenergy.starlink'

# Update interval in milliseconds
DEFAULT_UPDATE_INTERVAL_MS = 5000

# Command constants (for /Command path)
CMD_NONE = 0
CMD_REBOOT = 1
CMD_STOW = 2
CMD_UNSTOW = 3
CMD_ICE_OFF = 4      # Snow melt off
CMD_ICE_ON = 5       # Snow melt force on
CMD_ICE_AUTO = 6     # Snow melt auto mode


class StarlinkDbusService:
    """D-Bus service exposing Starlink dish data and controls."""

    def __init__(
        self,
        dish_address: str = DEFAULT_DISH_ADDRESS,
        mock: bool = False,
        update_interval_ms: int = DEFAULT_UPDATE_INTERVAL_MS
    ):
        """
        Initialize the Starlink D-Bus service.

        Args:
            dish_address: Address of Starlink dish (ip:port)
            mock: Use mock client for testing
            update_interval_ms: Status update interval in milliseconds
        """
        self.dish_address = dish_address
        self.update_interval_ms = update_interval_ms

        # Create gRPC client
        self.client = create_client(dish_address, mock=mock)

        # Initialize D-Bus main loop
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

        # Get D-Bus connection (always use system bus on VenusOS)
        self._dbusconn = dbus.SystemBus()

        # Create D-Bus service
        self._dbusservice = VeDbusService(SERVICE_NAME, self._dbusconn)

        # Track last known values for change detection
        self._last_status = {}

        # Register D-Bus paths
        self._register_paths()

        # Connect to dish
        if not self.client.connect():
            logger.warning("Initial connection to Starlink dish failed, will retry")

        # Schedule periodic updates
        GLib.timeout_add(self.update_interval_ms, self._update_status)

        logger.info(f"Starlink D-Bus service initialized on {SERVICE_NAME}")

    def _register_paths(self):
        """Register all D-Bus paths with the service."""

        # Management paths
        self._dbusservice.add_path('/Mgmt/ProcessName', 'starlink-dbus')
        self._dbusservice.add_path('/Mgmt/ProcessVersion', '1.0.0')
        self._dbusservice.add_path('/Mgmt/Connection', self.dish_address)

        # Product identification
        self._dbusservice.add_path('/ProductId', 0xFFFF)  # Custom product ID
        self._dbusservice.add_path('/ProductName', 'Starlink')
        self._dbusservice.add_path('/FirmwareVersion', '')
        self._dbusservice.add_path('/HardwareVersion', '')

        # Device identification
        self._dbusservice.add_path('/DeviceId', '')
        self._dbusservice.add_path('/Serial', '')

        # Connected state (0=Disconnected, 1=Connected)
        self._dbusservice.add_path('/Connected', 0)

        # Dish state (maps to Starlink state enum)
        self._dbusservice.add_path('/State', 0)
        self._dbusservice.add_path('/StateText', 'Unknown')

        # Throughput (Mbps)
        self._dbusservice.add_path('/DownlinkThroughput', 0.0)
        self._dbusservice.add_path('/UplinkThroughput', 0.0)

        # Latency
        self._dbusservice.add_path('/PopPingLatencyMs', 0.0)
        self._dbusservice.add_path('/PopPingDropRate', 0.0)

        # Obstruction
        self._dbusservice.add_path('/Obstructed', 0)
        self._dbusservice.add_path('/ObstructedPercent', 0.0)
        self._dbusservice.add_path('/FractionObstructed', 0.0)

        # Alerts (0=OK, 1=Alert)
        self._dbusservice.add_path('/Alerts/ThermalThrottle', 0)
        self._dbusservice.add_path('/Alerts/ThermalShutdown', 0)
        self._dbusservice.add_path('/Alerts/MotorsStuck', 0)
        self._dbusservice.add_path('/Alerts/MastNotVertical', 0)
        self._dbusservice.add_path('/Alerts/SlowEthernet', 0)
        self._dbusservice.add_path('/Alerts/Roaming', 0)
        self._dbusservice.add_path('/Alerts/IsHeating', 0)
        self._dbusservice.add_path('/Alerts/PowerSaveIdle', 0)

        # Uptime
        self._dbusservice.add_path('/Uptime', 0)
        self._dbusservice.add_path('/Bootcount', 0)

        # Country
        self._dbusservice.add_path('/CountryCode', '')

        # Software version
        self._dbusservice.add_path('/SoftwareVersion', '')

        # GPS data
        self._dbusservice.add_path('/Gps/Valid', 0)
        self._dbusservice.add_path('/Gps/Satellites', 0)
        self._dbusservice.add_path('/Gps/Latitude', 0.0)
        self._dbusservice.add_path('/Gps/Longitude', 0.0)
        self._dbusservice.add_path('/Gps/Altitude', 0.0)

        # Attitude/orientation data
        self._dbusservice.add_path('/Attitude/Tilt', 0.0)
        self._dbusservice.add_path('/Attitude/Azimuth', 0.0)
        self._dbusservice.add_path('/Attitude/Elevation', 0.0)
        self._dbusservice.add_path('/Attitude/Heading', 0.0)
        self._dbusservice.add_path('/Attitude/Speed', 0.0)
        self._dbusservice.add_path('/Attitude/Roll', 0.0)

        # Command path (writable) - write values to trigger commands
        self._dbusservice.add_path(
            '/Command',
            CMD_NONE,
            writeable=True,
            onchangecallback=self._on_command
        )

        # Command result (0=None, 1=Success, 2=Failed)
        self._dbusservice.add_path('/CommandResult', 0)

        logger.debug("D-Bus paths registered")

    def _on_command(self, path: str, value) -> bool:
        """
        Handle command writes to /Command path.

        Args:
            path: D-Bus path (should be '/Command')
            value: Command value (1=Reboot, 2=Stow, 3=Unstow)

        Returns:
            True to accept the value, False to reject
        """
        try:
            cmd = int(value)
        except (ValueError, TypeError):
            logger.error(f"Invalid command value: {value}")
            self._dbusservice['/CommandResult'] = 2  # Failed
            return False

        logger.info(f"Command received: {cmd}")

        result = False

        if cmd == CMD_REBOOT:
            result = self.client.reboot()
        elif cmd == CMD_STOW:
            result = self.client.stow()
        elif cmd == CMD_UNSTOW:
            result = self.client.unstow()
        elif cmd == CMD_ICE_OFF:
            result = self.client.set_snow_melt_mode(SNOW_MELT_OFF)
        elif cmd == CMD_ICE_ON:
            result = self.client.set_snow_melt_mode(SNOW_MELT_FORCE)
        elif cmd == CMD_ICE_AUTO:
            result = self.client.set_snow_melt_mode(SNOW_MELT_AUTO)
        elif cmd == CMD_NONE:
            # Reset command - always succeeds
            result = True
        else:
            logger.warning(f"Unknown command: {cmd}")

        # Update command result
        self._dbusservice['/CommandResult'] = 1 if result else 2

        # Reset command to none after processing
        if cmd != CMD_NONE:
            GLib.timeout_add(500, lambda: self._reset_command())

        return True

    def _reset_command(self):
        """Reset command path to none after processing."""
        self._dbusservice['/Command'] = CMD_NONE
        return False  # Don't repeat

    def _update_status(self) -> bool:
        """
        Update D-Bus paths with current Starlink status.

        Returns:
            True to continue periodic updates
        """
        status = self.client.get_status()

        if status is None:
            # Connection failed
            self._dbusservice['/Connected'] = 0
            self._dbusservice['/StateText'] = 'Disconnected'

            # Try to reconnect
            self.client.connect()

            return True  # Continue updates

        # Update connected state
        self._dbusservice['/Connected'] = 1

        # Update device info
        self._dbusservice['/DeviceId'] = status.get('device_id', '')
        self._dbusservice['/Serial'] = status.get('device_id', '')
        self._dbusservice['/HardwareVersion'] = status.get('hardware_version', '')
        self._dbusservice['/SoftwareVersion'] = status.get('software_version', '')
        self._dbusservice['/FirmwareVersion'] = status.get('software_version', '')

        # Update state
        self._dbusservice['/State'] = status.get('state', 0)
        self._dbusservice['/StateText'] = status.get('state_text', 'Unknown')

        # Update throughput
        self._dbusservice['/DownlinkThroughput'] = round(status.get('downlink_throughput_mbps', 0), 2)
        self._dbusservice['/UplinkThroughput'] = round(status.get('uplink_throughput_mbps', 0), 2)

        # Update latency
        self._dbusservice['/PopPingLatencyMs'] = round(status.get('pop_ping_latency_ms', 0), 1)
        self._dbusservice['/PopPingDropRate'] = round(status.get('pop_ping_drop_rate', 0), 4)

        # Update obstruction
        self._dbusservice['/Obstructed'] = 1 if status.get('currently_obstructed', False) else 0
        self._dbusservice['/ObstructedPercent'] = round(status.get('percent_obstructed', 0), 2)
        self._dbusservice['/FractionObstructed'] = round(status.get('fraction_obstructed', 0), 4)

        # Update alerts
        self._dbusservice['/Alerts/ThermalThrottle'] = 1 if status.get('thermal_throttle', False) else 0
        self._dbusservice['/Alerts/ThermalShutdown'] = 1 if status.get('thermal_shutdown', False) else 0
        self._dbusservice['/Alerts/MotorsStuck'] = 1 if status.get('motors_stuck', False) else 0
        self._dbusservice['/Alerts/MastNotVertical'] = 1 if status.get('mast_not_vertical', False) else 0
        self._dbusservice['/Alerts/SlowEthernet'] = 1 if status.get('slow_ethernet', False) else 0
        self._dbusservice['/Alerts/Roaming'] = 1 if status.get('roaming', False) else 0
        self._dbusservice['/Alerts/IsHeating'] = 1 if status.get('is_heating', False) else 0
        self._dbusservice['/Alerts/PowerSaveIdle'] = 1 if status.get('power_save_idle', False) else 0

        # Update other info
        self._dbusservice['/Uptime'] = status.get('uptime_s', 0)
        self._dbusservice['/Bootcount'] = status.get('bootcount', 0)
        self._dbusservice['/CountryCode'] = status.get('country_code', '')

        # Update GPS data
        self._dbusservice['/Gps/Valid'] = 1 if status.get('gps_valid', False) else 0
        self._dbusservice['/Gps/Satellites'] = status.get('gps_sats', 0)
        self._dbusservice['/Gps/Latitude'] = round(status.get('latitude', 0.0), 6)
        self._dbusservice['/Gps/Longitude'] = round(status.get('longitude', 0.0), 6)
        self._dbusservice['/Gps/Altitude'] = round(status.get('altitude_m', 0.0), 1)

        # Update attitude/orientation data
        self._dbusservice['/Attitude/Tilt'] = round(status.get('tilt_angle_deg', 0.0), 2)
        self._dbusservice['/Attitude/Azimuth'] = round(status.get('boresight_azimuth_deg', 0.0), 1)
        self._dbusservice['/Attitude/Elevation'] = round(status.get('boresight_elevation_deg', 0.0), 1)
        self._dbusservice['/Attitude/Heading'] = round(status.get('heading_deg', 0.0), 1)
        self._dbusservice['/Attitude/Speed'] = round(status.get('speed_mps', 0.0), 2)
        self._dbusservice['/Attitude/Roll'] = round(status.get('roll_deg', 0.0), 2)

        return True  # Continue periodic updates

    def run(self):
        """Run the D-Bus service main loop."""
        logger.info("Starting Starlink D-Bus service main loop")
        mainloop = GLib.MainLoop()

        try:
            mainloop.run()
        except KeyboardInterrupt:
            logger.info("Received keyboard interrupt, shutting down")
        finally:
            self.client.disconnect()


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Starlink D-Bus Service for VenusOS'
    )
    parser.add_argument(
        '--address',
        default=DEFAULT_DISH_ADDRESS,
        help=f'Starlink dish address (default: {DEFAULT_DISH_ADDRESS})'
    )
    parser.add_argument(
        '--mock',
        action='store_true',
        help='Use mock client for testing'
    )
    parser.add_argument(
        '--interval',
        type=int,
        default=DEFAULT_UPDATE_INTERVAL_MS,
        help=f'Status update interval in ms (default: {DEFAULT_UPDATE_INTERVAL_MS})'
    )
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Enable debug logging'
    )

    args = parser.parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    service = StarlinkDbusService(
        dish_address=args.address,
        mock=args.mock,
        update_interval_ms=args.interval
    )
    service.run()


if __name__ == '__main__':
    main()
