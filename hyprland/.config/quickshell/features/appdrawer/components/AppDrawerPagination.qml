import QtQuick

import "../../../config" as Config

/*
  AppDrawerPagination
  Dot-pill page controls for navigating app drawer pages.
  Required properties: page, pageCount.
*/
Row {
    id: root

    required property int page
    required property int pageCount

    signal pageRequested(int page)

    spacing: 8

    Repeater {
        model: Math.max(1, root.pageCount)

        delegate: Rectangle {
            required property int index

            readonly property bool active: index === root.page

            width: active ? 28 : 8
            height: 8
            radius: height / 2
            color: active ? Config.Palette.color("primary") : Config.Palette.color("outline_variant")
            opacity: active ? 1 : 0.72

            Behavior on width {
                NumberAnimation {
                    duration: Config.Motion.shortDuration
                    easing.bezierCurve: Config.Motion.standard
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Config.Motion.shortDuration
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.pageRequested(index)
            }
        }
    }
}
