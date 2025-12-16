/*
 * Starlink Detailed Status Page for VenusOS GUI-v2
 *
 * Shows comprehensive dish statistics and status information.
 */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    title: qsTr("Starlink Status")

    // D-Bus service binding
    readonly property string serviceUid: "com.victronenergy.starlink"

    // Data item bindings - Connection
    readonly property var _connected: VeQuickItem { uid: root.serviceUid + "/Connected" }
    readonly property var _state: VeQuickItem { uid: root.serviceUid + "/State" }
    readonly property var _stateText: VeQuickItem { uid: root.serviceUid + "/StateText" }

    // Throughput
    readonly property var _downlink: VeQuickItem { uid: root.serviceUid + "/DownlinkThroughput" }
    readonly property var _uplink: VeQuickItem { uid: root.serviceUid + "/UplinkThroughput" }

    // Latency
    readonly property var _latency: VeQuickItem { uid: root.serviceUid + "/PopPingLatencyMs" }
    readonly property var _dropRate: VeQuickItem { uid: root.serviceUid + "/PopPingDropRate" }

    // Obstruction
    readonly property var _obstructed: VeQuickItem { uid: root.serviceUid + "/Obstructed" }
    readonly property var _obstructedPercent: VeQuickItem { uid: root.serviceUid + "/ObstructedPercent" }
    readonly property var _fractionObstructed: VeQuickItem { uid: root.serviceUid + "/FractionObstructed" }

    // Device info
    readonly property var _deviceId: VeQuickItem { uid: root.serviceUid + "/DeviceId" }
    readonly property var _softwareVersion: VeQuickItem { uid: root.serviceUid + "/SoftwareVersion" }
    readonly property var _hardwareVersion: VeQuickItem { uid: root.serviceUid + "/HardwareVersion" }
    readonly property var _countryCode: VeQuickItem { uid: root.serviceUid + "/CountryCode" }
    readonly property var _uptime: VeQuickItem { uid: root.serviceUid + "/Uptime" }
    readonly property var _bootcount: VeQuickItem { uid: root.serviceUid + "/Bootcount" }

    // Alerts
    readonly property var _thermalThrottle: VeQuickItem { uid: root.serviceUid + "/Alerts/ThermalThrottle" }
    readonly property var _thermalShutdown: VeQuickItem { uid: root.serviceUid + "/Alerts/ThermalShutdown" }
    readonly property var _motorsStuck: VeQuickItem { uid: root.serviceUid + "/Alerts/MotorsStuck" }
    readonly property var _mastNotVertical: VeQuickItem { uid: root.serviceUid + "/Alerts/MastNotVertical" }
    readonly property var _slowEthernet: VeQuickItem { uid: root.serviceUid + "/Alerts/SlowEthernet" }
    readonly property var _roaming: VeQuickItem { uid: root.serviceUid + "/Alerts/Roaming" }
    readonly property var _heating: VeQuickItem { uid: root.serviceUid + "/Alerts/IsHeating" }
    readonly property var _powerSaveIdle: VeQuickItem { uid: root.serviceUid + "/Alerts/PowerSaveIdle" }

    // GPS data
    readonly property var _gpsValid: VeQuickItem { uid: root.serviceUid + "/Gps/Valid" }
    readonly property var _gpsSatellites: VeQuickItem { uid: root.serviceUid + "/Gps/Satellites" }
    readonly property var _gpsLatitude: VeQuickItem { uid: root.serviceUid + "/Gps/Latitude" }
    readonly property var _gpsLongitude: VeQuickItem { uid: root.serviceUid + "/Gps/Longitude" }
    readonly property var _gpsAltitude: VeQuickItem { uid: root.serviceUid + "/Gps/Altitude" }

    // Attitude/orientation data
    readonly property var _tilt: VeQuickItem { uid: root.serviceUid + "/Attitude/Tilt" }
    readonly property var _azimuth: VeQuickItem { uid: root.serviceUid + "/Attitude/Azimuth" }
    readonly property var _elevation: VeQuickItem { uid: root.serviceUid + "/Attitude/Elevation" }
    readonly property var _heading: VeQuickItem { uid: root.serviceUid + "/Attitude/Heading" }
    readonly property var _speed: VeQuickItem { uid: root.serviceUid + "/Attitude/Speed" }
    readonly property var _roll: VeQuickItem { uid: root.serviceUid + "/Attitude/Roll" }

    // Helper functions
    function formatUptime(seconds) {
        if (seconds === undefined || seconds === null) return "--"
        var days = Math.floor(seconds / 86400)
        var hours = Math.floor((seconds % 86400) / 3600)
        var mins = Math.floor((seconds % 3600) / 60)
        var secs = seconds % 60
        if (days > 0) {
            return qsTr("%1d %2h %3m").arg(days).arg(hours).arg(mins)
        } else if (hours > 0) {
            return qsTr("%1h %2m %3s").arg(hours).arg(mins).arg(secs)
        } else if (mins > 0) {
            return qsTr("%1m %2s").arg(mins).arg(secs)
        } else {
            return qsTr("%1s").arg(secs)
        }
    }

    function formatThroughput(mbps) {
        if (mbps === undefined || mbps === null) return "--"
        return Number(mbps).toFixed(2) + " Mbps"
    }

    function formatPercent(value) {
        if (value === undefined || value === null) return "--"
        return Number(value).toFixed(2) + "%"
    }

    function alertStatus(value) {
        return value === 1 ? qsTr("Yes") : qsTr("No")
    }

    function formatCoordinate(value, isLatitude) {
        if (value === undefined || value === null || value === 0) return "--"
        var absVal = Math.abs(value)
        var degrees = Math.floor(absVal)
        var minutes = (absVal - degrees) * 60
        var direction = isLatitude ? (value >= 0 ? "N" : "S") : (value >= 0 ? "E" : "W")
        return qsTr("%1° %2' %3").arg(degrees).arg(minutes.toFixed(3)).arg(direction)
    }

    function formatDegrees(value) {
        if (value === undefined || value === null) return "--"
        return Number(value).toFixed(1) + "°"
    }

    function formatSpeed(mps) {
        if (mps === undefined || mps === null) return "--"
        // Convert m/s to knots for marine use
        var knots = mps * 1.94384
        return Number(knots).toFixed(1) + " kn"
    }

    GradientListView {
        model: ObjectModel {

            // Connection Status Section
            ListItem {
                text: qsTr("Connection")
                content.children: [
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: _connected.value === 1 ? qsTr("Connected") : qsTr("Disconnected")
                        color: _connected.value === 1 ? Theme.color_green : Theme.color_red
                    }
                ]
            }

            ListTextItem {
                text: qsTr("Dish State")
                secondaryText: _stateText.value || "--"
            }

            // Throughput Section Header
            ListItem {
                text: qsTr("Network Performance")
            }

            ListTextItem {
                text: qsTr("Download Speed")
                secondaryText: formatThroughput(_downlink.value)
            }

            ListTextItem {
                text: qsTr("Upload Speed")
                secondaryText: formatThroughput(_uplink.value)
            }

            ListTextItem {
                text: qsTr("Latency (to PoP)")
                secondaryText: {
                    if (_latency.value === undefined || _latency.value === null) return "--"
                    return Number(_latency.value).toFixed(1) + " ms"
                }
            }

            ListTextItem {
                text: qsTr("Packet Drop Rate")
                secondaryText: {
                    if (_dropRate.value === undefined || _dropRate.value === null) return "--"
                    return (Number(_dropRate.value) * 100).toFixed(2) + "%"
                }
            }

            // Obstruction Section Header
            ListItem {
                text: qsTr("Obstruction Status")
            }

            ListTextItem {
                text: qsTr("Currently Obstructed")
                secondaryText: _obstructed.value === 1 ? qsTr("Yes") : qsTr("No")
            }

            ListTextItem {
                text: qsTr("Obstruction Percentage")
                secondaryText: formatPercent(_obstructedPercent.value)
            }

            ListTextItem {
                text: qsTr("Fraction Obstructed")
                secondaryText: {
                    if (_fractionObstructed.value === undefined) return "--"
                    return Number(_fractionObstructed.value).toFixed(4)
                }
            }

            // GPS Section Header
            ListItem {
                text: qsTr("GPS Location")
            }

            ListTextItem {
                text: qsTr("GPS Status")
                secondaryText: _gpsValid.value === 1 ? qsTr("Valid (%1 sats)").arg(_gpsSatellites.value || 0) : qsTr("No Fix")
                secondaryLabel.color: _gpsValid.value === 1 ? Theme.color_green : Theme.color_font_secondary
            }

            ListTextItem {
                text: qsTr("Latitude")
                secondaryText: formatCoordinate(_gpsLatitude.value, true)
            }

            ListTextItem {
                text: qsTr("Longitude")
                secondaryText: formatCoordinate(_gpsLongitude.value, false)
            }

            ListTextItem {
                text: qsTr("Altitude")
                secondaryText: {
                    if (_gpsAltitude.value === undefined || _gpsAltitude.value === null) return "--"
                    return Number(_gpsAltitude.value).toFixed(1) + " m"
                }
            }

            // Attitude Section Header
            ListItem {
                text: qsTr("Dish Orientation")
            }

            ListTextItem {
                text: qsTr("Heading (COG)")
                secondaryText: formatDegrees(_heading.value)
            }

            ListTextItem {
                text: qsTr("Tilt")
                secondaryText: formatDegrees(_tilt.value)
            }

            ListTextItem {
                text: qsTr("Roll")
                secondaryText: formatDegrees(_roll.value)
            }

            ListTextItem {
                text: qsTr("Boresight Azimuth")
                secondaryText: formatDegrees(_azimuth.value)
            }

            ListTextItem {
                text: qsTr("Boresight Elevation")
                secondaryText: formatDegrees(_elevation.value)
            }

            ListTextItem {
                text: qsTr("Speed (SOG)")
                secondaryText: formatSpeed(_speed.value)
            }

            // Device Info Section Header
            ListItem {
                text: qsTr("Device Information")
            }

            ListTextItem {
                text: qsTr("Device ID")
                secondaryText: _deviceId.value || "--"
            }

            ListTextItem {
                text: qsTr("Hardware Version")
                secondaryText: _hardwareVersion.value || "--"
            }

            ListTextItem {
                text: qsTr("Software Version")
                secondaryText: _softwareVersion.value || "--"
            }

            ListTextItem {
                text: qsTr("Country Code")
                secondaryText: _countryCode.value || "--"
            }

            ListTextItem {
                text: qsTr("Uptime")
                secondaryText: formatUptime(_uptime.value)
            }

            ListTextItem {
                text: qsTr("Boot Count")
                secondaryText: _bootcount.value !== undefined ? String(_bootcount.value) : "--"
            }

            // Alerts Section Header
            ListItem {
                text: qsTr("Alerts & Warnings")
            }

            ListTextItem {
                text: qsTr("Thermal Throttle")
                secondaryText: alertStatus(_thermalThrottle.value)
                secondaryLabel.color: _thermalThrottle.value === 1 ? Theme.color_orange : Theme.color_font_secondary
            }

            ListTextItem {
                text: qsTr("Thermal Shutdown")
                secondaryText: alertStatus(_thermalShutdown.value)
                secondaryLabel.color: _thermalShutdown.value === 1 ? Theme.color_red : Theme.color_font_secondary
            }

            ListTextItem {
                text: qsTr("Motors Stuck")
                secondaryText: alertStatus(_motorsStuck.value)
                secondaryLabel.color: _motorsStuck.value === 1 ? Theme.color_red : Theme.color_font_secondary
            }

            ListTextItem {
                text: qsTr("Mast Not Vertical")
                secondaryText: alertStatus(_mastNotVertical.value)
                secondaryLabel.color: _mastNotVertical.value === 1 ? Theme.color_orange : Theme.color_font_secondary
            }

            ListTextItem {
                text: qsTr("Slow Ethernet")
                secondaryText: alertStatus(_slowEthernet.value)
                secondaryLabel.color: _slowEthernet.value === 1 ? Theme.color_orange : Theme.color_font_secondary
            }

            ListTextItem {
                text: qsTr("Roaming")
                secondaryText: alertStatus(_roaming.value)
            }

            ListTextItem {
                text: qsTr("Heating Active")
                secondaryText: alertStatus(_heating.value)
            }

            ListTextItem {
                text: qsTr("Power Save Idle")
                secondaryText: alertStatus(_powerSaveIdle.value)
            }
        }
    }
}
