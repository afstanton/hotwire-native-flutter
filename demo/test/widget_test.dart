import 'dart:async';

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
  tearDown(() {
    Hotwire().config.pathConfiguration.sources = const [];
  });

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

  testWidgets('Demo app clears navigation stack on clear_all', (
    WidgetTester tester,
  ) async {
    await _configurePathRules(r'''
      {
        "rules": [
          {
            "patterns": ["/clear"],
            "properties": {"presentation": "clear_all"}
          }
        ]
      }
    ''');

    final navigatorKey = GlobalKey<NavigatorState>();
    final session = Session(
      navigationStack: NavigationStack(startLocation: 'https://example.com'),
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: WebTab(
          url: 'https://example.com',
          session: session,
          onOpenNumbers: (_, __) {},
          onOpenModalWeb: (_, __, ___) {},
          onOpenImage: (_) {},
          webViewOverride: const SizedBox.shrink(),
          adapterOverride: _TestAdapter(),
        ),
      ),
    );
    await tester.pump();

    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const SizedBox()),
    );
    await tester.pumpAndSettle();
    expect(navigatorKey.currentState!.canPop(), isTrue);

    session.handleTurboMessage('visitProposed', {
      'location': 'https://example.com/clear',
      'options': {'action': 'advance'},
    });
    await tester.pumpAndSettle();

    expect(navigatorKey.currentState!.canPop(), isFalse);
  });
}

Future<void> _configurePathRules(String json) async {
  final config = Hotwire().config.pathConfiguration;
  final completer = Completer<void>();
  late final StreamSubscription sub;
  sub = config.onUpdated.listen((_) {
    sub.cancel();
    completer.complete();
  });
  config.sources = [PathConfigurationSource.data(json)];
  return completer.future;
}
