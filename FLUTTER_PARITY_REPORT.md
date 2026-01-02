# Hotwire Native Flutter Parity Checklist

This document reflects current Flutter implementation status versus the Android/iOS reference libraries.

## Overall Status

- Core library parity is largely complete.
- Remaining work is concentrated in: platform integration tests for platform-channel features.

## Navigation (Execution Layer)

### Implemented (Flutter)

- [x] NavigationStack with main/modal decisioning and instruction output
- [x] Query string presentation replace behavior
- [x] Pop/refresh/clear_all/replace_root/replace handling in stack
- [x] NavigationHostRegistry for per-tab stacks
- [x] Demo app uses HotwireNavigator per tab with nested Navigator

### Missing (Parity)

- [x] HotwireNavigator / NavigationHierarchyController equivalent
  - [x] Centralized navigation instruction execution (push/replace/pop/clear_all/replace_root)
  - [x] Modal presentation/dismissal orchestration
  - [x] Custom route builder delegate (native screens)
  - [x] Session attach/detach coordination during transitions
  - [x] Historical location refresh helpers at navigator level

## Platform Channel Features

- [x] WebView default user agent integration (native UA + Hotwire prefix)
- [x] WebView debugging toggle
- [x] WebView process termination callback
- [x] HTTP auth challenge handling
- [x] File chooser / camera capture / MIME filters (flutter_inappwebview overrides + file_selector/image_picker)
- [x] Geolocation permission handling
- [x] Offline request interception + cache persistence
- [x] Tests: `test/file_chooser_channel_test.dart`

## Core Library Parity (Implemented)

### Bridge

- [x] Message encoding/decoding + metadata
- [x] Component lifecycle + factories
- [x] BridgeDelegate/BridgeDestination lifecycle + message gating (framework-owned)
- [x] Reply helpers (sync + async)
- [x] JS bridge injection
- [x] Tests: `test/bridge_test.dart`, `test/bridge_delegate_test.dart`

### Path Configuration

- [x] Data/asset/server sources with caching
- [x] Rule matching, settings parsing
- [x] Historical location rules
- [x] Tabs + modal properties parsing
- [x] Tests: `test/path_configuration_test.dart`

### Session

- [x] Visit lifecycle tracking + proposals
- [x] Turbo readiness handshake + queued visits
- [x] Snapshot cache/restore hooks
- [x] Form submission lifecycle
- [x] Cross-origin redirect verification
- [x] Error propagation + retry hook
- [x] Tests: `test/session_test.dart`

### Visit Models

- [x] VisitAction/VisitOptions/VisitResponse
- [x] Visit state modeling
- [x] Tests: `test/visit_models_test.dart`

### Visitable Lifecycle

- [x] HotwireVisitable widget + route-aware attach/detach
- [x] Keep-alive WebView support
- [x] Snapshot cache per visitable
- [x] Bridge lifecycle wiring handled by HotwireVisitable
- [x] Tests: `test/hotwire_visitable_test.dart`

### WebView Policies

- [x] External navigation policy
- [x] New window policy
- [x] Link activated policy
- [x] Reload policy
- [x] Tests: `test/webview_policy_test.dart`

## Demo App Parity

- [x] Bottom tabs (Navigation, Bridge Components, Resources, optional Bugs & Fixes)
- [x] Numbers native list + modal web details
- [x] Image viewer
- [x] Bridge components (menu, form, overflow menu)
- [x] Modal web routes (/new, /edit, /modal, /numbers/:id)
- [x] Navigation stack effects wired via stack instructions

## Test Coverage Gaps (Parity)

- [ ] Navigator execution layer integration tests
- [ ] Platform integration tests (file chooser, geolocation, auth, offline)

## Platform Smoke Tests (Manual)

Use these to validate platform-channel features on iOS and Android before deeper integration tests.

- [ ] File chooser (single) opens picker from a file input
- [ ] File chooser (multiple) returns multiple file paths when allowed
- [ ] MIME filters respected (e.g., accept `image/*`, `.pdf`)
- [ ] Camera capture (`capture=true`) opens camera and returns captured path
- [ ] Geolocation prompt appears when requested and response is applied
- [ ] HTTP auth challenge shows prompt and applies credentials
- [ ] Offline response hook returns cached response when network is blocked

## Reference Files

- Android core: `hotwire-native-android/core/src/main/kotlin/dev/hotwire/core`
- iOS core: `hotwire-native-ios/Source`
- Android navigation: `hotwire-native-android/navigation-fragments/src/main/kotlin/dev/hotwire/navigation`
- iOS navigation: `hotwire-native-ios/Source/Turbo/Navigator`
