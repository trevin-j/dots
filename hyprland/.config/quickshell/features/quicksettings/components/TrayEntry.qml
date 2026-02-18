import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import "../../../config" as Config
import "../vm" as QuickSettingsVm

/*
  TrayEntry
  Single system tray row handling click, menu, tooltip, and wheel interactions.
*/
Item {
    id: root

    required property var trayItem
    required property int itemHeight
    required property int iconSize
    required property Item tooltipLayer
    required property Timer tooltipTimer
    required property QuickSettingsVm.PopoverState state

    readonly property string trayTitle: trayItem.tooltipTitle || trayItem.title || trayItem.id
    readonly property string trayDescription: trayItem.tooltipDescription || ""
    readonly property string trayTitleClean: trayTitle ? trayTitle.replace(/[\r\n]+/g, " ") : ""
    readonly property string trayDescriptionClean: trayDescription ? trayDescription.replace(/[\r\n]+/g, " ") : ""
    property bool hovered: trayEntryArea.containsMouse
    property real lastMouseX: width * 0.5
    property real lastMouseY: height

    function openTrayMenuAt(mouseX, mouseY) {
        if (!trayItem || !trayItem.hasMenu) {
            return;
        }
        trayMenu.anchor.item = root;
        trayMenu.anchor.rect = Qt.rect(
            Math.round(mouseX ?? root.width * 0.5),
            Math.round(mouseY ?? root.height),
            1,
            1
        );
        trayMenu.open();
    }

    function handleClick(mouseEvent) {
        if (!mouseEvent) {
            return;
        }
        if (mouseEvent.button === Qt.LeftButton) {
            if (trayItem.onlyMenu) {
                openTrayMenuAt(mouseEvent.x, mouseEvent.y);
            } else {
                trayItem.activate();
            }
        } else if (mouseEvent.button === Qt.MiddleButton) {
            trayItem.secondaryActivate();
        } else if (mouseEvent.button === Qt.RightButton) {
            openTrayMenuAt(mouseEvent.x, mouseEvent.y);
        }
    }

    height: root.itemHeight

    Rectangle {
        anchors.fill: parent
        radius: Config.Appearance.radiusSmall
        color: root.hovered ? Config.Palette.color("surface_container_high") : "transparent"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        IconImage {
            source: root.trayItem.icon
            implicitSize: root.iconSize
            asynchronous: true
            mipmap: true
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            Text {
                text: root.trayTitleClean
                font.family: Config.Appearance.fontFamily
                font.weight: Config.Appearance.fontWeight
                font.pixelSize: Config.Appearance.fontSizeMedium
                color: Config.Palette.color("on_surface")
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                textFormat: Text.PlainText
                Layout.fillWidth: true
            }

            Text {
                visible: root.trayDescriptionClean !== ""
                text: root.trayDescriptionClean
                font.family: Config.Appearance.fontFamily
                font.weight: Config.Appearance.fontWeight
                font.pixelSize: Math.max(10, Math.round(Config.Appearance.fontSizeSmall))
                color: Config.Palette.color("on_surface_variant")
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                textFormat: Text.PlainText
                Layout.fillWidth: true
            }
        }
    }

    MouseArea {
        id: trayEntryArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onEntered: root.state.scheduleTrayTooltip(root, root.lastMouseX, root.lastMouseY, root.tooltipTimer)
        onExited: root.state.clearTrayTooltip(root, root.tooltipTimer)
        onPositionChanged: {
            root.lastMouseX = mouse.x;
            root.lastMouseY = mouse.y;
            if (root.state.trayTooltipSource === root) {
                root.state.updateTrayTooltipPosition(root, root.tooltipLayer, mouse.x, mouse.y);
            } else if (root.state.trayTooltipPending === root) {
                root.state.trayTooltipX = mouse.x;
                root.state.trayTooltipY = mouse.y;
            }
        }
        onClicked: mouse => root.handleClick(mouse)
    }

    QsMenuAnchor {
        id: trayMenu
        menu: root.trayItem && root.trayItem.hasMenu ? root.trayItem.menu : null

        onOpened: root.state.trayMenuOpen = true
        onClosed: root.state.trayMenuOpen = false
    }

    onYChanged: {
        if (root.state.trayTooltipSource === root && trayEntryArea.containsMouse) {
            root.state.updateTrayTooltipPosition(root, root.tooltipLayer);
        }
    }

    WheelHandler {
        target: root
        onWheel: event => {
            if (!root.trayItem) {
                return;
            }
            const horizontal = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y);
            const delta = horizontal ? event.angleDelta.x : event.angleDelta.y;
            root.trayItem.scroll(Math.round(delta), horizontal);
            event.accepted = true;
        }
    }
}
