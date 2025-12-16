import QtQuick 1.1
import com.victron.velib 1.0
import "utils.js" as Utils

MbPage {
    id: root
    title: qsTr("Starlink")
    property string bindPrefix: "com.victronenergy.starlink"

    model: VisualItemModel {
        MbItemValue {
            description: qsTr("Status")
            item.bind: Utils.path(bindPrefix, "/StateText")
        }

        MbItemValue {
            description: qsTr("Connected")
            item.bind: Utils.path(bindPrefix, "/Connected")
            item.text: item.value === 1 ? qsTr("Yes") : qsTr("No")
        }

        MbItemValue {
            description: qsTr("Uptime")
            item.bind: Utils.path(bindPrefix, "/Uptime")
            item.text: formatUptime(item.value)

            function formatUptime(seconds) {
                if (!seconds || seconds <= 0) return "--"
                var days = Math.floor(seconds / 86400)
                var hours = Math.floor((seconds % 86400) / 3600)
                var mins = Math.floor((seconds % 3600) / 60)
                if (days > 0) return days + "d " + hours + "h " + mins + "m"
                if (hours > 0) return hours + "h " + mins + "m"
                return mins + "m"
            }
        }

        MbSubMenu {
            description: qsTr("Performance")
            subpage: Component {
                MbPage {
                    title: qsTr("Performance")
                    model: VisualItemModel {
                        MbItemValue {
                            description: qsTr("Download")
                            item.bind: Utils.path(bindPrefix, "/DownlinkThroughput")
                            item.text: item.value !== undefined ? item.value.toFixed(1) + " Mbps" : "--"
                        }

                        MbItemValue {
                            description: qsTr("Upload")
                            item.bind: Utils.path(bindPrefix, "/UplinkThroughput")
                            item.text: item.value !== undefined ? item.value.toFixed(1) + " Mbps" : "--"
                        }

                        MbItemValue {
                            description: qsTr("Latency")
                            item.bind: Utils.path(bindPrefix, "/PopPingLatencyMs")
                            item.text: item.value !== undefined ? item.value.toFixed(0) + " ms" : "--"
                        }

                        MbItemValue {
                            description: qsTr("Packet Loss")
                            item.bind: Utils.path(bindPrefix, "/PopPingDropRate")
                            item.text: item.value !== undefined ? (item.value * 100).toFixed(1) + "%" : "--"
                        }
                    }
                }
            }
        }

        MbSubMenu {
            description: qsTr("Obstruction")
            subpage: Component {
                MbPage {
                    title: qsTr("Obstruction")
                    model: VisualItemModel {
                        MbItemValue {
                            description: qsTr("Currently Obstructed")
                            item.bind: Utils.path(bindPrefix, "/Obstructed")
                            item.text: item.value === 1 ? qsTr("Yes") : qsTr("No")
                        }

                        MbItemValue {
                            description: qsTr("Time Obstructed")
                            item.bind: Utils.path(bindPrefix, "/ObstructedPercent")
                            item.text: item.value !== undefined ? item.value.toFixed(1) + "%" : "--"
                        }

                        MbItemValue {
                            description: qsTr("Sky Blocked")
                            item.bind: Utils.path(bindPrefix, "/FractionObstructed")
                            item.text: item.value !== undefined ? (item.value * 100).toFixed(2) + "%" : "--"
                        }
                    }
                }
            }
        }

        MbSubMenu {
            description: qsTr("GPS Position")
            subpage: Component {
                MbPage {
                    title: qsTr("GPS Position")
                    model: VisualItemModel {
                        MbItemValue {
                            description: qsTr("GPS Valid")
                            item.bind: Utils.path(bindPrefix, "/Gps/Valid")
                            item.text: item.value === 1 ? qsTr("Yes") : qsTr("No")
                        }

                        MbItemValue {
                            description: qsTr("Satellites")
                            item.bind: Utils.path(bindPrefix, "/Gps/Satellites")
                        }

                        MbItemValue {
                            description: qsTr("Latitude")
                            item.bind: Utils.path(bindPrefix, "/Gps/Latitude")
                            item.text: item.value !== undefined ? formatCoord(item.value, "N", "S") : "--"

                            function formatCoord(value, pos, neg) {
                                var dir = value >= 0 ? pos : neg
                                return Math.abs(value).toFixed(5) + "° " + dir
                            }
                        }

                        MbItemValue {
                            description: qsTr("Longitude")
                            item.bind: Utils.path(bindPrefix, "/Gps/Longitude")
                            item.text: item.value !== undefined ? formatCoord(item.value, "E", "W") : "--"

                            function formatCoord(value, pos, neg) {
                                var dir = value >= 0 ? pos : neg
                                return Math.abs(value).toFixed(5) + "° " + dir
                            }
                        }

                        MbItemValue {
                            description: qsTr("Altitude")
                            item.bind: Utils.path(bindPrefix, "/Gps/Altitude")
                            item.text: item.value !== undefined ? item.value.toFixed(1) + " m" : "--"
                        }
                    }
                }
            }
        }

        MbSubMenu {
            description: qsTr("Orientation")
            subpage: Component {
                MbPage {
                    title: qsTr("Orientation")
                    model: VisualItemModel {
                        MbItemValue {
                            description: qsTr("Heading")
                            item.bind: Utils.path(bindPrefix, "/Attitude/Heading")
                            item.text: item.value !== undefined ? item.value.toFixed(0) + "°" : "--"
                        }

                        MbItemValue {
                            description: qsTr("Tilt")
                            item.bind: Utils.path(bindPrefix, "/Attitude/Tilt")
                            item.text: item.value !== undefined ? item.value.toFixed(1) + "°" : "--"
                        }

                        MbItemValue {
                            description: qsTr("Roll")
                            item.bind: Utils.path(bindPrefix, "/Attitude/Roll")
                            item.text: item.value !== undefined ? item.value.toFixed(1) + "°" : "--"
                        }

                        MbItemValue {
                            description: qsTr("Speed")
                            item.bind: Utils.path(bindPrefix, "/Attitude/Speed")
                            item.text: item.value !== undefined ? (item.value * 1.94384).toFixed(1) + " kts" : "--"
                        }
                    }
                }
            }
        }

        MbSubMenu {
            description: qsTr("Alerts")
            subpage: Component {
                MbPage {
                    title: qsTr("Alerts")
                    model: VisualItemModel {
                        MbItemValue {
                            description: qsTr("Thermal Throttle")
                            item.bind: Utils.path(bindPrefix, "/Alerts/ThermalThrottle")
                            item.text: item.value === 1 ? qsTr("ALERT") : qsTr("OK")
                        }

                        MbItemValue {
                            description: qsTr("Thermal Shutdown")
                            item.bind: Utils.path(bindPrefix, "/Alerts/ThermalShutdown")
                            item.text: item.value === 1 ? qsTr("ALERT") : qsTr("OK")
                        }

                        MbItemValue {
                            description: qsTr("Motors Stuck")
                            item.bind: Utils.path(bindPrefix, "/Alerts/MotorsStuck")
                            item.text: item.value === 1 ? qsTr("ALERT") : qsTr("OK")
                        }

                        MbItemValue {
                            description: qsTr("Mast Not Vertical")
                            item.bind: Utils.path(bindPrefix, "/Alerts/MastNotVertical")
                            item.text: item.value === 1 ? qsTr("ALERT") : qsTr("OK")
                        }

                        MbItemValue {
                            description: qsTr("Slow Ethernet")
                            item.bind: Utils.path(bindPrefix, "/Alerts/SlowEthernet")
                            item.text: item.value === 1 ? qsTr("ALERT") : qsTr("OK")
                        }

                        MbItemValue {
                            description: qsTr("Roaming")
                            item.bind: Utils.path(bindPrefix, "/Alerts/Roaming")
                            item.text: item.value === 1 ? qsTr("Yes") : qsTr("No")
                        }

                        MbItemValue {
                            description: qsTr("Heating")
                            item.bind: Utils.path(bindPrefix, "/Alerts/IsHeating")
                            item.text: item.value === 1 ? qsTr("Yes") : qsTr("No")
                        }
                    }
                }
            }
        }

        MbSubMenu {
            description: qsTr("Device Info")
            subpage: Component {
                MbPage {
                    title: qsTr("Device Info")
                    model: VisualItemModel {
                        MbItemValue {
                            description: qsTr("Device ID")
                            item.bind: Utils.path(bindPrefix, "/DeviceId")
                        }

                        MbItemValue {
                            description: qsTr("Hardware Version")
                            item.bind: Utils.path(bindPrefix, "/HardwareVersion")
                        }

                        MbItemValue {
                            description: qsTr("Software Version")
                            item.bind: Utils.path(bindPrefix, "/SoftwareVersion")
                        }

                        MbItemValue {
                            description: qsTr("Boot Count")
                            item.bind: Utils.path(bindPrefix, "/Bootcount")
                        }

                        MbItemValue {
                            description: qsTr("Country Code")
                            item.bind: Utils.path(bindPrefix, "/CountryCode")
                        }
                    }
                }
            }
        }

        MbSubMenu {
            description: qsTr("Controls")
            subpage: Component {
                MbPage {
                    title: qsTr("Controls")
                    model: VisualItemModel {
                        MbOK {
                            description: qsTr("Stow Dish")
                            value: qsTr("Press to stow")
                            onClicked: {
                                commandItem.setValue(2)
                            }
                        }

                        MbOK {
                            description: qsTr("Unstow Dish")
                            value: qsTr("Press to unstow")
                            onClicked: {
                                commandItem.setValue(3)
                            }
                        }

                        MbOK {
                            description: qsTr("Reboot Dish")
                            value: qsTr("Press to reboot")
                            onClicked: {
                                commandItem.setValue(1)
                            }
                        }

                        MbItemValue {
                            description: qsTr("Last Command Result")
                            item.bind: Utils.path(bindPrefix, "/CommandResult")
                            item.text: {
                                switch(item.value) {
                                    case 0: return qsTr("None")
                                    case 1: return qsTr("Success")
                                    case 2: return qsTr("Failed")
                                    default: return "--"
                                }
                            }
                        }
                    }

                    VBusItem {
                        id: commandItem
                        bind: Utils.path(bindPrefix, "/Command")
                    }
                }
            }
        }
    }
}
