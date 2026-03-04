import QtQuick
import QtTest

import "../../services/parsers/NotificationLogic.js" as NotificationLogic

TestCase {
    name: "NotificationLogic"

    function test_sanitizeText() {
        compare(NotificationLogic.sanitizeText(" hello\nworld\r\n "), "hello world");
        compare(NotificationLogic.sanitizeText(null), "");
    }

    function test_shouldRetainInHistory() {
        compare(NotificationLogic.shouldRetainInHistory({ transient: false, lastGeneration: false }, false, false), true);
        compare(NotificationLogic.shouldRetainInHistory({ transient: true, lastGeneration: false }, false, false), false);
        compare(NotificationLogic.shouldRetainInHistory({ transient: false, lastGeneration: true }, false, false), false);
        compare(NotificationLogic.shouldRetainInHistory({ transient: true, lastGeneration: true }, true, true), true);
    }

    function test_shouldShowPopup() {
        compare(NotificationLogic.shouldShowPopup({
            enabled: true,
            lastGeneration: false,
            dndEnabled: false,
            showOnDnd: false,
            showCriticalOnDnd: true,
            urgency: "Normal"
        }), true);

        compare(NotificationLogic.shouldShowPopup({
            enabled: true,
            lastGeneration: false,
            dndEnabled: true,
            showOnDnd: false,
            showCriticalOnDnd: true,
            urgency: "Critical"
        }), true);

        compare(NotificationLogic.shouldShowPopup({
            enabled: true,
            lastGeneration: false,
            dndEnabled: true,
            showOnDnd: false,
            showCriticalOnDnd: true,
            urgency: "Normal"
        }), false);
    }

    function test_resolveTimeoutMs() {
        compare(NotificationLogic.resolveTimeoutMs({
            urgency: "Normal",
            clientSeconds: 2,
            ignoreClient: false,
            defaultTimeoutMs: 6000,
            criticalTimeoutMs: 0
        }), 2000);

        compare(NotificationLogic.resolveTimeoutMs({
            urgency: "Critical",
            clientSeconds: -1,
            ignoreClient: false,
            defaultTimeoutMs: 6000,
            criticalTimeoutMs: 0
        }), 0);

        compare(NotificationLogic.resolveTimeoutMs({
            urgency: "Normal",
            clientSeconds: 5,
            ignoreClient: true,
            defaultTimeoutMs: 6000,
            criticalTimeoutMs: 0
        }), 6000);
    }
}
