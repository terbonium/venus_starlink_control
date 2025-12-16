/*
 * PageStarlinkOrientation.qml
 * Starlink dish orientation/attitude data
 */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    property string bindPrefix

    GradientListView {
        model: ObjectModel {

            ListTextItem {
                text: qsTr("Heading")
                secondaryText: heading.isValid ? heading.value.toFixed(0) + "°" : "--"

                VeQuickItem {
                    id: heading
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Attitude/Heading"
                }
            }

            ListTextItem {
                text: qsTr("Tilt")
                secondaryText: tilt.isValid ? tilt.value.toFixed(1) + "°" : "--"

                VeQuickItem {
                    id: tilt
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Attitude/Tilt"
                }
            }

            ListTextItem {
                text: qsTr("Roll")
                secondaryText: roll.isValid ? roll.value.toFixed(1) + "°" : "--"

                VeQuickItem {
                    id: roll
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Attitude/Roll"
                }
            }

            ListTextItem {
                text: qsTr("Azimuth")
                secondaryText: azimuth.isValid ? azimuth.value.toFixed(1) + "°" : "--"

                VeQuickItem {
                    id: azimuth
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Attitude/Azimuth"
                }
            }

            ListTextItem {
                text: qsTr("Elevation")
                secondaryText: elevation.isValid ? elevation.value.toFixed(1) + "°" : "--"

                VeQuickItem {
                    id: elevation
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Attitude/Elevation"
                }
            }

            ListTextItem {
                text: qsTr("Speed")
                secondaryText: speed.isValid ? (speed.value * 1.94384).toFixed(1) + " kts" : "--"

                VeQuickItem {
                    id: speed
                    uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Attitude/Speed"
                }
            }
        }
    }
}
