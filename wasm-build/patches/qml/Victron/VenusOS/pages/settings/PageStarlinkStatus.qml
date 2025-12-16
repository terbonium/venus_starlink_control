/*
 * PageStarlinkStatus.qml
 * Detailed Starlink status page
 */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    property string bindPrefix

    GradientListView {
        model: ObjectModel {

            ListTextItem {
                text: qsTr("State")
                secondaryText: stateText.isValid ? stateText.value : "--"

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
                text: qsTr("Download")
                secondaryText: downlink.isValid ? downlink.value.toFixed(1) + " Mbps" : "--"

                VeQuickItem {
                    id: downlink
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/DownlinkThroughput"
                }
            }

            ListTextItem {
                text: qsTr("Upload")
                secondaryText: uplink.isValid ? uplink.value.toFixed(1) + " Mbps" : "--"

                VeQuickItem {
                    id: uplink
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/UplinkThroughput"
                }
            }

            ListTextItem {
                text: qsTr("Latency")
                secondaryText: latency.isValid ? latency.value.toFixed(0) + " ms" : "--"

                VeQuickItem {
                    id: latency
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/PopPingLatencyMs"
                }
            }

            ListTextItem {
                text: qsTr("Obstructed")
                secondaryText: obstructed.value === 1 ? CommonWords.yes : CommonWords.no

                VeQuickItem {
                    id: obstructed
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Obstructed"
                }
            }

            ListTextItem {
                text: qsTr("Obstruction %")
                secondaryText: obstructedPct.isValid ? obstructedPct.value.toFixed(1) + "%" : "--"

                VeQuickItem {
                    id: obstructedPct
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/ObstructedPercent"
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
        }
    }
}
