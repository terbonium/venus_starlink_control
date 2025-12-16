/*
 * PageStarlinkPerformance.qml
 * Starlink performance metrics
 */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    property string bindPrefix

    GradientListView {
        model: ObjectModel {

            ListTextItem {
                text: qsTr("Download Speed")
                secondaryText: downlink.isValid ? downlink.value.toFixed(1) + " Mbps" : "--"

                VeQuickItem {
                    id: downlink
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/DownlinkThroughput"
                }
            }

            ListTextItem {
                text: qsTr("Upload Speed")
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
                text: qsTr("Packet Loss")
                secondaryText: dropRate.isValid ? (dropRate.value * 100).toFixed(2) + "%" : "--"

                VeQuickItem {
                    id: dropRate
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/PopPingDropRate"
                }
            }

            ListTextItem {
                text: qsTr("Currently Obstructed")
                secondaryText: obstructed.value === 1 ? CommonWords.yes : CommonWords.no

                VeQuickItem {
                    id: obstructed
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Obstructed"
                }
            }

            ListTextItem {
                text: qsTr("Time Obstructed")
                secondaryText: obstructedPct.isValid ? obstructedPct.value.toFixed(1) + "%" : "--"

                VeQuickItem {
                    id: obstructedPct
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/ObstructedPercent"
                }
            }

            ListTextItem {
                text: qsTr("Sky Blocked")
                secondaryText: fractionObs.isValid ? (fractionObs.value * 100).toFixed(2) + "%" : "--"

                VeQuickItem {
                    id: fractionObs
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/FractionObstructed"
                }
            }
        }
    }
}
