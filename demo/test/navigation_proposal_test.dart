import 'package:flutter/material.dart';
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
  testWidgets('WebTab routes visit proposals to native handlers', (
    WidgetTester tester,
  ) async {
    final session = Session(
      navigationStack: NavigationStack(startLocation: 'https://example.com'),
    );
    final bridge = Bridge();
    var numbersOpened = 0;
    var modalOpened = 0;
    var imageOpened = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: WebTab(
          url: 'https://example.com',
          session: session,
          bridge: bridge,
          onOpenNumbers: (_, __) => numbersOpened += 1,
          onOpenModalWeb: (_, __, ___) => modalOpened += 1,
          onOpenImage: (_) => imageOpened += 1,
          webViewOverride: const SizedBox.shrink(),
          adapterOverride: _TestAdapter(),
        ),
      ),
    );

    session.handleTurboMessage('visitProposed', {
      'location': 'https://example.com/numbers',
      'options': {'action': 'advance'},
    });
    await tester.pump();

    expect(numbersOpened, 1);

    session.handleTurboMessage('visitProposed', {
      'location': 'https://example.com/modal/new',
      'options': {'action': 'advance'},
    });
    await tester.pump();

    expect(modalOpened, 1);

    session.handleTurboMessage('visitProposed', {
      'location': 'https://example.com/assets/image.png',
      'options': {'action': 'advance'},
    });
    await tester.pump();

    expect(imageOpened, 1);
  });
}
