pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

/*!
  FrameRegistry
  Stores active FrameWrapper items for global frame layers.
  Inputs: FrameWrapper items register/unregister themselves.
*/
QtObject {
    id: root

    property var wrappers: []

    function registerWrapper(wrapper) {
        if (!wrapper) {
            return;
        }
        if (wrappers.indexOf(wrapper) !== -1) {
            return;
        }
        wrappers = wrappers.concat([wrapper]);
    }

    function unregisterWrapper(wrapper) {
        if (!wrapper) {
            return;
        }
        wrappers = wrappers.filter(existing => existing !== wrapper);
    }
}
