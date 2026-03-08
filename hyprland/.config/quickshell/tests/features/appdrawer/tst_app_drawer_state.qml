import QtQuick
import QtTest

import "../../../features/appdrawer/vm" as AppDrawerVm

TestCase {
    name: "AppDrawerState"

    AppDrawerVm.AppDrawerState {
        id: state
    }

    function init() {
        state.open = false;
        state.query = "";
        state.page = 0;
        state.selectedIndex = -1;
        state.edgeInset = 0;
    }

    function test_toggleAndCloseResetsState() {
        state.openPanel();
        state.setQuery("fire");
        state.page = 2;

        state.close();
        compare(state.open, false);
        compare(state.query, "");
        compare(state.page, 0);
        compare(state.selectedIndex, 0);
    }

    function test_queryResetsPage() {
        state.openPanel();
        state.page = 2;
        state.selectedIndex = 7;
        state.setQuery("abc");
        compare(state.page, 0);
        compare(state.selectedIndex, 0);
    }

    function test_pageNavigation() {
        state.page = 0;
        state.nextPage(3);
        compare(state.page, 1);
        state.nextPage(3);
        compare(state.page, 2);
        state.nextPage(3);
        compare(state.page, 2);
        state.previousPage(3);
        compare(state.page, 1);
    }

    function test_ensureSelectionInRange() {
        state.selectedIndex = 9;
        state.ensureSelectionInRange(3);
        compare(state.selectedIndex, 2);

        state.ensureSelectionInRange(0);
        compare(state.selectedIndex, -1);
        compare(state.page, 0);
    }

    function test_moveSelectionTracksPage() {
        state.selectedIndex = 0;
        state.moveSelection(4, 20, 6);
        compare(state.selectedIndex, 4);
        compare(state.page, 0);

        state.moveSelection(4, 20, 6);
        compare(state.selectedIndex, 8);
        compare(state.page, 1);
    }

    function test_selectPageMovesSelectionToFirstItem() {
        state.selectPage(2, 4, 6, 20);
        compare(state.page, 2);
        compare(state.selectedIndex, 12);

        state.selectPage(3, 4, 6, 20);
        compare(state.page, 3);
        compare(state.selectedIndex, 18);
    }
}
