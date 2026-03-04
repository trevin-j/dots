pragma Singleton

import QtQuick
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

import "../config" as Config
import "./" as Services
import "parsers/NotificationLogic.js" as NotificationLogic

/*
  NotificationService
  Hosts org.freedesktop.Notifications and exposes popup/history state.
*/
Scope {
    id: root

    property bool dndEnabled: false
    property var history: []
    property var popupQueue: []
    property int unreadCount: 0
    readonly property alias popupModel: popupVisibleModel

    readonly property bool hasNotifications: root.history.length > 0
    readonly property bool hasPopups: popupVisibleModel.count > 0
    readonly property int maxPopupVisible: Math.max(1, Config.Config.notifications?.popup?.maxVisible ?? 4)

    readonly property int maxHistory: Math.max(1, Config.Config.notifications?.history?.maxEntries ?? 120)
    readonly property bool retainTransient: Config.Config.notifications?.history?.retainTransient ?? false
    readonly property bool showReloadedInHistory: Config.Config.notifications?.history?.showReloaded ?? false

    property int _serial: 0
    property bool _hydratedDnd: false

    function _syncPopupVisibleModel() {
        const desired = root.popupQueue.slice(0, root.maxPopupVisible);
        const desiredIds = ({ });

        for (const entry of desired) {
            desiredIds[String(entry.id)] = true;
        }

        for (let row = popupVisibleModel.count - 1; row >= 0; row -= 1) {
            const current = popupVisibleModel.get(row);
            if (!desiredIds[String(current.entryId)]) {
                popupVisibleModel.remove(row, 1);
            }
        }

        for (let row = 0; row < desired.length; row += 1) {
            const expected = desired[row];
            const current = row < popupVisibleModel.count ? popupVisibleModel.get(row) : null;

            if (current && current.entryId === expected.id) {
                if (current.serial !== expected.serial) {
                    popupVisibleModel.setProperty(row, "popupEntry", expected);
                    popupVisibleModel.setProperty(row, "serial", expected.serial);
                }
                continue;
            }

            let foundRow = -1;
            for (let probe = row + 1; probe < popupVisibleModel.count; probe += 1) {
                if (popupVisibleModel.get(probe).entryId === expected.id) {
                    foundRow = probe;
                    break;
                }
            }

            if (foundRow >= 0) {
                popupVisibleModel.move(foundRow, row, 1);
                const movedCurrent = popupVisibleModel.get(row);
                if (!movedCurrent || movedCurrent.serial !== expected.serial) {
                    popupVisibleModel.setProperty(row, "popupEntry", expected);
                    popupVisibleModel.setProperty(row, "serial", expected.serial);
                }
            } else {
                popupVisibleModel.insert(row, {
                    entryId: expected.id,
                    serial: expected.serial,
                    popupEntry: expected
                });
            }
        }

        while (popupVisibleModel.count > desired.length) {
            popupVisibleModel.remove(popupVisibleModel.count - 1, 1);
        }
    }

    function _urgencyText(notification) {
        return NotificationUrgency.toString(notification?.urgency);
    }

    function _entryFor(notification) {
        return ({
            serial: ++root._serial,
            id: notification.id,
            notification: notification,
            appName: NotificationLogic.sanitizeText(notification.appName),
            summary: NotificationLogic.sanitizeText(notification.summary),
            body: NotificationLogic.sanitizeText(notification.body),
            receivedAtMs: Date.now(),
            urgency: root._urgencyText(notification),
            transient: !!notification.transient,
            unseen: true
        });
    }

    function _replaceOrInsert(list, entry) {
        const next = list.slice();
        const idx = next.findIndex(candidate => candidate && candidate.id === entry.id);
        if (idx >= 0) {
            next.splice(idx, 1, entry);
        } else {
            next.unshift(entry);
        }
        return next;
    }

    function _removeById(list, id) {
        return list.filter(entry => entry && entry.id !== id);
    }

    function _recountUnread() {
        root.unreadCount = root.history.reduce((total, entry) => total + (entry && entry.unseen ? 1 : 0), 0);
    }

    function _trimHistory() {
        if (root.history.length <= root.maxHistory) {
            return;
        }
        root.history = root.history.slice(0, root.maxHistory);
    }

    function _syncEntryArrays(entry) {
        const nextHistory = root._replaceOrInsert(root.history, entry);
        root.history = nextHistory;
        root._trimHistory();
        root._recountUnread();

        const popupEnabled = NotificationLogic.shouldShowPopup({
            enabled: Config.Config.notifications?.popup?.enabled ?? true,
            lastGeneration: !!entry.notification.lastGeneration,
            dndEnabled: root.dndEnabled,
            showOnDnd: Config.Config.notifications?.popup?.showOnDnd ?? false,
            showCriticalOnDnd: Config.Config.notifications?.popup?.showCriticalOnDnd ?? true,
            urgency: entry.urgency
        });

        if (popupEnabled) {
            root.popupQueue = root._replaceOrInsert(root.popupQueue, entry);
        }
    }

    function _onClosed(notification, reason) {
        if (!notification) {
            return;
        }
        root.popupQueue = root._removeById(root.popupQueue, notification.id);

        const reasonText = NotificationCloseReason.toString(reason || NotificationCloseReason.CloseRequested).toLowerCase();
        if (reasonText.indexOf("dismissed") >= 0) {
            root.history = root._removeById(root.history, notification.id);
            root._recountUnread();
        }
    }

    onPopupQueueChanged: root._syncPopupVisibleModel()
    onMaxPopupVisibleChanged: root._syncPopupVisibleModel()

    ListModel {
        id: popupVisibleModel
        dynamicRoles: true
    }

    function setDndEnabled(next) {
        const desired = !!next;
        if (desired === root.dndEnabled) {
            return;
        }

        root.dndEnabled = desired;
        Services.RuntimeStateService.setNotificationsDndEnabled(desired);

        if (desired) {
            root.popupQueue = root.popupQueue.filter(entry => {
                if (!entry || !entry.notification) {
                    return false;
                }

                return NotificationLogic.shouldShowPopup({
                    enabled: true,
                    lastGeneration: !!entry.notification.lastGeneration,
                    dndEnabled: true,
                    showOnDnd: Config.Config.notifications?.popup?.showOnDnd ?? false,
                    showCriticalOnDnd: Config.Config.notifications?.popup?.showCriticalOnDnd ?? true,
                    urgency: entry.urgency
                });
            });
        }
    }

    function toggleDnd() {
        root.setDndEnabled(!root.dndEnabled);
    }

    function timeoutMsFor(entry) {
        if (!entry || !entry.notification) {
            return 0;
        }

        return NotificationLogic.resolveTimeoutMs({
            urgency: entry.urgency,
            clientSeconds: entry.notification.expireTimeout,
            ignoreClient: Config.Config.notifications?.popup?.ignoreTimeoutFromClients ?? false,
            defaultTimeoutMs: Config.Config.notifications?.popup?.defaultTimeoutMs ?? 6000,
            criticalTimeoutMs: Config.Config.notifications?.popup?.criticalTimeoutMs ?? 0
        });
    }

    function dismiss(entry) {
        if (!entry || !entry.notification) {
            return;
        }

        entry.notification.dismiss();
    }

    function dismissById(id) {
        const entry = root.history.find(candidate => candidate && candidate.id === id)
            || root.popupQueue.find(candidate => candidate && candidate.id === id);
        if (entry) {
            root.dismiss(entry);
        }
    }

    function dismissAll() {
        const seen = ({});
        for (const entry of root.history.concat(root.popupQueue)) {
            if (!entry || !entry.notification) {
                continue;
            }

            const key = String(entry.id);
            if (seen[key]) {
                continue;
            }
            seen[key] = true;
            entry.notification.dismiss();
        }
    }

    function markSeen(id) {
        const next = root.history.map(entry => {
            if (!entry || entry.id !== id || !entry.unseen) {
                return entry;
            }

            return ({
                serial: entry.serial,
                id: entry.id,
                notification: entry.notification,
                appName: entry.appName,
                summary: entry.summary,
                body: entry.body,
                receivedAtMs: entry.receivedAtMs,
                urgency: entry.urgency,
                transient: entry.transient,
                unseen: false
            });
        });
        root.history = next;
        root._recountUnread();
    }

    function markAllRead() {
        const next = root.history.map(entry => {
            if (!entry || !entry.unseen) {
                return entry;
            }

            return ({
                serial: entry.serial,
                id: entry.id,
                notification: entry.notification,
                appName: entry.appName,
                summary: entry.summary,
                body: entry.body,
                receivedAtMs: entry.receivedAtMs,
                urgency: entry.urgency,
                transient: entry.transient,
                unseen: false
            });
        });
        root.history = next;
        root._recountUnread();
    }

    function invokeAction(entry, action) {
        if (!entry || !action) {
            return;
        }
        action.invoke();
    }

    NotificationServer {
        id: server

        keepOnReload: Config.Config.notifications?.daemon?.keepOnReload ?? true
        actionsSupported: Config.Config.notifications?.daemon?.actionsSupported ?? true
        actionIconsSupported: Config.Config.notifications?.daemon?.actionIconsSupported ?? false
        bodySupported: Config.Config.notifications?.daemon?.bodySupported ?? true
        bodyMarkupSupported: Config.Config.notifications?.daemon?.bodyMarkupSupported ?? false
        bodyHyperlinksSupported: Config.Config.notifications?.daemon?.bodyHyperlinksSupported ?? false
        bodyImagesSupported: Config.Config.notifications?.daemon?.bodyImagesSupported ?? false
        imageSupported: Config.Config.notifications?.daemon?.imageSupported ?? true
        persistenceSupported: Config.Config.notifications?.daemon?.persistenceSupported ?? true
        inlineReplySupported: Config.Config.notifications?.daemon?.inlineReplySupported ?? false
        extraHints: Config.Config.notifications?.daemon?.extraHints ?? []

        onNotification: notification => {
            if (!notification) {
                return;
            }

            notification.tracked = true;
            notification.closed.connect(reason => root._onClosed(notification, reason));

            const keepHistory = NotificationLogic.shouldRetainInHistory(
                notification,
                root.retainTransient,
                root.showReloadedInHistory
            );

            const entry = root._entryFor(notification);
            if (keepHistory) {
                root._syncEntryArrays(entry);
            } else {
                const popupAllowed = NotificationLogic.shouldShowPopup({
                    enabled: Config.Config.notifications?.popup?.enabled ?? true,
                    lastGeneration: !!notification.lastGeneration,
                    dndEnabled: root.dndEnabled,
                    showOnDnd: Config.Config.notifications?.popup?.showOnDnd ?? false,
                    showCriticalOnDnd: Config.Config.notifications?.popup?.showCriticalOnDnd ?? true,
                    urgency: entry.urgency
                });
                if (popupAllowed) {
                    root.popupQueue = root._replaceOrInsert(root.popupQueue, entry);
                }
            }
        }
    }

    Connections {
        target: Services.RuntimeStateService

        function onReadyChanged() {
            if (!Services.RuntimeStateService.ready || root._hydratedDnd) {
                return;
            }
            root._hydratedDnd = true;
            root.dndEnabled = Services.RuntimeStateService.notificationsDndEnabled;
        }

        function onNotificationsDndEnabledChanged() {
            if (!root._hydratedDnd) {
                return;
            }
            if (root.dndEnabled !== Services.RuntimeStateService.notificationsDndEnabled) {
                root.dndEnabled = Services.RuntimeStateService.notificationsDndEnabled;
            }
        }
    }

    IpcHandler {
        target: "notifications"

        function toggleDnd(): void {
            root.toggleDnd();
        }

        function clear(): void {
            root.dismissAll();
        }

        function dismiss(id: int): void {
            root.dismissById(id);
        }
    }
}
