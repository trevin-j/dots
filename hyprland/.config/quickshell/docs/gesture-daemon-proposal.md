# Gesture Daemon Proposal (Future Work)

## Goal

Make shell gestures feel immediate (track finger motion) instead of only triggering on gesture release.

Current Hyprland `gesture = ... dispatcher, exec, ...` behavior is end-triggered, so Quickshell only gets an action after release.

## Proposed Approach

Build a very small Rust daemon (example name: `qs-gestured`) that:

1. Reads touchpad gesture events from input devices.
2. Emits `begin/update/end` gesture messages to Quickshell.
3. Lets Quickshell decide behavior based on current shell state (open panels, direction priorities, etc).

This keeps compositor config simple and puts panel/state logic in Quickshell.

## Why a Daemon

- Hyprland can run gesture actions, but custom dispatch through IPC is generally end-based.
- For "panel follows finger" UX, Quickshell needs per-frame updates (`dx/dy/progress/velocity`), not just a final direction.

## High-Level Data Flow

1. Touchpad gesture starts.
2. Daemon sends: `gesture.begin` (fingers, direction candidate, timestamp).
3. Daemon sends repeated: `gesture.update` (delta/progress/velocity).
4. Daemon sends: `gesture.end` (final direction, settle hint).
5. Quickshell `GestureRouterService` routes to the correct panel VM:
   - left: open control center (if closed)
   - right: close control center (if open)
   - future: up/down to other panels

## Permissions and Security

Important: a `systemd --user` service by itself does **not** grant access to `/dev/input/event*`.

Use package-managed permissions:

- Install a udev rule (preferred) that grants active-session ACL access (`TAG+="uaccess"`) to the touchpad device(s).
- Run daemon as a normal user service, not root.

Alternative options:

- Add user to `input` group (works, broader access).
- Root broker service forwarding sanitized events to user service (more complex).

## Packaging Plan (Arch)

Create a `PKGBUILD` for system install that places:

- Binary: `/usr/bin/qs-gestured`
- User unit: `/usr/lib/systemd/user/qs-gestured.service`
- Udev rule: `/etc/udev/rules.d/99-qs-gestured-touchpad.rules`
- Optional config: `/etc/qs-gestured/config.toml`

User activation model:

1. Install package.
2. Reload udev rules.
3. Enable/start user service.

## Quickshell Integration Shape

Suggested components:

- `services/GestureRouterService.qml`
  - Receives daemon events
  - Applies direction lock and ownership rules
  - Resolves conflicts (e.g. if panel A open, right closes A before opening B)

- Feature VMs (e.g. control center state)
  - Expose `gestureProgress` (0..1)
  - Implement settle behavior on end (`open` vs `close`)

## Hyprland Config Strategy

- Keep `4-finger horizontal` for native workspace swipe.
- Keep `3-finger` bindings as fallback/end-trigger if daemon is unavailable.
- Prefer daemon-driven interaction when running.

## Rust Implementation Notes (Minimal)

- Keep binary focused: no UI logic, only capture + normalize + emit.
- Suggested crates (examples): `evdev`, `tokio`, `serde`, `toml`.
- IPC format should be stable and compact (JSON lines or unix socket frames).
- Add simple rate limiting/coalescing so update frequency is high but bounded.

## Risks / Edge Cases

- Multi-touchpad or hotplug device changes.
- Session switching / seat changes.
- Input permission regressions after updates.
- Gesture conflict with other desktop tools.

## MVP Scope Suggestion

1. Support 3-finger horizontal only.
2. Drive control center progress with update events.
3. Left opens, right closes (state-aware, non-toggle).
4. Add logging and fallback to current end-trigger behavior.
