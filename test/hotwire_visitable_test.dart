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

class _TestDestination extends BridgeDestination {}

class _TestBridgeDelegate extends BridgeDelegate {
  int webViewAttachedCalls = 0;
  int webViewDetachedCalls = 0;
  int viewDidLoadCalls = 0;
  int viewWillAppearCalls = 0;
  int viewDidAppearCalls = 0;
  int viewWillDisappearCalls = 0;
  int viewDidDisappearCalls = 0;

  _TestBridgeDelegate()
    : super(
        location: 'https://example.com',
        destination: _TestDestination(),
        componentFactories: const <BridgeComponentFactory>[],
      );

  @override
  void onWebViewAttached(Bridge bridge) {
    webViewAttachedCalls += 1;
    super.onWebViewAttached(bridge);
  }

  @override
  void onWebViewDetached() {
    webViewDetachedCalls += 1;
    super.onWebViewDetached();
  }

  @override
  void onViewDidLoad() {
    viewDidLoadCalls += 1;
    super.onViewDidLoad();
  }

  @override
  void onViewWillAppear() {
    viewWillAppearCalls += 1;
    super.onViewWillAppear();
  }

  @override
  void onViewDidAppear() {
    viewDidAppearCalls += 1;
    super.onViewDidAppear();
  }

  @override
  void onViewWillDisappear() {
    viewWillDisappearCalls += 1;
    super.onViewWillDisappear();
  }

  @override
  void onViewDidDisappear() {
    viewDidDisappearCalls += 1;
    super.onViewDidDisappear();
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

  testWidgets('HotwireVisitable forwards bridge lifecycle callbacks', (
    WidgetTester tester,
  ) async {
    final session = _TestSession();
    final observer = RouteObserver<PageRoute<dynamic>>();
    final navigatorKey = GlobalKey<NavigatorState>();
    final delegate = _TestBridgeDelegate();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [observer],
        home: HotwireVisitable(
          url: 'https://example.com',
          session: session,
          routeObserver: observer,
          bridgeDelegate: delegate,
          webViewOverride: const SizedBox.shrink(),
          adapterOverride: _TestAdapter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(delegate.webViewAttachedCalls, 1);
    expect(delegate.viewDidLoadCalls, 1);
    expect(delegate.viewWillAppearCalls, 1);
    expect(delegate.viewDidAppearCalls, 1);

    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();

    expect(delegate.viewWillDisappearCalls, 1);
    expect(delegate.viewDidDisappearCalls, 1);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(delegate.viewWillAppearCalls, 2);
    expect(delegate.viewDidAppearCalls, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(delegate.webViewDetachedCalls, 1);
  });
}
