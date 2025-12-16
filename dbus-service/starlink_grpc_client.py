#!/usr/bin/env python3
"""
Starlink gRPC Client

Communicates with Starlink dish via gRPC to retrieve status
and send commands (reboot, stow/unstow).
"""

import logging
import grpc
from typing import Optional, Dict, Any

# These will be generated from proto files
try:
    from spacex.api.device import device_pb2
    from spacex.api.device import device_pb2_grpc
    from spacex.api.device import dish_pb2
except ImportError:
    # Fallback for development/testing
    device_pb2 = None
    device_pb2_grpc = None
    dish_pb2 = None

logger = logging.getLogger(__name__)

# Default Starlink dish address
DEFAULT_DISH_ADDRESS = "192.168.100.1:9200"

# State mapping from protobuf enum to human-readable
STATE_MAP = {
    0: "Unknown",
    1: "Connected",
    2: "Booting",
    3: "Searching",
    4: "Stowed",
    5: "Thermal Shutdown",
    6: "No Satellites",
    7: "Obstructed",
    8: "No Downlink",
    9: "No Pings",
    10: "Disabled",
    11: "Faulted",
    12: "Cable Test",
    13: "Actuator Motor Stopped",
    14: "Moving Fast",
    15: "Too Far From Service Address",
    16: "No Active Account",
    17: "Sleeping",
    18: "Moving While Not Mobile",
}


class StarlinkGrpcClient:
    """Client for communicating with Starlink dish via gRPC."""

    def __init__(self, address: str = DEFAULT_DISH_ADDRESS, timeout: float = 10.0):
        """
        Initialize the Starlink gRPC client.

        Args:
            address: Starlink dish address (ip:port)
            timeout: gRPC call timeout in seconds
        """
        self.address = address
        self.timeout = timeout
        self._channel: Optional[grpc.Channel] = None
        self._stub = None

    def connect(self) -> bool:
        """
        Establish connection to the Starlink dish.

        Returns:
            True if connection successful, False otherwise
        """
        if device_pb2_grpc is None:
            logger.error("gRPC protobuf modules not available")
            return False

        try:
            self._channel = grpc.insecure_channel(self.address)
            self._stub = device_pb2_grpc.DeviceStub(self._channel)
            logger.info(f"Connected to Starlink dish at {self.address}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to Starlink dish: {e}")
            return False

    def disconnect(self):
        """Close the gRPC channel."""
        if self._channel:
            self._channel.close()
            self._channel = None
            self._stub = None
            logger.info("Disconnected from Starlink dish")

    def get_status(self) -> Optional[Dict[str, Any]]:
        """
        Get dish status information.

        Returns:
            Dictionary with status data or None on failure
        """
        if not self._stub:
            if not self.connect():
                return None

        try:
            # Create request for dish status
            request = device_pb2.Request(
                dish_get_status=device_pb2.DishGetStatusRequest()
            )

            # Make gRPC call
            response = self._stub.Handle(request, timeout=self.timeout)

            if response.status != device_pb2.STATUS_OK:
                logger.error(f"Dish status request failed: {response.status}")
                return None

            dish_status = response.dish_get_status
            device_info = dish_status.device_info

            # Extract state
            state_value = 0
            if dish_status.HasField('device_state'):
                state_value = dish_status.device_state.state

            # Parse alerts
            alerts = dish_status.alerts if dish_status.HasField('alerts') else None
            obstruction = dish_status.obstruction_stats if dish_status.HasField('obstruction_stats') else None

            return {
                # Device info
                "device_id": device_info.id,
                "hardware_version": device_info.hardware_version,
                "software_version": device_info.software_version,
                "country_code": device_info.country_code,
                "bootcount": device_info.bootcount,

                # State
                "state": state_value,
                "state_text": STATE_MAP.get(state_value, "Unknown"),

                # Throughput (convert from bps to Mbps)
                "downlink_throughput_mbps": dish_status.downlink_throughput_bps / 1_000_000,
                "uplink_throughput_mbps": dish_status.uplink_throughput_bps / 1_000_000,

                # Latency
                "pop_ping_latency_ms": dish_status.pop_ping_latency_ms,
                "pop_ping_drop_rate": dish_status.pop_ping_drop_rate,

                # Obstruction
                "currently_obstructed": obstruction.currently_obstructed if obstruction else False,
                "fraction_obstructed": obstruction.fraction_obstructed if obstruction else 0.0,
                "seconds_obstructed": dish_status.seconds_obstructed,
                "percent_obstructed": dish_status.percent_obstructed,

                # Alerts
                "thermal_throttle": alerts.thermal_throttle if alerts else False,
                "thermal_shutdown": alerts.thermal_shutdown if alerts else False,
                "motors_stuck": alerts.motors_stuck if alerts else False,
                "mast_not_vertical": alerts.mast_not_near_vertical if alerts else False,
                "slow_ethernet": alerts.slow_ethernet_speeds if alerts else False,
                "roaming": alerts.roaming if alerts else False,
                "is_heating": alerts.is_heating if alerts else False,
                "power_save_idle": alerts.is_power_save_idle if alerts else False,

                # Uptime (bootcount approximation - actual uptime from dish)
                "uptime_s": 0,  # Will be populated from device telemetry if available
            }

        except grpc.RpcError as e:
            logger.error(f"gRPC error getting dish status: {e}")
            return None
        except Exception as e:
            logger.error(f"Error getting dish status: {e}")
            return None

    def reboot(self) -> bool:
        """
        Reboot the Starlink dish.

        Returns:
            True if reboot command successful, False otherwise
        """
        if not self._stub:
            if not self.connect():
                return False

        try:
            request = device_pb2.Request(
                reboot=device_pb2.RebootRequest()
            )

            response = self._stub.Handle(request, timeout=self.timeout)

            if response.status == device_pb2.STATUS_OK:
                logger.info("Reboot command sent successfully")
                return True
            else:
                logger.error(f"Reboot command failed: {response.status}")
                return False

        except grpc.RpcError as e:
            logger.error(f"gRPC error sending reboot: {e}")
            return False
        except Exception as e:
            logger.error(f"Error sending reboot: {e}")
            return False

    def stow(self) -> bool:
        """
        Stow the Starlink dish.

        Returns:
            True if stow command successful, False otherwise
        """
        if not self._stub:
            if not self.connect():
                return False

        try:
            request = device_pb2.Request(
                dish_stow=device_pb2.DishStowRequest(unstow=False)
            )

            response = self._stub.Handle(request, timeout=self.timeout)

            if response.status == device_pb2.STATUS_OK:
                logger.info("Stow command sent successfully")
                return True
            else:
                logger.error(f"Stow command failed: {response.status}")
                return False

        except grpc.RpcError as e:
            logger.error(f"gRPC error sending stow: {e}")
            return False
        except Exception as e:
            logger.error(f"Error sending stow: {e}")
            return False

    def unstow(self) -> bool:
        """
        Unstow the Starlink dish.

        Returns:
            True if unstow command successful, False otherwise
        """
        if not self._stub:
            if not self.connect():
                return False

        try:
            request = device_pb2.Request(
                dish_stow=device_pb2.DishStowRequest(unstow=True)
            )

            response = self._stub.Handle(request, timeout=self.timeout)

            if response.status == device_pb2.STATUS_OK:
                logger.info("Unstow command sent successfully")
                return True
            else:
                logger.error(f"Unstow command failed: {response.status}")
                return False

        except grpc.RpcError as e:
            logger.error(f"gRPC error sending unstow: {e}")
            return False
        except Exception as e:
            logger.error(f"Error sending unstow: {e}")
            return False


