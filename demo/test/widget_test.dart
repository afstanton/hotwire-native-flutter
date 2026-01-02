import 'dart:async';

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

  test('Demo app routes clear_all presentations', () async {
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

    final executor = _ExecutorSpy();
    final navigator = HotwireNavigator(
      navigatorKey: GlobalKey<NavigatorState>(),
      executorOverride: executor,
      navigationStack: NavigationStack(startLocation: 'https://example.com'),
    );

    navigator.routeLocation('https://example.com/clear');

    expect(executor.calls, ['clearAll:https://example.com/clear']);
  });
}

class _ExecutorSpy implements NavigationExecutor {
  final List<String> calls = [];

  @override
  void push(String location, {required bool isModal}) {}

  @override
  void replace(String location, {required bool isModal}) {}

  @override
  void pop({required bool isModal}) {}

  @override
  void clearAll(String location) {
    calls.add('clearAll:$location');
  }

  @override
  void replaceRoot(String location) {}

  @override
  void presentModal() {}

  @override
  void dismissModal() {}

  @override
  void refresh(String location, {required bool isModal}) {}
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
