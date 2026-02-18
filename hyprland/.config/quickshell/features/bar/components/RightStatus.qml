import QtQuick

import "../../../config" as Config
import "../../quicksettings/vm" as QuickSettingsVm
import "../../quicksettings/components" as QuickSettingsComponents

/*
  RightStatus
  Persistent status content shown in the bar right section.
  Required properties: barHeight, spacing.
*/
Item {
    id: root

    required property int barHeight
    required property int spacing

    readonly property int horizontalPadding: Math.max(6, Math.round(spacing * 0.75))
    readonly property int verticalPadding: Math.max(4, Math.round(horizontalPadding * 0.6))
    readonly property int iconSize: Math.max(14, Math.round(barHeight * 0.45))
    readonly property string materialFont: Config.Appearance.iconFontFamily

    QuickSettingsVm.StatusViewModel {
        id: statusVm
    }

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    QuickSettingsComponents.StatusPill {
        id: pill

        barHeight: root.barHeight
        spacing: root.spacing
        materialFont: root.materialFont
        iconSize: root.iconSize
        horizontalPadding: root.horizontalPadding
        verticalPadding: root.verticalPadding
        viewModel: statusVm
    }
}
