import QtQuick
import QtQuick.Layouts
import Quickshell

import "./"
import "../models" as BarModels
import "../../../services" as Services

Item {
    id: root

    required property ShellScreen screen
    required property bool vertical

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    BarModels.WorkspaceModel {
        id: workspaceModel
        screen: root.screen
    }

    RowLayout {
        id: layout

        spacing: 6

        Repeater {
            model: workspaceModel.liveWorkspaces

            delegate: WorkspacePill {
                required property var modelData

                workspaceId: modelData.id
                label: workspaceModel.workspaceLabel(modelData)
                vertical: root.vertical
                active: workspaceModel.activeWorkspaceId === workspaceId
                occupied: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: Services.WorkspaceService.activateWorkspace(workspaceId)
                }
            }
        }
    }
}
