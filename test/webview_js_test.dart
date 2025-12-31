import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/src/webview/bridge_js.dart';
import 'package:hotwire_native_flutter/src/webview/turbo_js.dart';

void main() {
  test('bridge_js exposes nativeBridge and message handler', () {
    expect(bridgeJs, contains('window.nativeBridge'));
    expect(bridgeJs, contains('HotwireNative'));
    expect(bridgeJs, contains('register('));
  });

  test('turbo_js emits expected Turbo message names', () {
    expect(turboJs, contains('visitProposed'));
    expect(turboJs, contains('visitRequestStarted'));
    expect(turboJs, contains('visitRequestFailed'));
    expect(turboJs, contains('formSubmissionStarted'));
    expect(turboJs, contains('pageInvalidated'));
  });
}
