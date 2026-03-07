import QtQuick
import QtTest

import "../../services/parsers/VolumeFeedbackParsers.js" as VolumeFeedbackParsers

TestCase {
    name: "VolumeFeedbackParsers"

    function test_resolveSoundPathBuiltins() {
        const home = "/home/tester";
        const base = "/tmp/builtin/";
        compare(
            VolumeFeedbackParsers.resolveSoundPath("warm", base, home),
            "/tmp/builtin/warm.wav"
        );
        compare(
            VolumeFeedbackParsers.resolveSoundPath("bouncy", base, home),
            "/tmp/builtin/bouncy.wav"
        );
        compare(
            VolumeFeedbackParsers.resolveSoundPath("chime", base, home),
            "/tmp/builtin/chime.wav"
        );
    }

    function test_resolveSoundPathDefaultsToWarm() {
        const home = "/home/tester";
        const base = "/tmp/builtin/";
        compare(
            VolumeFeedbackParsers.resolveSoundPath("", base, home),
            "/tmp/builtin/warm.wav"
        );
        compare(
            VolumeFeedbackParsers.resolveSoundPath("unknown-sound", base, home),
            "/tmp/builtin/warm.wav"
        );
        compare(
            VolumeFeedbackParsers.resolveSoundPath(undefined, base, home),
            "/tmp/builtin/warm.wav"
        );
    }

    function test_resolveSoundPathCanDisablePlayback() {
        const home = "/home/tester";
        const base = "/tmp/builtin/";
        compare(VolumeFeedbackParsers.resolveSoundPath("off", base, home), "");
        compare(VolumeFeedbackParsers.resolveSoundPath("none", base, home), "");
        compare(VolumeFeedbackParsers.resolveSoundPath("disabled", base, home), "");
    }

    function test_resolveSoundPathCustomAbsoluteAndHome() {
        const home = "/home/tester";
        compare(
            VolumeFeedbackParsers.resolveSoundPath("/tmp/custom.wav", "", home),
            "/tmp/custom.wav"
        );
        compare(
            VolumeFeedbackParsers.resolveSoundPath("~/sounds/custom.ogg", "", home),
            "/home/tester/sounds/custom.ogg"
        );
    }

    function test_urlToLocalPath() {
        compare(VolumeFeedbackParsers.urlToLocalPath("file:///tmp/my%20dir/"), "/tmp/my dir/");
        compare(VolumeFeedbackParsers.urlToLocalPath("/tmp/plain"), "/tmp/plain");
    }

    function test_normalizeSuppressWhenMicActive() {
        compare(VolumeFeedbackParsers.normalizeSuppressWhenMicActive(undefined), true);
        compare(VolumeFeedbackParsers.normalizeSuppressWhenMicActive(true), true);
        compare(VolumeFeedbackParsers.normalizeSuppressWhenMicActive(false), false);
    }

    function test_directionForDelta() {
        compare(VolumeFeedbackParsers.directionForDelta(0.05), "up");
        compare(VolumeFeedbackParsers.directionForDelta(-0.03), "down");
        compare(VolumeFeedbackParsers.directionForDelta(0.0001), "");
        compare(VolumeFeedbackParsers.directionForDelta(0), "");
    }

    function test_buildPlayCommandQuotesPath() {
        const command = VolumeFeedbackParsers.buildPlayCommand("/tmp/a'b.wav", true);
        verify(command.indexOf("pw-play") >= 0);
        verify(command.indexOf("paplay") >= 0);
        verify(command.indexOf("pactl list source-outputs short") >= 0);
        verify(command.indexOf('"/tmp/a\'b.wav"') >= 0);
    }

    function test_buildPlayCommandWithoutMicGuard() {
        const command = VolumeFeedbackParsers.buildPlayCommand("/tmp/x.wav", false);
        verify(command.indexOf("pactl list source-outputs short") < 0);
    }
}
