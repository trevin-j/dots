import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import "../../config" as Config
import "../../services" as Services
import "./vm" as BitwardenVm

/*
  BitwardenSetupPopupFeature
  Centered setup popup for configuring Bitwarden email and optional server URL.
  Required properties: panelScreen, state.
 */
PanelWindow {
    id: root

    required property ShellScreen panelScreen
    required property BitwardenVm.BitwardenSetupState state

    readonly property int cardWidth: Config.Config.bitwardenPicker?.setup?.width ?? 420
    readonly property int cardPadding: Config.Config.bitwardenPicker?.setup?.padding ?? 18
    readonly property int contentSpacing: Config.Config.bitwardenPicker?.setup?.spacing ?? 12
    readonly property int inputHeight: Config.Config.bitwardenPicker?.setup?.inputHeight ?? 42
    readonly property int buttonHeight: Config.Config.bitwardenPicker?.setup?.buttonHeight ?? 40

    screen: root.panelScreen
    aboveWindows: true
    focusable: root.state.open
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: 0
    visible: root.state.open

    WlrLayershell.namespace: "quickshell-bitwarden-setup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.state.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    function submit() {
        const email = setupEmailInput.text.trim();
        const serverUrl = serverUrlInput.text.trim();
        if (!email || root.state.submitting) {
            return;
        }

        Services.BitwardenService.submitSetup(email, serverUrl);
    }

    onVisibleChanged: {
        if (visible) {
            focusTimer.restart();
            focusRetryTimer.restart();
        } else {
            focusRetryTimer.stop();
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.state.open && root.visible

        onCleared: {
            if (root.state.open && !root.state.submitting) {
                root.state.closeDialog();
            }
        }
    }

    Timer {
        id: focusTimer

        interval: 0
        repeat: false
        onTriggered: setupEmailInput.forceActiveFocus()
    }

    Timer {
        id: focusRetryTimer

        interval: 70
        repeat: false
        onTriggered: {
            if (root.state.open) {
                setupEmailInput.forceActiveFocus();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.state.open && !root.state.submitting
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: root.state.closeDialog()
    }

    Rectangle {
        width: root.cardWidth
        height: contentColumn.implicitHeight + root.cardPadding * 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        radius: Config.Appearance.radiusLarge
        color: Config.Palette.color("surface")
        border.width: 1
        border.color: Config.Palette.color("outline_variant")

        ColumnLayout {
            id: contentColumn

            anchors.fill: parent
            anchors.margins: root.cardPadding
            spacing: root.contentSpacing

            Text {
                text: "Set Up Bitwarden"
                color: Config.Palette.color("on_surface")
                font.family: Config.Appearance.fontFamily
                font.pixelSize: Config.Appearance.fontSizeLarge
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            Text {
                text: "Enter your account email and optional server URL. Leave server URL blank for the official Bitwarden instance."
                color: Config.Palette.color("on_surface_variant")
                font.family: Config.Appearance.fontFamily
                font.pixelSize: Config.Appearance.fontSizeSmall
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.inputHeight
                radius: Config.Appearance.radiusMedium
                color: Config.Palette.color("surface_container")
                border.width: 1
                border.color: Config.Palette.color("outline_variant")

                TextInput {
                    id: setupEmailInput

                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    color: Config.Palette.color("on_surface")
                    selectedTextColor: Config.Palette.color("on_primary")
                    selectionColor: Config.Palette.color("primary")
                    font.family: Config.Appearance.fontFamily
                    font.pixelSize: Config.Appearance.fontSizeMedium
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.state.email
                    onTextEdited: root.state.email = text

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 2
                        text: "Email"
                        visible: setupEmailInput.text.length === 0 && !setupEmailInput.activeFocus
                        color: Config.Palette.color("on_surface_variant")
                        font.family: Config.Appearance.fontFamily
                        font.pixelSize: Config.Appearance.fontSizeMedium
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.inputHeight
                radius: Config.Appearance.radiusMedium
                color: Config.Palette.color("surface_container")
                border.width: 1
                border.color: Config.Palette.color("outline_variant")

                TextInput {
                    id: serverUrlInput

                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    color: Config.Palette.color("on_surface")
                    selectedTextColor: Config.Palette.color("on_primary")
                    selectionColor: Config.Palette.color("primary")
                    font.family: Config.Appearance.fontFamily
                    font.pixelSize: Config.Appearance.fontSizeMedium
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.state.serverUrl
                    onTextEdited: root.state.serverUrl = text

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 2
                        text: "Server URL"
                        visible: serverUrlInput.text.length === 0 && !serverUrlInput.activeFocus
                        color: Config.Palette.color("on_surface_variant")
                        font.family: Config.Appearance.fontFamily
                        font.pixelSize: Config.Appearance.fontSizeMedium
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Text {
                visible: root.state.errorText !== ""
                text: root.state.errorText
                color: Config.Palette.color("error")
                font.family: Config.Appearance.fontFamily
                font.pixelSize: Config.Appearance.fontSizeSmall
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.buttonHeight
                    radius: Config.Appearance.radiusMedium
                    color: Config.Palette.color("surface_container")
                    opacity: root.state.submitting ? 0.5 : 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Config.Palette.color("on_surface")
                        font.family: Config.Appearance.fontFamily
                        font.pixelSize: Config.Appearance.fontSizeMedium
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.state.submitting
                        onClicked: root.state.closeDialog()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.buttonHeight
                    radius: Config.Appearance.radiusMedium
                    color: Config.Palette.color("primary")
                    opacity: (setupEmailInput.text.trim() !== "" && !root.state.submitting) ? 1 : 0.55

                    Text {
                        anchors.centerIn: parent
                        text: root.state.submitting ? "Saving..." : "Continue"
                        color: Config.Palette.color("on_primary")
                        font.family: Config.Appearance.fontFamily
                        font.pixelSize: Config.Appearance.fontSizeMedium
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: setupEmailInput.text.trim() !== "" && !root.state.submitting
                        onClicked: root.submit()
                    }
                }
            }
        }
    }
}
