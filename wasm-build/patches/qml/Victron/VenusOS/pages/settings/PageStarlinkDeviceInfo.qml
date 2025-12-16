/*
 * PageStarlinkDeviceInfo.qml
 * Starlink device information
 */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    property string bindPrefix

    GradientListView {
        model: ObjectModel {

            ListTextItem {
                text: qsTr("Device ID")
                secondaryText: deviceId.isValid ? deviceId.value : "--"

                VeQuickItem {
                    id: deviceId
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/DeviceId"
                }
            }

            ListTextItem {
                text: qsTr("Hardware Version")
                secondaryText: hwVersion.isValid ? hwVersion.value : "--"

                VeQuickItem {
                    id: hwVersion
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/HardwareVersion"
                }
            }

            ListTextItem {
                text: qsTr("Software Version")
                secondaryText: swVersion.isValid ? swVersion.value : "--"

                VeQuickItem {
                    id: swVersion
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/SoftwareVersion"
                }
            }

            ListTextItem {
                text: qsTr("Boot Count")
                secondaryText: bootcount.isValid ? bootcount.value.toString() : "--"

                VeQuickItem {
                    id: bootcount
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Bootcount"
                }
            }

            ListTextItem {
                text: qsTr("Country Code")
                secondaryText: countryCode.isValid ? countryCode.value : "--"

                VeQuickItem {
                    id: countryCode
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/CountryCode"
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
