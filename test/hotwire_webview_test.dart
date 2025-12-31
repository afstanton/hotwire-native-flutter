import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

class _TestAdapter implements SessionWebViewAdapter {
  @override
  Future<void> load(String url) async {}

  @override
  Future<void> reload() async {}

  @override
  Future<void> runJavaScript(String javaScript) async {}
}

void main() {
  testWidgets('HotwireWebView runs configurator hook', (
    WidgetTester tester,
  ) async {
    var called = false;
    Hotwire().config.webViewControllerConfigurator = (controller) {
      called = true;
    };

    await tester.pumpWidget(
      MaterialApp(
        home: HotwireWebView(
          url: 'https://example.com',
          session: Session(),
          webViewOverride: const SizedBox.shrink(),
          adapterOverride: _TestAdapter(),
          controllerOverride: Object(),
        ),
      ),
    );

    expect(called, isTrue);
    Hotwire().config.webViewControllerConfigurator = null;
  });
}
