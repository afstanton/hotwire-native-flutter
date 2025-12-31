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
- [x] Non-HTTP redirect verification (native fetch + cross-origin proposal parity)
- [ ] Session delegate parity (complete list vs iOS/Android; remaining items are platform channel)
  - [x] Cross-origin redirect proposal callback
  - [ ] WebView process termination callback (platform channel needed)
  - [ ] HTTP auth challenge handling (platform channel needed)
- [x] Form submission lifecycle: start/finish hooks toggle progress UI
- [x] Page load failed / errorRaised propagation
- [x] Restoration identifiers tracked per visitable
- [x] Session reset + cold boot behavior
- [x] Turbo readiness handshake (turboIsReady/turboFailedToLoad) + pending visit queue

### Navigation stack / visitable lifecycle

- [x] HotwireVisitable widget (route-aware attach/detach + restore/caching hooks)
- [x] Visitable abstraction activated/deactivated with shared WebView (iOS `Visitable`)
- [x] WebView keep-alive support for sharing a session WebView
- [x] Track topmost/active/previous visitable to restore on back navigation
- [x] Restore visit on back to web view (restore action vs advance)
- [x] Snapshot cache per visitable and restore integration with navigation stack
- [x] Main vs modal session handling (shared modal session for modal stack)
- [x] Refresh/reload requests from visitable surface to Session
- [ ] Navigation stack routing parity (main vs modal session handling)

### WebView policy / routing

- [x] External navigation policy (non-http schemes)
- [x] New window policy (handled via in-app webview create window callbacks)
- [ ] Reload policy (platform channel needed)
- [x] Link activated policy (basic)
- [x] App navigation policy handler chain (basic manager)
- [x] Modal presentation rules from path config (context + presentation)
- [x] Propose visits when Turbo does not (target=_blank, cold-boot redirects)
  - [x] target=_blank / new-window proposals routed to Session
  - [x] cold-boot redirect proposals

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
- Minimal WebView widget using `flutter_inappwebview` added to enable in-app navigation.
- Turbo/Bridge JS injected into WebView and wired to Session/Bridge message flow.
- Session now supports `visitWithOptions`, `restoreOrVisit`, snapshot cache hooks via a WebView adapter (no full lifecycle yet).
- Demo app updated to match native demo layout and routing.
- Navigation stack helper added for main/modal decisioning (not yet wired into app navigation).
- Demo app uses NavigationStack instructions for modal vs main routing decisions.

## Reference Test Coverage vs Flutter

### Reference tests (Android/iOS) cover

- Bridge: message encoding/decoding, internal message mapping, component lifecycle, delegate routing, async APIs, JavaScript evaluation hooks, user agent composition.
- Turbo session: cold boot visit lifecycle, delegate callbacks, Turbo error mapping (HTTP/page load), JS bridge wiring.
- Path configuration: loader, parsing, modal styles, historical locations, repository caching behavior.
- Routing/policy: route decision handlers (app/system/safari/browser), webview policy handlers (external, new window, reload, link activated).
- Navigation stack: navigation hierarchy controller / navigator host + routing rules.
- Errors: HTTP/web/SSL error models.
- File handling: file chooser, camera capture, URI helper, file provider.
- Visit response parsing/flags.

### Flutter tests currently cover

- Bridge message encoding/decoding, component lifecycle, dispatcher and factories.
- User agent string composition for Hotwire components.
- Turbo JS/bridge JS injection shims.
- WebView policy handlers (external, new window, link activated) and policy manager basics.
- Session lifecycle (visit proposals, redirects, errors, Turbo readiness, snapshot cache, restoration identifiers).
- Path configuration parsing, rules, loader errors, tabs/modal parsing, historical locations.
- Visit models (actions, options, response).
- SSL error mapping model.
- Visitable lifecycle + controller helpers.

### Test gaps to close (parity)

- [ ] Route decision handlers parity (app/system/browser/safari-style routing decisions).
- [x] Route decision handlers parity (app/system/browser/safari-style routing decisions).
- [ ] Navigation stack behavior parity (navigation hierarchy / navigator host rules).
- [ ] WebView policy reload handler parity.
- [x] WebView policy reload handler parity.
- [x] Turbo error mapping parity (HTTP error vs page load vs web error types).
- [x] Visit response error handling parity (non-2xx, redirect behaviors).
- [x] Path configuration repository caching behavior (remote caching + invalidation).
- [ ] Bridge async API parity (timing/queueing behavior).
- [x] Bridge async API parity (timing/queueing behavior).
- [ ] File chooser / camera / URI helper behaviors (platform channel when available).
- [ ] Geolocation permission handling (platform channel when available).

## Next Steps (No platform-specific code yet)

1) Turbo readiness handshake + pending visit queue
   - Track Turbo ready/failed state from JS.
   - Queue visits during cold boot and replay once ready.

2) Visitable lifecycle foundation
   - Introduce Visitable abstraction + activation/deactivation hooks tied to navigation.
   - Attach/detach visitables to Session.

3) Restore & snapshot integration
   - Restore on back navigation (restore vs advance).
   - Cache snapshots per visitable; restore identifiers on reattach.

4) Navigation stack parity
   - Track topmost/active/previous visitables.
   - Main vs modal stack handling (dismiss modal on proposal when needed).

5) Turbo visit proposal fallback
   - Propose visits when Turbo doesn’t (target=_blank, cold-boot redirects).

6) Non-HTTP redirect verification
   - Native fetch to confirm cross-origin redirect before proposing.
   - (May need platform channel or HTTP client policy.)

## Platform Channel Backlog

- WebView default user agent integration
- WebView debugging toggle
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
