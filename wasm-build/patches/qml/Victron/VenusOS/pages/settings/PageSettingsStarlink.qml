/*
 * PageSettingsStarlink.qml
 * Starlink satellite dish monitoring and control page for Venus OS GUI v2
 */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    property string bindPrefix: "com.victronenergy.starlink"

    GradientListView {
        model: ObjectModel {

            ListNavigationItem {
                text: CommonWords.status
                secondaryText: stateText.isValid ? stateText.value : "--"
                onClicked: Global.pageManager.pushPage("/pages/settings/PageStarlinkStatus.qml", { bindPrefix: root.bindPrefix })

                VeQuickItem {
                    id: stateText
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/StateText"
                }
            }

            ListTextItem {
                text: qsTr("Connected")
                secondaryText: connected.value === 1 ? CommonWords.yes : CommonWords.no

                VeQuickItem {
                    id: connected
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Connected"
                }
            }

            ListTextItem {
                text: qsTr("Uptime")
                secondaryText: formatUptime(uptime.value)

                VeQuickItem {
                    id: uptime
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Uptime"
                }

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

            ListNavigationItem {
                text: qsTr("Performance")
                onClicked: Global.pageManager.pushPage("/pages/settings/PageStarlinkPerformance.qml", { bindPrefix: root.bindPrefix })
            }

            ListNavigationItem {
                text: qsTr("GPS Position")
                onClicked: Global.pageManager.pushPage("/pages/settings/PageStarlinkGps.qml", { bindPrefix: root.bindPrefix })
            }

            ListNavigationItem {
                text: qsTr("Orientation")
                onClicked: Global.pageManager.pushPage("/pages/settings/PageStarlinkOrientation.qml", { bindPrefix: root.bindPrefix })
            }

            ListNavigationItem {
                text: qsTr("Alerts")
                onClicked: Global.pageManager.pushPage("/pages/settings/PageStarlinkAlerts.qml", { bindPrefix: root.bindPrefix })
            }

            ListNavigationItem {
                text: qsTr("Device Info")
                onClicked: Global.pageManager.pushPage("/pages/settings/PageStarlinkDeviceInfo.qml", { bindPrefix: root.bindPrefix })
            }

            ListNavigationItem {
                text: qsTr("Controls")
                onClicked: Global.pageManager.pushPage("/pages/settings/PageStarlinkControls.qml", { bindPrefix: root.bindPrefix })
            }
        }
    }
}
