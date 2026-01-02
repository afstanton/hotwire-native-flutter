# Hotwired Native Flutter Parity Checklist

This document tracks concrete implementation tasks needed to achieve feature parity with Android and iOS reference implementations.

## Overall Status

**Parity**: ~64% (7/11 major feature areas complete)

**Critical Blocker**: Navigation execution layer

---

## 🔴 CRITICAL: Navigation Implementation (40% Complete)

### Navigator Core

- [ ] Create `HotwireNavigator` class
  - [ ] Manage main Navigator 2.0 router delegate
  - [ ] Manage modal Navigator 2.0 router delegate
  - [ ] Implement session coordination (attach/detach during navigation)
  - [ ] Track active visitable during navigation transitions
  - [ ] Implement `NavigatorDelegate` pattern for custom controllers

- [ ] Implement `NavigationHierarchyController` equivalent
  - [ ] Route execution based on `NavigationInstruction` from `NavigationStack`
  - [ ] Handle push operations with animation control
  - [ ] Handle replace operations
  - [ ] Handle pop operations (main vs modal context aware)
  - [ ] Handle clearAll (dismiss modal + pop to root)
  - [ ] Handle replaceRoot
  - [ ] Handle refresh (per-context awareness)
  - [ ] Handle none (no-op)

- [ ] Modal presentation logic
  - [ ] Present modal navigation stack
  - [ ] Dismiss modal with animation
  - [ ] Modal style configuration (from path properties)
  - [ ] Detect if in modal context

- [ ] Route building integration
  - [ ] Build MaterialPageRoute/CupertinoPageRoute based on platform
  - [ ] Animation configuration based on VisitAction (advance = push animation, restore = no animation)
  - [ ] Custom route builder delegate for native screens

- [ ] Session lifecycle integration
  - [ ] Attach session WebView to active visitable
  - [ ] Detach session WebView when navigating away
  - [ ] Handle session switching between main and modal
  - [ ] Coordinate snapshot cache during navigation

- [ ] Historical location routing
  - [ ] Implement `refreshIfTopViewControllerIsVisitable` equivalent
  - [ ] Apply historical location actions (recede/resume/refresh)
  - [ ] Dismiss modal on historical location when needed

### Navigator Tests

- [ ] Test navigation hierarchy (push/pop/replace)
- [ ] Test modal presentation and dismissal
- [ ] Test clearAll behavior
- [ ] Test replaceRoot behavior
- [ ] Test refresh in different contexts
- [ ] Test session coordination during navigation
- [ ] Test custom controller delegation
- [ ] Test animation control
- [ ] Test historical location routing
- [ ] Integration tests with demo app flows

### Reference Files to Study

