import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';
import 'package:hotwire_native/main.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class _TestWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return _TestWebViewController(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return _TestNavigationDelegate(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return _TestWebViewWidget(params);
  }

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) {
    return _TestCookieManager(params);
  }
}

class _TestWebViewController extends PlatformWebViewController {
  _TestWebViewController(super.params) : super.implementation();

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setUserAgent(String? userAgent) async {}

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {}
}

class _TestNavigationDelegate extends PlatformNavigationDelegate {
  _TestNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}

  @override
  Future<void> setOnHttpAuthRequest(
    HttpAuthRequestCallback onHttpAuthRequest,
  ) async {}

  @override
  Future<void> setOnSSlAuthError(SslAuthErrorCallback onSslAuthError) async {}
}

class _TestWebViewWidget extends PlatformWebViewWidget {
  _TestWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _TestCookieManager extends PlatformWebViewCookieManager {
  _TestCookieManager(super.params) : super.implementation();

  @override
  Future<bool> clearCookies() async => false;

  @override
  Future<void> setCookie(WebViewCookie cookie) async {}
}

void main() {
  testWidgets('WebTab routes visit proposals to native handlers', (
    WidgetTester tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    WebViewPlatform.instance = _TestWebViewPlatform();

    final session = Session();
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
          onOpenNumbers: () => numbersOpened += 1,
          onOpenModalWeb: (_) => modalOpened += 1,
          onOpenImage: (_) => imageOpened += 1,
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
