pragma ComponentBehavior: Bound

import QtQuick

import "WhichKeyTree.js" as WhichKeyTree

/*
  WhichKeyState
  Stores which-key navigation state and resolves actions from configured key paths.
  Required properties: config.
*/
QtObject {
    id: root

    required property var config

    property bool enabled: true
    property bool closeOnUnknown: true
    property bool open: false
    property string title: "Leader"
    property var tree: WhichKeyTree.emptyTree()
    property var path: []
    property var entries: []
    property string crumb: "Leader"

    signal commandRequested(string command)

    function refreshView() {
        root.entries = WhichKeyTree.entriesForPath(root.tree, root.path);
        root.crumb = WhichKeyTree.crumbLabel(root.title, root.path);
    }

    function applyConfig(nextConfig) {
        const normalized = WhichKeyTree.normalizeConfig(nextConfig);
        root.enabled = normalized.enabled;
        root.closeOnUnknown = normalized.closeOnUnknown;
        root.title = normalized.title;
        root.tree = WhichKeyTree.buildTree(normalized.binds);
        root.path = [];
        root.refreshView();
        if (!root.enabled) {
            root.open = false;
        }
    }

    function openLeader() {
        if (!root.enabled) {
            return;
        }
        root.path = [];
        root.refreshView();
        root.open = true;
    }

    function close() {
        root.open = false;
        root.path = [];
        root.refreshView();
    }

    function toggleLeader() {
        if (!root.enabled) {
            return;
        }
        if (root.open) {
            root.close();
            return;
        }
        root.openLeader();
    }

    function back() {
        if (!root.open) {
            return;
        }
        if (root.path.length <= 0) {
            root.close();
            return;
        }
        root.path = root.path.slice(0, root.path.length - 1);
        root.refreshView();
    }

    function activateEntry(key) {
        if (!root.open || typeof key !== "string") {
            return;
        }
        const normalizedKey = key.toLowerCase();
        if (!/^[a-z0-9]$/.test(normalizedKey) && normalizedKey !== "<enter>") {
            if (root.closeOnUnknown) {
                root.close();
            }
            return;
        }

        const node = WhichKeyTree.nodeForPath(root.tree, root.path);
        const child = node.children?.[normalizedKey];
        if (!child) {
            if (root.closeOnUnknown) {
                root.close();
            }
            return;
        }

        const hasChildren = Object.keys(child.children || ({})).length > 0;
        if (hasChildren) {
            root.path = root.path.concat([normalizedKey]);
            root.refreshView();
            return;
        }

        const command = typeof child.command === "string" ? child.command.trim() : "";
        root.close();
        if (command) {
            root.commandRequested(command);
        }
    }

    onConfigChanged: root.applyConfig(config)

    Component.onCompleted: root.applyConfig(config)
}