- iOS: [Navigator.swift](file:///Users/afstanton/code/hotwired/hotwire-native-ios/Source/Turbo/Navigator/Navigator.swift) (365 lines)
- iOS: [NavigationHierarchyController.swift](file:///Users/afstanton/code/hotwired/hotwire-native-ios/Source/Turbo/Navigator/NavigationHierarchyController.swift) (241 lines)
- Android: Fragment transaction management patterns

---

## 🟡 HIGH PRIORITY: Platform Channel Features

### File Upload Support

- [ ] Implement platform channel for file chooser
  - [ ] Android: Hook into WebChromeClient.onShowFileChooser
  - [ ] iOS: Hook into WKUIDelegate.runOpenPanelWithParameters
  - [ ] Dart: File picker integration (file_picker package)

- [ ] File chooser features
  - [ ] MIME type filtering (acceptTypes)
  - [ ] Multiple file selection
  - [ ] Camera capture mode
  - [ ] Return file paths to WebView

- [ ] URI helper utilities
  - [ ] Get file attributes (name, size, MIME type)
  - [ ] File path to URI conversion

- [ ] Tests
  - [ ] Test file chooser params parsing
  - [ ] Test MIME type filtering
  - [ ] Test multiple selection
  - [ ] Test camera capture mode
  - [ ] Mock file picker integration

### Reference Files

- Android: [FileChooserDelegate.kt](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/files/delegates/FileChooserDelegate.kt)
- Android: [CameraCaptureDelegate.kt](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/files/delegates/CameraCaptureDelegate.kt)
- Android: [UriHelper.kt](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/files/util/UriHelper.kt)

---

### Offline Caching

- [ ] Implement platform channel for request interception
  - [ ] Android: Intercept via WebViewClient.shouldInterceptRequest
  - [ ] iOS: Intercept via WKURLSchemeHandler or custom protocol
  - [ ] Dart: Offline cache strategy interface

- [ ] Offline request handler
  - [ ] Request matching logic
  - [ ] Cache lookup
  - [ ] Return cached response to WebView
  - [ ] Delegate pattern for custom offline handlers

- [ ] Pre-cache API
  - [ ] `preCacheLocation(String location)` on Session
  - [ ] Fetch and store in offline cache
  - [ ] Cache key generation

- [ ] Offline HTTP repository
  - [ ] HTTP client for fetching resources
  - [ ] Cache storage (shared_preferences or sqflite)
  - [ ] Cache eviction policy
  - [ ] Cache size limits

- [ ] Tests
  - [ ] Test request interception
  - [ ] Test cache hit/miss logic
  - [ ] Test pre-cache API
  - [ ] Test cache eviction
  - [ ] Test offline request handler delegation

### Reference Files

- Android: [OfflineWebViewRequestInterceptor.kt](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/turbo/offline/OfflineWebViewRequestInterceptor.kt)
- Android: [OfflineHttpRepository.kt](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/turbo/offline/OfflineHttpRepository.kt) (7000 bytes)
- Android: [OfflineRequestHandler.kt](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/turbo/offline/OfflineRequestHandler.kt)
- Android: [OfflinePreCacheRequest.kt](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/turbo/offline/OfflinePreCacheRequest.kt)

---

### WebView Configuration

- [ ] Default user agent integration
  - [ ] Platform channel to get default WebView user agent
  - [ ] Compose with Hotwire component list
  - [ ] Set on WebView creation

- [ ] WebView debugging toggle
  - [ ] Platform channel to enable/disable WebView debugging
  - [ ] Android: WebView.setWebContentsDebuggingEnabled
  - [ ] iOS: WKWebView inspector

- [ ] Reload policy handler
  - [ ] Implement missing reload decision logic
  - [ ] Platform channel if native-level control needed

- [ ] Tests
  - [ ] Test user agent composition
  - [ ] Test debugging toggle
  - [ ] Test reload policy

---

## 🟢 MEDIUM PRIORITY: Advanced Platform Features

### Geolocation Permissions

- [ ] Implement platform channel for geolocation permissions
  - [ ] Android: Hook into WebChromeClient.onGeolocationPermissionsShowPrompt
  - [ ] iOS: Hook into WKUIDelegate geolocation delegate
  - [ ] Dart: Permission request delegation

- [ ] Geolocation permission handler
  - [ ] Request system permissions (permission_handler package)
  - [ ] Delegate pattern for custom permission UI
  - [ ] Allow/deny decision propagation to WebView
  - [ ] Remember decision option

- [ ] Tests
  - [ ] Test permission request flow
  - [ ] Test allow/deny actions
  - [ ] Test retain flag

### Reference Files

- Android: [GeolocationPermissionDelegate.kt](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/files/delegates/GeolocationPermissionDelegate.kt)

---

### HTTP Authentication

- [ ] Implement platform channel for HTTP auth
  - [ ] Android: Hook into WebViewClient.onReceivedHttpAuthRequest
  - [ ] iOS: Hook into WKNavigationDelegate didReceiveAuthenticationChallenge
  - [ ] Dart: Auth challenge delegation

- [ ] HTTP auth handler
  - [ ] Delegate pattern for credential collection
  - [ ] Actions: cancel, useCredential, performDefaultHandling
  - [ ] Credential storage (flutter_secure_storage)

- [ ] Session delegate integration
  - [ ] Add `sessionDidReceiveAuthChallenge` to SessionDelegate
  - [ ] Wire up in Session class

- [ ] Tests
  - [ ] Test auth challenge propagation
  - [ ] Test credential submission
  - [ ] Test cancel action
  - [ ] Test default handling

---

### WebView Process Termination

- [ ] Implement platform channel for process termination
  - [ ] Android: Hook into WebViewClient.onRenderProcessGone
  - [ ] iOS: Hook into WKNavigationDelegate webViewWebContentProcessDidTerminate
  - [ ] Dart: Termination event handling

- [ ] Process termination handler
  - [ ] Detect termination reason (crashed/killed/unknown)
  - [ ] Delegate pattern for custom termination handling
  - [ ] Auto-reload logic (check if WebView is visible)
  - [ ] Session reset on termination

- [ ] App lifecycle integration
  - [ ] Track app state (foreground/background)
  - [ ] Queue terminations in background
  - [ ] Reload when app returns to foreground

- [ ] Session delegate integration
  - [ ] Add `sessionWebViewProcessDidTerminate` to SessionDelegate

- [ ] Tests
  - [ ] Test termination detection
  - [ ] Test auto-reload logic
  - [ ] Test background queueing
  - [ ] Test session reset

---

## ✅ COMPLETE: Core Features (100% Parity)

### Bridge System
- [x] Message encoding/decoding
- [x] Component lifecycle (connect/disconnect)
- [x] Component factory registration
- [x] WebView bridge injection
- [x] Reply handling
- [x] JSON encode/decode hooks
- [x] User agent composition for components
- [x] Tests: [bridge_test.dart](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/test/bridge_test.dart)

### Path Configuration
- [x] Load from data/asset/remote with caching
- [x] Regex pattern matching
- [x] Path properties parsing (presentation, context, uri, title, etc.)
- [x] Historical location behavior
- [x] Query string presentation
- [x] Settings map parsing
- [x] Repository caching with invalidation
- [x] Tests: [path_configuration_test.dart](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/test/path_configuration_test.dart)

### Session Core
- [x] Visit lifecycle tracking
- [x] Visit proposal handling
- [x] WebView-backed session (cold boot vs JS visits)
- [x] Snapshot cache/restore
- [x] Form submission lifecycle
- [x] Error handling and propagation
- [x] Cross-origin redirect handling
- [x] Restoration identifiers
- [x] Turbo readiness handshake
- [x] Tests: [session_test.dart](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/test/session_test.dart)

### Visit Models
- [x] VisitAction, VisitOptions, VisitResponse
- [x] VisitProposal with properties/parameters
- [x] Visit state modeling
- [x] Tests: [visit_models_test.dart](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/test/visit_models_test.dart)

### Visitable Lifecycle
- [x] HotwireVisitable widget
- [x] Activate/deactivate lifecycle
- [x] WebView keep-alive support
- [x] Snapshot cache per visitable
- [x] Tests: [hotwire_visitable_test.dart](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/test/hotwire_visitable_test.dart)

### WebView Policies
- [x] External navigation (non-http schemes)
- [x] New window policy
- [x] Link activated policy
- [x] Policy handler chain
- [x] Tests: [webview_policy_test.dart](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/test/webview_policy_test.dart)

### Error Handling
- [x] Web error types (network/timeout/content-type/http/page-load)
- [x] SSL error type mapping
- [x] Error view/handler hooks
- [x] Retry handler
- [x] Tests: [turbo_error_test.dart](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/test/turbo_error_test.dart), [ssl_error_test.dart](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/test/ssl_error_test.dart)

---

## ⚠️ TEST COVERAGE GAPS

### Missing Tests vs Reference Implementations

The Android and iOS implementations have extensive test coverage that Flutter is missing:

#### Navigator/Routing Tests
- [ ] Navigation hierarchy controller tests
  - Reference: iOS has extensive UINavigationController hierarchy tests
  - Reference: Android has Fragment transaction tests
  - **Missing in Flutter**: No navigator-level integration tests

#### File Handling Tests
- [ ] File chooser delegate tests
- [ ] Camera capture delegate tests
- [ ] URI helper tests
- [ ] File provider tests
  - Reference: Android has comprehensive file handling tests
  - **Missing in Flutter**: No implementation = no tests

#### Offline Caching Tests
- [ ] Request interception tests
- [ ] Cache repository tests
- [ ] Cache eviction policy tests
- [ ] Pre-cache API tests
  - Reference: Android has OfflineHttpRepository tests
  - **Missing in Flutter**: No implementation = no tests

#### Platform Callback Tests
- [ ] WebView process termination tests
- [ ] HTTP auth challenge tests
- [ ] Geolocation permission tests
  - Reference: Both Android and iOS have these
  - **Missing in Flutter**: Only models exist in [platform_hooks.dart](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/lib/src/webview/platform_hooks.dart)

#### Integration Tests
- [ ] End-to-end navigation flow tests
- [ ] Modal presentation flow tests
- [ ] Session coordination tests
- [ ] Full app lifecycle tests
  - Reference: Both platforms have demo app integration tests
  - **Missing in Flutter**: Demo exists but no integration tests

---

## Implementation Phases

| Phase | Feature | Priority |
|-------|---------|----------|
| 1 | **Navigator Implementation** | 🔴 Critical |
| 2 | File Upload Support | 🟡 High |
| 2 | Offline Caching | 🟡 High |
| 2 | WebView Configuration | 🟡 High |
| 3 | Geolocation Permissions | 🟢 Medium |
| 3 | HTTP Authentication | 🟢 Medium |
| 3 | Process Termination | 🟢 Medium |

---

## Implementation Strategy

### Phase 1: Unblock App Development (Critical)

Implement Navigator to enable actual app navigation. Without this, Flutter apps cannot use Hotwired Native.

### Phase 2: Common Web Features (High Priority)

Implement file uploads, offline caching, and WebView configuration. These are frequently used web app features.

### Phase 3: Advanced Features (Medium Priority)

Implement geolocation, HTTP auth, and process termination handling for production robustness.

---

## Reference Implementation Mapping

| Android | iOS | Flutter |
|---------|-----|---------|
| [core/bridge](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/bridge) | [Source/Bridge](file:///Users/afstanton/code/hotwired/hotwire-native-ios/Source/Bridge) | [lib/src/bridge](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/lib/src/bridge) ✅ |
| [core/turbo/session](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/turbo/session) | [Source/Turbo/Session](file:///Users/afstanton/code/hotwired/hotwire-native-ios/Source/Turbo/Session) | [lib/src/session](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/lib/src/session) ✅ |
| [core/turbo/config](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/turbo/config) | [Source/Turbo/Path Configuration](file:///Users/afstanton/code/hotwired/hotwire-native-ios/Source/Turbo/Path%20Configuration) | [lib/src/turbo](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/lib/src/turbo) ✅ |
| Fragment Navigation | [Source/Turbo/Navigator](file:///Users/afstanton/code/hotwired/hotwire-native-ios/Source/Turbo/Navigator) | [lib/src/navigation](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/lib/src/navigation) ⚠️ |
| [core/files](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/files) | File delegates in Navigator | [platform_hooks.dart](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/lib/src/webview/platform_hooks.dart) ❌ |
| [core/turbo/offline](file:///Users/afstanton/code/hotwired/hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/turbo/offline) | Networking layer | [platform_hooks.dart](file:///Users/afstanton/code/hotwired/hotwire-native-flutter/lib/src/webview/platform_hooks.dart) ❌ |

**Legend**: ✅ Complete | ⚠️ Partial | ❌ Missing
