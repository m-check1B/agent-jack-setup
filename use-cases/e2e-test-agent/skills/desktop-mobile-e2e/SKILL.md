---
name: desktop-mobile-e2e
description: Use this when end-to-end testing native macOS apps, Electron or WebView desktop apps, or iOS simulator flows via Paired Mac Device Bridge (app.status, window.screenshot, window.ax_tree) or Tentacles.
---

Verify native desktop applications (macOS Swift/AppKit/SwiftUI, Electron/WebView shells) and mobile builds (iOS Simulator / XCTest) using Agent Jack's Paired Mac Device Bridge and Tentacles local execution paths.

## Execution Surfaces and Honesty Gate

1. **Paired Mac Device Bridge (`machines.dispatch`, read-only consent-gated verbs)**:
   - Use `machines.list` to identify the seat's paired Mac, then call read-only `machines.dispatch` verbs when enabled in Desktop Settings:
     - `app.status` — check whether an allowlisted macOS application bundle is installed/running without mutating state.
     - `window.screenshot` — capture a bounded screenshot of an allowlisted application window (requires macOS Screen Recording consent).
     - `window.ax_tree` — inspect the bounded macOS Accessibility (`AXUIElement`) hierarchy of an allowlisted application window (requires macOS Accessibility consent).
2. **Paired Mac / Tentacles local route (`Local Claude` / `Local Codex` or `tentacles.hire`)**:
   - Use for building and running automated native suites (`swift test`, `xcodebuild test`), isolated Electron Playwright launches, read-only signature checks (`codesign -dv --verbose=2`), and iOS Simulator flows (`xcrun simctl`).
3. **Fail honest when unattached or unconsented.** If no Paired Mac is connected, or if macOS Screen Recording / Accessibility permissions or Xcode Simulator runtimes are absent, mark affected rows `BLOCKED` with the exact missing prerequisite. Never fabricate native app results.
4. **Never touch personal user data or macOS Login Keychain.** Launch test builds with isolated fixture directories or in-memory test stores; never read, modify, or unlock the user's Login Keychain or personal accounts.

## macOS Native Apps (Swift / AppKit / SwiftUI)

1. **Build, test, and provenance verification**:
   - Record app bundle ID, version, exact git SHA, macOS version (`sw_vers`), and Swift/Xcode version.
   - Run automated unit/UI test suites (`swift test` / `xcodebuild test`) confirming zero Login Keychain access and recording exact executed/passed/skipped/failed counts.
   - For signed release `.app` bundles, run read-only signature check (`codesign -dv --verbose=2 <App.app>`) and verify zero new crash reports in `~/Library/Logs/DiagnosticReports/`.
2. **Live window & Accessibility inspection**:
   - Verify app status via `machines.dispatch(..., method="app.status")`.
   - Inspect interactive controls via `machines.dispatch(..., method="window.ax_tree")` to confirm primary buttons, tabs, and menus exist, are enabled, and carry accessible labels.
   - Capture Light and Dark window screenshots via `machines.dispatch(..., method="window.screenshot")` (or `screencapture -x -l <windowID>`) and inspect via vision for truncation, dark-mode contrast, and window sizing defects.

## Electron and WebView Desktop Apps

1. **Shell lifecycle and security boundary**:
   - Verify cold start, window chrome, preload/IPC boundary health, deep-link registration, and offline fallback screen when the backend is unreachable.
2. **Isolated Playwright Electron verification**:
   - Drive Electron builds with Playwright `_electron.launch()` against an isolated `--user-data-dir` fixture directory, asserting `0` renderer console errors, `0` uncaught main-process exceptions, and clean read-only updater manifest checks.

## Mobile Apps (iOS Simulator / Mobile WebView)

1. **Simulator lifecycle** (Paired Mac with Xcode):
   - Enumerate runtimes (`xcrun simctl list devices available`), use an ephemeral test simulator, install the `.app`, launch with fixture env, and inspect for crash logs.
2. **Automated UI flows and evidence**:
   - Run `XCUITest` targets when present; capture Light/Dark screenshots (`xcrun simctl io <udid> screenshot` + `xcrun simctl ui <udid> appearance dark|light`) and verify deep links and safe-area insets.
3. **Physical device rule**:
   - Mark physical-hardware-only rows (CarPlay, real push delivery, hardware biometrics) `BLOCKED (physical device human check required)` with exact manual steps.

## Output Contract

Deliver per-platform rows (`macos-native`, `electron-desktop`, `ios-simulator`) to `evidence-pack-verdict` with OS/Swift/Xcode/Electron versions, exact build SHA, test counts, crash-log status, and window/simulator screenshots.
