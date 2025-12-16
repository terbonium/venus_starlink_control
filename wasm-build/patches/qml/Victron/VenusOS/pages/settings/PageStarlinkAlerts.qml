/*
 * PageStarlinkAlerts.qml
 * Starlink alerts and warnings
 */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    property string bindPrefix

    GradientListView {
        model: ObjectModel {

            ListTextItem {
                text: qsTr("Thermal Throttle")
                secondaryText: thermalThrottle.value === 1 ? qsTr("ALERT") : qsTr("OK")

                VeQuickItem {
                    id: thermalThrottle
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Alerts/ThermalThrottle"
                }
            }

            ListTextItem {
                text: qsTr("Thermal Shutdown")
                secondaryText: thermalShutdown.value === 1 ? qsTr("ALERT") : qsTr("OK")

                VeQuickItem {
                    id: thermalShutdown
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Alerts/ThermalShutdown"
                }
            }

            ListTextItem {
                text: qsTr("Motors Stuck")
                secondaryText: motorsStuck.value === 1 ? qsTr("ALERT") : qsTr("OK")

                VeQuickItem {
                    id: motorsStuck
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Alerts/MotorsStuck"
                }
            }

            ListTextItem {
                text: qsTr("Mast Not Vertical")
                secondaryText: mastNotVertical.value === 1 ? qsTr("ALERT") : qsTr("OK")

                VeQuickItem {
                    id: mastNotVertical
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Alerts/MastNotVertical"
                }
            }

            ListTextItem {
                text: qsTr("Slow Ethernet")
                secondaryText: slowEthernet.value === 1 ? qsTr("ALERT") : qsTr("OK")

                VeQuickItem {
                    id: slowEthernet
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Alerts/SlowEthernet"
                }
            }

            ListTextItem {
                text: qsTr("Roaming")
                secondaryText: roaming.value === 1 ? CommonWords.yes : CommonWords.no

                VeQuickItem {
                    id: roaming
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Alerts/Roaming"
                }
            }

            ListTextItem {
                text: qsTr("Heating")
                secondaryText: isHeating.value === 1 ? CommonWords.yes : CommonWords.no

                VeQuickItem {
                    id: isHeating
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Alerts/IsHeating"
                }
            }

            ListTextItem {
                text: qsTr("Power Save Idle")
                secondaryText: powerSaveIdle.value === 1 ? CommonWords.yes : CommonWords.no

                VeQuickItem {
                    id: powerSaveIdle
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Alerts/PowerSaveIdle"
                }
            }
        }
    }
}
