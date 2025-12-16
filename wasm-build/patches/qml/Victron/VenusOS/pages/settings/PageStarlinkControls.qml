/*
 * PageStarlinkControls.qml
 * Starlink dish control commands
 */

import QtQuick
import Victron.VenusOS

Page {
    id: root

    property string bindPrefix

    VeQuickItem {
        id: commandItem
        uid: Global.system.serviceUid + "/" + root.bindPrefix + "/Command"
    }

    VeQuickItem {
        id: commandResult
        uid: Global.system.serviceUid + "/" + root.bindPrefix + "/CommandResult"
    }

    GradientListView {
        model: ObjectModel {

            ListTextItem {
                text: qsTr("Last Command Result")
                secondaryText: {
                    switch(commandResult.value) {
                        case 0: return qsTr("None")
                        case 1: return qsTr("Success")
                        case 2: return qsTr("Failed")
                        default: return "--"
                    }
                }
            }

            ListButton {
                id: stowButton
                text: qsTr("Stow Dish")
                secondaryText: qsTr("Press to stow")
                button.text: qsTr("Stow")
                enabled: !commandPending
                onClicked: {
                    commandPending = true
                    commandItem.setValue(2)
                    pendingTimer.restart()
                }

                property bool commandPending: false

                Timer {
                    id: pendingTimer
                    interval: 3000
                    onTriggered: stowButton.commandPending = false
                }
            }

            ListButton {
                id: unstowButton
                text: qsTr("Unstow Dish")
                secondaryText: qsTr("Press to unstow")
                button.text: qsTr("Unstow")
                enabled: !commandPending
                onClicked: {
                    commandPending = true
                    commandItem.setValue(3)
                    pendingTimer.restart()
                }

                property bool commandPending: false

                Timer {
                    id: unstowPendingTimer
                    interval: 3000
                    onTriggered: unstowButton.commandPending = false
                }
            }

            ListButton {
                id: rebootButton
                text: qsTr("Reboot Dish")
                secondaryText: qsTr("Press to reboot (causes temporary outage)")
                button.text: qsTr("Reboot")
                enabled: !commandPending
                onClicked: {
                    Global.dialogLayer.open(confirmRebootDialog)
                }

                property bool commandPending: false

                Timer {
                    id: rebootPendingTimer
                    interval: 5000
                    onTriggered: rebootButton.commandPending = false
                }
            }
        }
    }

    Component {
        id: confirmRebootDialog

        ModalWarningDialog {
            dialogDoneOptions: VenusOS.ModalDialog_DoneOptions_OkAndCancel
            title: qsTr("Confirm Reboot")
            description: qsTr("Are you sure you want to reboot the Starlink dish? This will cause a temporary loss of connectivity.")

            onAccepted: {
                rebootButton.commandPending = true
                commandItem.setValue(1)
                rebootPendingTimer.restart()
            }
        }
    }
}
