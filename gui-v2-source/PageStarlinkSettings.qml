/*
 * Starlink Settings Page for VenusOS GUI-v2
 *
 * Main integration page displayed under Settings -> Integrations -> Starlink
 * Shows dish status, stats, and control buttons.
 */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    // D-Bus service binding
    readonly property string serviceUid: "com.victronenergy.starlink"

    // Data item bindings
    readonly property var _connected: VeQuickItem { uid: root.serviceUid + "/Connected" }
    readonly property var _state: VeQuickItem { uid: root.serviceUid + "/State" }
    readonly property var _stateText: VeQuickItem { uid: root.serviceUid + "/StateText" }
    readonly property var _downlink: VeQuickItem { uid: root.serviceUid + "/DownlinkThroughput" }
    readonly property var _uplink: VeQuickItem { uid: root.serviceUid + "/UplinkThroughput" }
    readonly property var _latency: VeQuickItem { uid: root.serviceUid + "/PopPingLatencyMs" }
    readonly property var _obstructed: VeQuickItem { uid: root.serviceUid + "/Obstructed" }
    readonly property var _obstructedPercent: VeQuickItem { uid: root.serviceUid + "/ObstructedPercent" }
    readonly property var _deviceId: VeQuickItem { uid: root.serviceUid + "/DeviceId" }
    readonly property var _softwareVersion: VeQuickItem { uid: root.serviceUid + "/SoftwareVersion" }
    readonly property var _hardwareVersion: VeQuickItem { uid: root.serviceUid + "/HardwareVersion" }
    readonly property var _uptime: VeQuickItem { uid: root.serviceUid + "/Uptime" }
    readonly property var _command: VeQuickItem { uid: root.serviceUid + "/Command" }
    readonly property var _commandResult: VeQuickItem { uid: root.serviceUid + "/CommandResult" }

    // Alerts
    readonly property var _thermalThrottle: VeQuickItem { uid: root.serviceUid + "/Alerts/ThermalThrottle" }
    readonly property var _heating: VeQuickItem { uid: root.serviceUid + "/Alerts/IsHeating" }
    readonly property var _roaming: VeQuickItem { uid: root.serviceUid + "/Alerts/Roaming" }

    // Helper functions
    function formatUptime(seconds) {
        if (seconds === undefined || seconds === null) return "--"
        var days = Math.floor(seconds / 86400)
        var hours = Math.floor((seconds % 86400) / 3600)
        var mins = Math.floor((seconds % 3600) / 60)
        if (days > 0) {
            return qsTr("%1d %2h %3m").arg(days).arg(hours).arg(mins)
        } else if (hours > 0) {
            return qsTr("%1h %2m").arg(hours).arg(mins)
        } else {
            return qsTr("%1m").arg(mins)
        }
    }

    function formatThroughput(mbps) {
        if (mbps === undefined || mbps === null) return "--"
        return Number(mbps).toFixed(1) + " Mbps"
    }

    function sendCommand(cmd) {
        if (_command.value !== undefined) {
            _command.setValue(cmd)
        }
    }

    GradientListView {
        model: ObjectModel {

            // Connection Status Header
            ListItem {
                id: connectionHeader
                text: qsTr("Connection Status")
                secondaryText: {
                    if (_connected.value === 1) {
                        return _stateText.value || qsTr("Connected")
                    }
                    return qsTr("Disconnected")
                }
                content.children: [
                    Led {
                        anchors.verticalCenter: parent.verticalCenter
                        color: {
                            if (_connected.value !== 1) return Theme.color_red
                            if (_state.value === 1) return Theme.color_green  // Connected
                            if (_state.value === 4) return Theme.color_yellow  // Stowed
                            return Theme.color_orange
                        }
                    }
                ]
            }

            // Throughput Section
            ListNavigationItem {
                text: qsTr("Throughput")
                secondaryText: qsTr("Download: %1 / Upload: %2")
                    .arg(formatThroughput(_downlink.value))
                    .arg(formatThroughput(_uplink.value))
                onClicked: Global.pageManager.pushPage("/pages/starlink/PageStarlinkStatus.qml")
            }

            // Latency
            ListTextItem {
                text: qsTr("Latency")
                secondaryText: {
                    if (_latency.value === undefined || _latency.value === null) return "--"
                    return Number(_latency.value).toFixed(0) + " ms"
                }
            }

            // Obstruction Status
            ListTextItem {
                text: qsTr("Obstruction")
                secondaryText: {
                    if (_obstructed.value === 1) {
                        return qsTr("Obstructed (%1%)").arg(Number(_obstructedPercent.value || 0).toFixed(1))
                    }
                    return qsTr("Clear (%1%)").arg(Number(_obstructedPercent.value || 0).toFixed(1))
                }
            }

            // Separator
            ListItem {
                text: qsTr("Alerts")
                allowed: _thermalThrottle.value === 1 || _heating.value === 1 || _roaming.value === 1
            }

            // Thermal Alert
            ListTextItem {
                text: qsTr("Thermal Throttle")
                secondaryText: qsTr("Active")
                allowed: _thermalThrottle.value === 1
            }

            // Heating Alert
            ListTextItem {
                text: qsTr("Heating")
                secondaryText: qsTr("Dish is heating")
                allowed: _heating.value === 1
            }

            // Roaming Alert
            ListTextItem {
                text: qsTr("Roaming")
                secondaryText: qsTr("Active")
                allowed: _roaming.value === 1
            }

            // Separator
            ListItem {
                text: ""
            }

            // Device Info Section Header
            ListNavigationItem {
                text: qsTr("Device Information")
                secondaryText: _deviceId.value || qsTr("Not available")
                onClicked: Global.pageManager.pushPage("/pages/starlink/PageStarlinkStatus.qml")
            }

            // Software Version
            ListTextItem {
                text: qsTr("Software Version")
                secondaryText: _softwareVersion.value || "--"
            }

            // Hardware Version
            ListTextItem {
                text: qsTr("Hardware Version")
                secondaryText: _hardwareVersion.value || "--"
            }

            // Uptime
            ListTextItem {
                text: qsTr("Uptime")
                secondaryText: formatUptime(_uptime.value)
            }

            // Separator
            ListItem {
                text: ""
            }

            // Control Section Header
            ListItem {
                text: qsTr("Dish Control")
            }

            // Stow Button
            ListButton {
                id: stowButton
                text: qsTr("Stow Dish")
                secondaryText: qsTr("Put dish in stowed position")
                button.text: _state.value === 4 ? qsTr("Unstow") : qsTr("Stow")
                enabled: _connected.value === 1
                onClicked: {
                    if (_state.value === 4) {
                        sendCommand(3)  // Unstow
                    } else {
                        sendCommand(2)  // Stow
                    }
                }
            }

            // Reboot Button
            ListButton {
                id: rebootButton
                text: qsTr("Reboot Dish")
                secondaryText: qsTr("Restart the Starlink dish")
                button.text: qsTr("Reboot")
                enabled: _connected.value === 1
                onClicked: {
                    Global.dialogLayer.open(rebootConfirmDialog)
                }
            }
        }
    }

    // Reboot confirmation dialog
    ModalWarningDialog {
        id: rebootConfirmDialog
        title: qsTr("Reboot Starlink?")
        description: qsTr("This will restart your Starlink dish. Internet connectivity will be temporarily interrupted.")
        acceptText: qsTr("Reboot")
        onAccepted: sendCommand(1)
    }
}
