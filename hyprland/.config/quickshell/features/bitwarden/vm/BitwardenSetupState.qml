pragma ComponentBehavior: Bound

import QtQuick

/*
  BitwardenSetupState
  Per-screen state for the Bitwarden setup popup shown when account config is missing.
 */
QtObject {
    id: root

    property bool open: false
    property string email: ""
    property string serverUrl: ""
    property string errorText: ""
    property bool submitting: false

    function openDialog(initialEmail, initialServerUrl) {
        root.email = typeof initialEmail === "string" ? initialEmail : "";
        root.serverUrl = typeof initialServerUrl === "string" ? initialServerUrl : "";
        root.errorText = "";
        root.submitting = false;
        root.open = true;
    }

    function closeDialog() {
        root.open = false;
        root.errorText = "";
        root.submitting = false;
    }
}
