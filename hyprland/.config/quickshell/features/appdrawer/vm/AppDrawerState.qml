pragma ComponentBehavior: Bound

import QtQuick

/*
  AppDrawerState
  Shared per-screen state for app drawer visibility, query, and page selection.
*/
QtObject {
    id: root

    property bool open: false
    property int edgeInset: 0
    property string query: ""
    property int page: 0
    property int selectedIndex: -1

    function resetNavigation() {
        root.page = 0;
        root.selectedIndex = 0;
    }

    function toggle() {
        root.open = !root.open;
        if (!root.open) {
            root.query = "";
            root.resetNavigation();
        }
    }

    function close() {
        root.open = false;
        root.query = "";
        root.resetNavigation();
    }

    function openPanel() {
        root.open = true;
    }

    function setQuery(value) {
        const next = typeof value === "string" ? value : "";
        if (next === root.query) {
            return;
        }

        root.query = next;
        root.resetNavigation();
    }

    function ensurePageInRange(totalPages) {
        const maxPage = Math.max(0, totalPages - 1);
        if (root.page > maxPage) {
            root.page = maxPage;
        }
        if (root.page < 0) {
            root.page = 0;
        }
    }

    function ensureSelectionInRange(totalItems) {
        const maxIndex = Math.max(-1, totalItems - 1);
        if (maxIndex < 0) {
            root.selectedIndex = -1;
            root.page = 0;
            return;
        }

        if (root.selectedIndex < 0) {
            root.selectedIndex = 0;
        } else if (root.selectedIndex > maxIndex) {
            root.selectedIndex = maxIndex;
        }
    }

    function syncPageToSelection(pageSize) {
        const size = Math.max(1, Math.floor(Number(pageSize) || 1));
        if (root.selectedIndex < 0) {
            root.page = 0;
            return;
        }

        root.page = Math.floor(root.selectedIndex / size);
    }

    function selectPage(pageIndex, totalPages, pageSize, totalItems) {
        root.ensurePageInRange(totalPages);
        const maxPage = Math.max(0, totalPages - 1);
        root.page = Math.min(Math.max(0, Math.floor(Number(pageIndex) || 0)), maxPage);

        if (totalItems <= 0) {
            root.selectedIndex = -1;
            return;
        }

        const size = Math.max(1, Math.floor(Number(pageSize) || 1));
        root.selectedIndex = Math.min(totalItems - 1, root.page * size);
    }

    function moveSelection(delta, totalItems, pageSize) {
        if (totalItems <= 0) {
            root.selectedIndex = -1;
            root.page = 0;
            return;
        }

        const offset = Math.floor(Number(delta) || 0);
        if (!offset && root.selectedIndex >= 0) {
            return;
        }

        root.ensureSelectionInRange(totalItems);
        root.selectedIndex = Math.min(totalItems - 1, Math.max(0, root.selectedIndex + offset));
        root.syncPageToSelection(pageSize);
    }

    function nextPage(totalPages) {
        root.ensurePageInRange(totalPages);
        if (root.page + 1 < totalPages) {
            root.page += 1;
        }
    }

    function previousPage(totalPages) {
        root.ensurePageInRange(totalPages);
        if (root.page > 0) {
            root.page -= 1;
        }
    }
}
