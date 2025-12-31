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
- [ ] WebView default user agent integration (platform channel needed)
- [ ] WebView debugging toggle (platform channel needed)
- [x] Custom webview factory / per-session webview configuration hook
- [x] Custom JSON encoder/decoder integration parity (naming strategies, errors surfaced)

### Path configuration

- [x] Load configuration from data source
- [x] Load configuration from asset file
- [x] Load configuration from remote server with caching
- [x] Default server route rules (historical location routes)
- [x] Path rule matching with regex patterns
- [x] Settings map parsing
- [x] Query string matching toggle
- [x] Path configuration loader options (custom headers, URLSession config parity)
- [x] Path configuration file format validation errors surfaced
- [x] Historical location behavior: recede/resume/refresh applied to navigation stack
  - Helper action provided for apps to apply (dismiss modal + presentation)

### Path properties helpers

- [x] `presentation` parsing (default, clear_all, replace_root, replace, pop, none, refresh)
- [x] `context` parsing (default, modal)
- [x] `query_string_presentation` parsing
- [x] `uri`, `fallback_uri`, `title`, `pull_to_refresh_enabled`, `animated`, `historical_location`
- [x] Additional typed helpers used by native libs (modal style, dismiss gesture, view controller)
- [x] Tabs property parsing (custom tab overrides from path config)

### Turbo visit models

- [x] VisitAction (advance, replace, restore)
- [x] VisitOptions (action, snapshotHTML, response)
- [x] VisitResponse (statusCode, redirected, responseHTML)
- [x] VisitProposal (url, options, properties, parameters)
- [x] Visit state modeling (started, rendered, completed, failed)

### Bridge

- [x] BridgeMessage model + metadata + replacement
- [x] BridgeComponent + factory registration
- [x] Bridge dispatcher for components/factories
- [x] JSON encode/decode hooks
- [x] WebView bridge injection (Turbo/Bridge JS)
- [x] Bridge replies over webview
- [ ] User agent includes registered components + platform default UA (platform channel needed)
- [x] Bridge message format parity: {id, component, event, data, metadata.url}
- [x] Bridge lifecycle: connect/disconnect events for components

### Session core

- [x] Turbo event tracking (visit lifecycle + form submissions)
- [x] Visit proposal handling from Turbo events
- [x] Route decision handler (navigate/delegate/external)
- [x] Query string presentation restore logic
- [x] WebView-backed session (cold boot vs JS visits)
- [x] Snapshot cache / restore integration (basic hooks)
- [x] Page invalidation + reload behavior
- [x] Non-HTTP error redirect handling (delegate hook)
- [ ] Session delegate parity (complete list vs iOS/Android; remaining items are platform channel)
  - [x] Cross-origin redirect proposal callback
  - [ ] WebView process termination callback (platform channel needed)
  - [ ] HTTP auth challenge handling (platform channel needed)
- [x] Form submission lifecycle: start/finish hooks toggle progress UI
- [x] Page load failed / errorRaised propagation
- [x] Restoration identifiers tracked per visitable
- [x] Session reset + cold boot behavior

### WebView policy / routing

- [x] External navigation policy (non-http schemes)
- [ ] New window policy (platform channel or plugin support needed; handler exists)
- [ ] Reload policy (platform channel needed)
- [x] Link activated policy (basic)
- [x] App navigation policy handler chain (basic manager)
- [x] Modal presentation rules from path config (context + presentation)

### Errors

- [x] Web error types (Turbo-style network/timeout/content-type/http/page-load)
- [x] SSL error type mapping (model only; no WebView hook yet)
- [x] Standard error view / handler hooks (basic)
- [x] Error retry handler hook (basic)

### Offline caching

- [ ] Offline request handler + pre-cache API (platform channel needed)
- [ ] Offline cache strategy (platform channel needed)
- [ ] Offline request interception (platform channel needed)
- [ ] Offline cache persistence policy (eviction, cache key) (platform channel needed)

### File chooser / geolocation

- [ ] File chooser delegate (platform channel needed)
- [ ] Camera capture delegate (platform channel needed)
- [ ] Geolocation permission delegate (platform channel needed)
- [ ] MIME type filters and multiple file selection (platform channel needed)

## Demo App Parity Checklist

- [x] Bottom tabs: Navigation, Bridge Components, Resources
- [x] Optional Bugs & Fixes tab when using local environment
- [x] Native Numbers screen (1–100)
- [x] Modal web for `/new`, `/edit`, `/modal`, `/numbers/:id`
- [x] Native image viewer for image paths
- [x] Demo bridge components (menu, form, overflow menu) wired to web
- [x] Demo toolbar progress indicator for form submission

## Current State (Flutter)

- Core config + path configuration + rule matching implemented and tested.
- Bridge primitives (message, component, factory, dispatcher) implemented and tested.
- Bridge component lifecycle + reply helpers implemented and tested.
- Turbo visit models implemented and tested.
- Minimal session logic implemented and tested.
- Visit state modeling implemented and tested.
- Platform hook placeholders added for auth/process/file/geolocation/offline events.
- Minimal WebView widget using `webview_flutter` added to enable in-app navigation.
- Turbo/Bridge JS injected into WebView and wired to Session/Bridge message flow.
- Session now supports `visitWithOptions`, `restoreOrVisit`, snapshot cache hooks via a WebView adapter (no full lifecycle yet).
- Demo app updated to match native demo layout and routing.

## Next Steps (No platform-specific code yet)

1) Session delegate parity (non-platform hooks)
   - Determine cross-origin redirect proposal behavior in Flutter.
   - Document platform-channel-dependent delegate hooks (auth challenge, render process termination).

2) Path configuration parity polish
   - Support tabs property parsing if used by native demos.

3) Demo app parity
   - Wire demo bridge components (menu, form, overflow menu).
   - Add toolbar progress indicator for form submission if used by native demos.

## Platform Channel Backlog

- WebView default user agent integration
- WebView debugging toggle
- New window policy support
- Reload policy
- WebView process termination callback
- HTTP auth challenge handling
- Offline cache + request interception
- File chooser delegate
- Camera capture delegate
- Geolocation permission delegate

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
