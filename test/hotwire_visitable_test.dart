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
  int attachCalls = 0;
  int detachCalls = 0;
  int cacheCalls = 0;
  int restoreCalls = 0;

  @override
  void attachVisitable(SessionVisitable visitable) {
    attachCalls += 1;
    super.attachVisitable(visitable);
  }

  @override
  void detachVisitable(SessionVisitable visitable) {
    detachCalls += 1;
    super.detachVisitable(visitable);
  }

  @override
  Future<void> cacheSnapshot() async {
    cacheCalls += 1;
  }

  @override
  Future<void> restoreOrVisit(String location) async {
    restoreCalls += 1;
  }
}

void main() {
  testWidgets('HotwireVisitable attaches and detaches without route observer', (
    WidgetTester tester,
  ) async {
    final session = _TestSession();

    await tester.pumpWidget(
      MaterialApp(
        home: HotwireVisitable(
          url: 'https://example.com',
          session: session,
          webViewOverride: const SizedBox.shrink(),
          adapterOverride: _TestAdapter(),
        ),
      ),
    );

    expect(session.attachCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(session.detachCalls, 1);
    expect(session.cacheCalls, 1);
  });

  testWidgets('HotwireVisitable restores on pop with route observer', (
    WidgetTester tester,
  ) async {
    final session = _TestSession();
    final observer = RouteObserver<PageRoute<dynamic>>();
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [observer],
        home: HotwireVisitable(
          url: 'https://example.com',
          session: session,
          routeObserver: observer,
          webViewOverride: const SizedBox.shrink(),
          adapterOverride: _TestAdapter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();

    expect(session.detachCalls, 1);
    expect(session.cacheCalls, 1);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(session.attachCalls, 2);
    expect(session.restoreCalls, 1);
  });
}
