/*
 * PageStarlinkGps.qml
 * Starlink GPS position data
 */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    property string bindPrefix

    GradientListView {
        model: ObjectModel {

            ListTextItem {
                text: qsTr("GPS Valid")
                secondaryText: gpsValid.value === 1 ? CommonWords.yes : CommonWords.no

                VeQuickItem {
                    id: gpsValid
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Gps/Valid"
                }
            }

            ListTextItem {
                text: qsTr("Satellites")
                secondaryText: satellites.isValid ? satellites.value.toString() : "--"

                VeQuickItem {
                    id: satellites
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Gps/Satellites"
                }
            }

            ListTextItem {
                text: qsTr("Latitude")
                secondaryText: formatCoord(latitude.value, "N", "S")

                VeQuickItem {
                    id: latitude
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Gps/Latitude"
                }

                function formatCoord(value, pos, neg) {
                    if (!value && value !== 0) return "--"
                    var dir = value >= 0 ? pos : neg
                    return Math.abs(value).toFixed(5) + "° " + dir
                }
            }

            ListTextItem {
                text: qsTr("Longitude")
                secondaryText: formatCoord(longitude.value, "E", "W")

                VeQuickItem {
                    id: longitude
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Gps/Longitude"
                }

                function formatCoord(value, pos, neg) {
                    if (!value && value !== 0) return "--"
                    var dir = value >= 0 ? pos : neg
                    return Math.abs(value).toFixed(5) + "° " + dir
                }
            }

            ListTextItem {
                text: qsTr("Altitude")
                secondaryText: altitude.isValid ? altitude.value.toFixed(1) + " m" : "--"

                VeQuickItem {
                    id: altitude
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Gps/Altitude"
                }
            }
        }
    }
}
