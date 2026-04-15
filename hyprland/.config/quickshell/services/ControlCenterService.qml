pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import "./" as Services

/*
  ControlCenterService
  Tracks per-screen control center state and exposes IPC controls.
*/
Scope {
    id: root

    readonly property string panelId: "controlcenter"
    property var entries: []

    function monitorKey(monitor) {
        if (!monitor) {
            return "";
        }

        return monitor.name
            || monitor.connector
            || monitor.id
            || monitor.lastIpcObject?.name
            || "";
    }

    function focusedMonitorKey() {
        return root.monitorKey(Hyprland.focusedMonitor);
    }

    function stateEntryForFocusedMonitor() {
        const key = root.focusedMonitorKey();
        if (key === "") {
            return null;
        }

        for (const entry of root.entries) {
            if (!entry || !entry.screen || !entry.state) {
                continue;
            }

            const monitor = Hyprland.monitorFor(entry.screen);
            if (root.monitorKey(monitor) === key) {
                return entry;
            }
        }

        return null;
    }

    function fallbackEntry() {
        for (const entry of root.entries) {
            if (entry && entry.state) {
                return entry;
            }
        }

        return null;
    }

    function withTargetState(callback) {
        const entry = root.stateEntryForFocusedMonitor() || root.fallbackEntry();
        if (!entry || !entry.state) {
            return;
        }

        callback(entry.state);
    }

    function targetState() {
        const entry = root.stateEntryForFocusedMonitor() || root.fallbackEntry();
        if (!entry || !entry.state) {
            return null;
        }

        return entry.state;
    }

    function registerScreenState(screen, state) {
        if (!screen || !state) {
            return;
        }

        const filtered = root.entries.filter(entry => entry && entry.state && entry.state !== state);
        filtered.push({
            screen: screen,
            state: state
        });
        root.entries = filtered;
    }

    function unregisterScreenState(state) {
        if (!state) {
            return;
        }

        root.entries = root.entries.filter(entry => entry && entry.state && entry.state !== state);
    }

    function toggle() {
        if (root.isTargetOpen()) {
            root.close();
            return;
        }

        root.open();
    }

    function open() {
        const state = root.targetState();
        if (!state) {
            return;
        }

        Services.PanelExclusivityService.requestOpen(root.panelId);
        root.closeAll();
        state.openPanel();
    }

    function close() {
        root.withTargetState(state => state.close());
    }

    function closeAll() {
        for (const entry of root.entries) {
            if (entry?.state) {
                entry.state.close();
            }
        }
    }

    function isOpen() {
        for (const entry of root.entries) {
            if (entry?.state?.open) {
                return true;
            }
        }

        return false;
    }

    function isTargetOpen() {
        const state = root.targetState();
        return state ? state.open : false;
    }

    function swipeLeft() {
        // swipe from right to left
        if (Services.AppDrawerService.isTargetOpen()) {
            Services.AppDrawerService.close();
            return;
        }

        root.open();
    }

    function swipeRight() {
        // swipe from left to right
        if (root.isTargetOpen()) {
            root.close();
            return;
        }

        Services.AppDrawerService.open();
    }

    function swipeUp() {
    }

    function swipeDown() {
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }
    }

    IpcHandler {
        target: "shellgestures"

        function swipeLeft(): void {
            root.swipeLeft();
        }

        function swipeRight(): void {
            root.swipeRight();
        }

        function swipeUp(): void {
            root.swipeUp();
        }

        function swipeDown(): void {
            root.swipeDown();
        }
    }

    Component.onCompleted: Services.PanelExclusivityService.registerPanel(root.panelId, root)
    Component.onDestruction: Services.PanelExclusivityService.unregisterPanel(root.panelId, root)
}
