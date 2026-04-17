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
    readonly property int iconSize: Math.max(16, Math.round(barHeight * 0.5))
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
        viewModel: statusVm
    }
}
