# Agent Instructions

This file guides coding agents working in this repo. Keep changes parity‑driven with the Android/iOS reference libraries.

## Scope

- Primary goal: Flutter library feature parity with Hotwire Native Android/iOS.
- Demo app: only implement features present in the native demo apps.
- Avoid extra features or UI polish not present in native references.

## Workflow

- Use `hotwire-native-flutter/FLUTTER_PARITY_REPORT.md` as the source of truth.
- Check off items as they are completed, and keep the report current.
- Prefer minimal, testable changes; add tests for new behavior.
- Tests are required for parity-critical logic (bridge, session, path configuration, visit models).

## Code Conventions

- Default to ASCII; avoid unnecessary comments.
- Keep public API surface small and parity‑aligned.
- Document any unavoidable platform-specific code.

## References

- Android core: `hotwire-native-android/core/src/main/kotlin/dev/hotwire/core`
- iOS core: `hotwire-native-ios/Source`
