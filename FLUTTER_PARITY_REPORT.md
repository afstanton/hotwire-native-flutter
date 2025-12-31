# Hotwire Native Flutter Parity Report

This document tracks feature parity between the Flutter library and the Android/iOS reference implementations. It lists the functionality provided by the native libraries, what is currently implemented in Flutter, and what remains.

## Scope

- Flutter library parity with Hotwire Native Android/iOS.
- Demo app parity only for features present in Android/iOS demo apps.
- Avoid extra features not present in native references.

## Reference Feature Checklist

### Core configuration

- [x] Global configuration entrypoint (Hotwire config)
- [x] Custom user agent prefix + component list
- [x] Debug logging flag (config flag only)
- [ ] WebView default user agent integration
- [ ] WebView debugging toggle
- [ ] Custom webview factory / per-session webview configuration hook
- [ ] Custom JSON encoder/decoder integration parity (naming strategies, errors surfaced)

### Path configuration

- [x] Load configuration from data source
- [x] Load configuration from asset file
- [x] Load configuration from remote server with caching
- [x] Default server route rules (historical location routes)
- [x] Path rule matching with regex patterns
- [x] Settings map parsing
- [x] Query string matching toggle
- [ ] Path configuration loader options (custom headers, URLSession config parity)
- [ ] Path configuration file format validation errors surfaced
- [ ] Historical location behavior: recede/resume/refresh applied to navigation stack

### Path properties helpers

- [x] `presentation` parsing (default, clear_all, replace_root, replace, pop, none, refresh)
- [x] `context` parsing (default, modal)
- [x] `query_string_presentation` parsing
- [x] `uri`, `fallback_uri`, `title`, `pull_to_refresh_enabled`, `animated`, `historical_location`
- [ ] Additional typed helpers used by native libs (if any emerge)
- [ ] Tabs property parsing (custom tab overrides from path config)

### Turbo visit models

- [x] VisitAction (advance, replace, restore)
- [x] VisitOptions (action, snapshotHTML, response)
- [x] VisitResponse (statusCode, redirected, responseHTML)
- [x] VisitProposal (url, options, properties, parameters)
- [ ] Visit state modeling (started, rendered, completed, failed)

### Bridge

- [x] BridgeMessage model + metadata + replacement
- [x] BridgeComponent + factory registration
- [x] Bridge dispatcher for components/factories
- [x] JSON encode/decode hooks
- [x] WebView bridge injection (Turbo/Bridge JS)
- [x] Bridge replies over webview
- [ ] User agent includes registered components + platform default UA
- [ ] Bridge message format parity: {id, component, event, data, metadata.url}
- [ ] Bridge lifecycle: connect/disconnect events for components

### Session core

- [x] Turbo event tracking (visit lifecycle + form submissions)
- [x] Visit proposal handling from Turbo events
- [x] Route decision handler (navigate/delegate/external)
- [x] Query string presentation restore logic
- [x] WebView-backed session (cold boot vs JS visits)
- [x] Snapshot cache / restore integration (basic hooks)
- [x] Page invalidation + reload behavior
- [ ] Non-HTTP error redirect handling (cross-origin redirect checks)
- [ ] Session delegate parity (complete list vs iOS/Android)
- [ ] Form submission lifecycle: start/finish hooks toggle progress UI
- [ ] Page load failed / errorRaised propagation
- [ ] Restoration identifiers tracked per visitable
- [x] Session reset + cold boot behavior

### WebView policy / routing

- [ ] External navigation policy (system browser / url launcher)
- [ ] New window policy
- [ ] Reload policy
- [ ] Link activated policy
- [ ] App navigation policy handler chain
- [ ] Modal presentation rules from path config (context + presentation)

### Errors

- [ ] Web error types (HTTP / SSL / network)
- [ ] Standard error view / handler hooks
- [ ] Error retry handler hook

### Offline caching

- [ ] Offline request handler + pre-cache API
- [ ] Offline cache strategy
- [ ] Offline request interception
- [ ] Offline cache persistence policy (eviction, cache key)

### File chooser / geolocation

- [ ] File chooser delegate
- [ ] Camera capture delegate
- [ ] Geolocation permission delegate
- [ ] MIME type filters and multiple file selection

## Demo App Parity Checklist

- [x] Bottom tabs: Navigation, Bridge Components, Resources
- [x] Optional Bugs & Fixes tab when using local environment
- [x] Native Numbers screen (1–100)
- [x] Modal web for `/new`, `/edit`, `/modal`, `/numbers/:id`
- [x] Native image viewer for image paths
- [ ] Demo bridge components (menu, form, overflow menu) wired to web
- [ ] Demo toolbar progress indicator for form submission

## Current State (Flutter)

- Core config + path configuration + rule matching implemented and tested.
- Bridge primitives (message, component, factory, dispatcher) implemented and tested.
- Turbo visit models implemented and tested.
- Minimal session logic implemented and tested.
- Minimal WebView widget using `webview_flutter` added to enable in-app navigation.
- Turbo/Bridge JS injected into WebView and wired to Session/Bridge message flow.
- Session now supports `visitWithOptions`, `restoreOrVisit`, snapshot cache hooks via a WebView adapter (no full lifecycle yet).
- Demo app updated to match native demo layout and routing.

## Next Steps (No platform-specific code yet)

1) WebView bridge injection + message handling
   - Inject Turbo/Bridge JS into webview.
   - Wire JS -> Session event flow and Bridge message dispatch.
   - Enable reply path from native -> JS.

2) WebView-backed session lifecycle
   - Cold boot vs JS visit logic.
   - Snapshot cache + restore hooks.
   - Page invalidation handling.

3) Routing + policy handling
   - External navigation hook.
   - New window + reload + link activated policies.
   - Route decision chain matching iOS/Android behavior.

4) Remaining parity features
   - Offline cache strategy + pre-cache API.
   - File chooser + geolocation.
   - Error types and presentation hooks.

## Reference Mapping (Key Files)

- Android core: `hotwire-native-android/core/src/main/kotlin/dev/hotwire/core`
- iOS core: `hotwire-native-ios/Source`
- Android session: `hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/turbo/session/Session.kt`
- iOS session: `hotwire-native-ios/Source/Turbo/Session/Session.swift`
- Android path config: `hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/turbo/config`
- iOS path config: `hotwire-native-ios/Source/Turbo/Path Configuration`
- Bridge (Android): `hotwire-native-android/core/src/main/kotlin/dev/hotwire/core/bridge`
- Bridge (iOS): `hotwire-native-ios/Source/Bridge`

## Notes

- This list is parity‑driven: only features present in Android/iOS reference libraries are targeted.
- Demo app intentionally mirrors native demos; avoid extra features.
