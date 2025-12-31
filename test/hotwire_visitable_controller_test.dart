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

class _TestSession extends Session {
  int reloadCalls = 0;
  int clearCalls = 0;

  @override
  Future<void> reload() async {
    reloadCalls += 1;
  }

  @override
  Future<void> clearSnapshotCache() async {
    clearCalls += 1;
  }
}

void main() {
  testWidgets('HotwireVisitableController forwards reload and refresh', (
    WidgetTester tester,
  ) async {
    final session = _TestSession();
    final controller = HotwireVisitableController();

    await tester.pumpWidget(
      MaterialApp(
        home: HotwireVisitable(
          url: 'https://example.com',
          session: session,
          controller: controller,
          webViewOverride: const SizedBox.shrink(),
          adapterOverride: _TestAdapter(),
        ),
      ),
    );

    await controller.reload();
    expect(session.reloadCalls, 1);

    await controller.refresh();
    expect(session.clearCalls, 1);
    expect(session.reloadCalls, 2);
  });
}
