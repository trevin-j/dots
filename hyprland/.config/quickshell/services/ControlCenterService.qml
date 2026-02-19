pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

/*
  ControlCenterService
  Tracks per-screen control center state and exposes IPC controls.
*/
Scope {
    id: root

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
        root.withTargetState(state => state.toggle());
    }

    function open() {
        root.withTargetState(state => state.openPanel());
    }

    function close() {
        root.withTargetState(state => state.close());
    }

    function isOpen() {
        const state = root.targetState();
        return state ? state.open : false;
    }

    function swipeLeft() {
        if (!root.isOpen()) {
            root.open();
        }
    }

    function swipeRight() {
        if (root.isOpen()) {
            root.close();
        }
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
}