# For testing without actual dish connection
class MockStarlinkGrpcClient:
    """Mock client for testing without a real Starlink dish."""

    def __init__(self, address: str = DEFAULT_DISH_ADDRESS, timeout: float = 10.0):
        self.address = address
        self.timeout = timeout
        self._connected = False
        self._stowed = False

    def connect(self) -> bool:
        self._connected = True
        logger.info(f"[MOCK] Connected to Starlink dish at {self.address}")
        return True

    def disconnect(self):
        self._connected = False
        logger.info("[MOCK] Disconnected from Starlink dish")

    def get_status(self) -> Optional[Dict[str, Any]]:
        import random

        state = 4 if self._stowed else 1  # Stowed or Connected

        return {
            "device_id": "ut01000000-00000000-00000000",
            "hardware_version": "rev3_proto2",
            "software_version": "2024.01.01.mr12345",
            "country_code": "US",
            "bootcount": 42,
            "state": state,
            "state_text": STATE_MAP.get(state, "Unknown"),
            "downlink_throughput_mbps": random.uniform(50, 250),
            "uplink_throughput_mbps": random.uniform(5, 30),
            "pop_ping_latency_ms": random.uniform(20, 60),
            "pop_ping_drop_rate": random.uniform(0, 0.02),
            "currently_obstructed": False,
            "fraction_obstructed": random.uniform(0, 0.05),
            "seconds_obstructed": random.uniform(0, 100),
            "percent_obstructed": random.uniform(0, 5),
            "thermal_throttle": False,
            "thermal_shutdown": False,
            "motors_stuck": False,
            "mast_not_vertical": False,
            "slow_ethernet": False,
            "roaming": False,
            "is_heating": False,
            "power_save_idle": False,
            "uptime_s": random.randint(1000, 100000),
        }

    def reboot(self) -> bool:
        logger.info("[MOCK] Reboot command sent")
        return True

    def stow(self) -> bool:
        self._stowed = True
        logger.info("[MOCK] Stow command sent")
        return True

    def unstow(self) -> bool:
        self._stowed = False
        logger.info("[MOCK] Unstow command sent")
        return True


def create_client(address: str = DEFAULT_DISH_ADDRESS, mock: bool = False) -> StarlinkGrpcClient:
    """
    Factory function to create appropriate Starlink client.

    Args:
        address: Starlink dish address
        mock: If True, create mock client for testing

    Returns:
        StarlinkGrpcClient or MockStarlinkGrpcClient instance
    """
    if mock:
        return MockStarlinkGrpcClient(address)
    return StarlinkGrpcClient(address)
