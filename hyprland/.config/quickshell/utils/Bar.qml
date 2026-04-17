pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    function widgetHeight(barHeight, contentHeight) {
        return Math.max(contentHeight, barHeight);
    }
}
