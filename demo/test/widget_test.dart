import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';
import 'package:hotwire_native/main.dart';

class _TestAdapter implements SessionWebViewAdapter {
  @override
  Future<void> load(String url) async {}

  @override
  Future<void> reload() async {}

  @override
  Future<void> runJavaScript(String javaScript) async {}
}

void main() {
  testWidgets('Demo app shows bottom tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      DemoApp(
        webViewOverride: const SizedBox.shrink(),
        adapterOverride: _TestAdapter(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Navigation'), findsOneWidget);
    expect(find.text('Bridge Components'), findsOneWidget);
    expect(find.text('Resources'), findsOneWidget);
  });
}
