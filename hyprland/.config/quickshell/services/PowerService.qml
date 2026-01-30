pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/*!
  PowerService
  Executes power actions (lock, suspend, hibernate, logout, reboot, poweroff).
*/
Scope {
    id: root

    function runCommand(args) {
        commandProcess.exec(args);
    }

    function lock() {
        runCommand(["loginctl", "lock-session"]);
    }

    function suspend() {
        runCommand(["systemctl", "suspend"]);
    }

    function hibernate() {
        runCommand(["systemctl", "hibernate"]);
    }

    function logout() {
        runCommand(["hyprctl", "dispatch", "exit"]);
    }

    function reboot() {
        runCommand(["systemctl", "reboot"]);
    }

    function poweroff() {
        runCommand(["systemctl", "poweroff"]);
    }

    Process {
        id: commandProcess
    }
}
