import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../bridge/bridge.dart';
import '../bridge/message.dart';
import '../hotwire.dart';
import '../session/route_decision.dart';
import '../session/session.dart';
import '../turbo/errors/visit_error.dart';
import 'platform_hooks.dart';
import 'file_chooser_channel.dart';
import 'bridge_js.dart';
import 'policy/webview_policy_decision.dart';
import 'policy/webview_policy_request.dart';
import 'turbo_js.dart';

typedef HotwireRouteRequestCallback =
    void Function(String location, Map<String, dynamic> properties);
typedef HotwireExternalNavigationCallback = void Function(String location);

typedef HotwireWebViewCreatedCallback = void Function(Object controller);

const String _inAppWebViewMessageShim = r'''
(() => {
  if (!window.flutter_inappwebview) {
    return
  }

  window.HotwireNative = window.HotwireNative || {}
  window.TurboNative = window.TurboNative || {}

  window.HotwireNative.postMessage = message => {
    window.flutter_inappwebview.callHandler("HotwireNative", message)
  }

  window.TurboNative.postMessage = message => {
    window.flutter_inappwebview.callHandler("TurboNative", message)
  }
})()
''';

class HotwireWebView extends StatefulWidget {
  final String url;
  final Session session;
  final Bridge? bridge;
  final HotwireRouteRequestCallback? onRouteRequest;
  final HotwireExternalNavigationCallback? onExternalNavigation;
  final HotwireWebViewCreatedCallback? onWebViewCreated;
  final Widget? webViewOverride;
  final SessionWebViewAdapter? adapterOverride;
  final Object? controllerOverride;
  final InAppWebViewKeepAlive? keepAlive;

  const HotwireWebView({
    required this.url,
    required this.session,
    this.bridge,
    this.onRouteRequest,
    this.onExternalNavigation,
    this.onWebViewCreated,
    this.webViewOverride,
    this.adapterOverride,
    this.controllerOverride,
    this.keepAlive,
    super.key,
  });

  @override
  State<HotwireWebView> createState() => _HotwireWebViewState();
}

class _HotwireWebViewState extends State<HotwireWebView> {
  late final String _initialUrl;
  InAppWebViewController? _controller;
  late final Bridge _bridge;
  SessionWebViewAdapter? _adapter;
  bool _isLoading = true;
  VisitError? _error;
  void Function()? _retry;
  void Function(VisitError error, void Function() retry)? _previousErrorHandler;
  String? _resolvedUserAgent;
  bool _debuggingConfigured = false;

  @override
  void initState() {
    super.initState();
    FileChooserChannel.ensureInitialized();
    _initialUrl = widget.url;
    _bridge = widget.bridge ?? Bridge();
    _bridge.replyHandler = _sendBridgeReply;
    _bridge.activate();

    if (widget.webViewOverride != null) {
      _isLoading = false;
    }

    if (widget.adapterOverride != null) {
      _adapter = widget.adapterOverride;
      widget.session.attachWebView(_adapter!);
    }

    if (widget.controllerOverride != null) {
      _configureController(widget.controllerOverride!);
    }

    _previousErrorHandler = widget.session.onError;
    widget.session.onError = _handleSessionError;
  }

  void _configureController(Object controller) {
    Hotwire().config.webViewControllerConfigurator?.call(controller);
    widget.onWebViewCreated?.call(controller);
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    _controller = controller;
    _configureController(controller);
    _configureUserAgent(controller);
    _configureDebugging(controller);

    controller.addJavaScriptHandler(
      handlerName: 'HotwireNative',
      callback: (args) {
        final payload = args.isNotEmpty ? args.first : null;
        if (payload is String) {
          _log('bridge->native $payload');
          _handleBridgeMessage(payload);
        }
        return null;
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'TurboNative',
      callback: (args) {
        final payload = args.isNotEmpty ? args.first : null;
        if (payload is String) {
          _log('turbo->native $payload');
          widget.session.updateFromJavaScriptMessage(payload);
        }
        return null;
      },
    );

    if (_adapter == null) {
      _adapter = _InAppWebViewAdapter(controller: controller);
      widget.session.attachWebView(_adapter!);
    }
  }

  void _configureDebugging(InAppWebViewController controller) {
    final enabled = Hotwire().config.webViewDebuggingEnabled;
    if (_debuggingConfigured || enabled == null) {
      return;
    }
    _debuggingConfigured = true;
    InAppWebViewController.setWebContentsDebuggingEnabled(enabled);
  }

  Future<void> _configureUserAgent(InAppWebViewController controller) async {
    var baseUserAgent = Hotwire().config.webViewDefaultUserAgent;
    if (baseUserAgent == null) {
      try {
        baseUserAgent = await InAppWebViewController.getDefaultUserAgent();
        Hotwire().config.webViewDefaultUserAgent ??= baseUserAgent;
      } catch (_) {
        baseUserAgent = null;
      }
    }
    final userAgent = _buildUserAgent(base: baseUserAgent);
    if (userAgent == _resolvedUserAgent) {
      return;
    }
    _resolvedUserAgent = userAgent;
    await controller.setSettings(
      settings: InAppWebViewSettings(userAgent: userAgent),
    );
  }

  String _buildUserAgent({String? base}) {
    final hotwireAgent = Hotwire().config.buildUserAgent(
      components: _bridge.registeredComponentNames(),
    );
    if (base == null || base.isEmpty) {
      return hotwireAgent;
    }
    return '$base $hotwireAgent';
  }

  Future<NavigationActionPolicy> _handleNavigation(
    NavigationAction action,
  ) async {
    final url = action.request.url?.toString();
    if (url == null) {
      return NavigationActionPolicy.ALLOW;
    }
    final isMainFrame = action.isForMainFrame == false ? false : true;
    _log('navRequest url=$url isMainFrame=$isMainFrame');
    final policyDecision = Hotwire().config.webViewPolicyManager.decide(
      WebViewPolicyRequest(
        url: url,
        isMainFrame: isMainFrame,
        navigationType: _navigationType(action.navigationType),
      ),
    );
    _log('policyDecision $policyDecision');

    if (policyDecision == WebViewPolicyDecision.external) {
      widget.onExternalNavigation?.call(url);
      return NavigationActionPolicy.CANCEL;
    }

    if (policyDecision == WebViewPolicyDecision.cancel) {
      if (_navigationType(action.navigationType) == 'reload') {
        _log('reloadRequest');
        widget.session.reload();
      }
      return NavigationActionPolicy.CANCEL;
    }

    if (!widget.session.isInitialized && isMainFrame && url != _initialUrl) {
      final optionsJson = json.encode({'action': 'replace'});
      widget.session.proposeVisitFromJson(url, optionsJson);
      return NavigationActionPolicy.CANCEL;
    }

    if (isMainFrame && widget.session.isCrossOriginLocation(url)) {
      _log('crossOriginRedirect $url');
      widget.session.handleCrossOriginRedirect(url);
      return NavigationActionPolicy.CANCEL;
    }

    final properties = Hotwire().config.pathConfiguration.properties(url);
    final decision = widget.session.decideNavigation(url);
    _log('routeDecision $decision');

    switch (decision) {
      case RouteDecision.navigate:
        return NavigationActionPolicy.ALLOW;
      case RouteDecision.delegate:
        widget.onRouteRequest?.call(url, properties);
        return NavigationActionPolicy.CANCEL;
      case RouteDecision.external:
        widget.onExternalNavigation?.call(url);
        return NavigationActionPolicy.CANCEL;
    }
  }

  Future<bool> _handleCreateWindow(CreateWindowAction action) async {
    final url = action.request.url?.toString();
    if (url == null) {
      return false;
    }
    final policyDecision = Hotwire().config.webViewPolicyManager.decide(
      WebViewPolicyRequest(url: url, isMainFrame: false, isNewWindow: true),
    );

    if (policyDecision == WebViewPolicyDecision.external) {
      widget.onExternalNavigation?.call(url);
      return false;
    }

    if (policyDecision == WebViewPolicyDecision.allow) {
      final optionsJson = json.encode({'action': 'advance'});
      widget.session.proposeVisitFromJson(url, optionsJson);
    }

    return false;
  }

  String? _navigationType(NavigationType? type) {
    if (type == NavigationType.LINK_ACTIVATED) {
      return 'link';
    }
    if (type == NavigationType.FORM_SUBMITTED) {
      return 'form';
    }
    if (type == NavigationType.BACK_FORWARD) {
      return 'backForward';
    }
    if (type == NavigationType.RELOAD) {
      return 'reload';
    }
    if (type == NavigationType.FORM_RESUBMITTED) {
      return 'formResubmitted';
    }
    return null;
  }

  Future<HttpAuthResponse?> _handleHttpAuth(
    URLAuthenticationChallenge challenge,
  ) async {
    final handler = Hotwire().config.onHttpAuthChallenge;
    if (handler == null) {
      return null;
    }
    final host = challenge.protectionSpace.host ?? '';
    final realm = challenge.protectionSpace.realm ?? '';
    final response = await handler(
      WebViewHttpAuthChallenge(host: host, realm: realm),
    );
    if (response == null) {
      return null;
    }
    switch (response.action) {
      case WebViewHttpAuthAction.useCredential:
        return HttpAuthResponse(
          action: HttpAuthResponseAction.PROCEED,
          username: response.username ?? '',
          password: response.password ?? '',
        );
      case WebViewHttpAuthAction.performDefaultHandling:
        return HttpAuthResponse(
          action: HttpAuthResponseAction.USE_SAVED_HTTP_AUTH_CREDENTIALS,
        );
      case WebViewHttpAuthAction.cancel:
        return HttpAuthResponse(action: HttpAuthResponseAction.CANCEL);
    }
  }

  Future<GeolocationPermissionShowPromptResponse?>
  _handleGeolocationPermission(String origin) async {
    final handler = Hotwire().config.onGeolocationPermissionRequest;
    if (handler == null) {
      return null;
    }
    final response = await handler(
      WebViewGeolocationPermissionRequest(origin: origin),
    );
    if (response == null) {
      return null;
    }
    return GeolocationPermissionShowPromptResponse(
      allow: response.allow,
      origin: origin,
      retain: response.retain,
    );
  }

  Future<WebResourceResponse?> _handleOfflineRequest(
    WebResourceRequest request,
  ) async {
    final handler = Hotwire().config.offlineRequestHandler;
    if (handler == null) {
      return null;
    }
    final url = request.url.toString();
    final response = await handler(
      OfflineRequest(
        url: url,
        method: request.method ?? 'GET',
        headers: Map<String, String>.from(request.headers ?? const {}),
      ),
    );
    if (response == null) {
      return null;
    }
    final status = response.statusCode;
    final reasonPhrase = status >= 200 && status < 300 ? 'OK' : 'ERROR';
    return WebResourceResponse(
      statusCode: status,
      reasonPhrase: reasonPhrase,
      headers: response.headers,
      data: response.body.isEmpty ? null : Uint8List.fromList(response.body),
    );
  }

  void _handleProcessTermination({bool didCrash = false}) {
    final handler = Hotwire().config.onWebViewProcessTerminated;
    if (handler == null) {
      return;
    }
    handler(
      WebViewProcessTermination(
        reason: didCrash
            ? WebViewProcessTerminationReason.crashed
            : WebViewProcessTerminationReason.killed,
      ),
    );
  }

  Future<void> _injectScripts() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    try {
      await controller.evaluateJavascript(source: _inAppWebViewMessageShim);
      await controller.evaluateJavascript(source: bridgeJs);
      await controller.evaluateJavascript(source: turboJs);
    } catch (error) {
      _log('injectScripts error=$error');
    }

    final componentNames = _bridge.registeredComponentNames();
    if (componentNames.isNotEmpty) {
      final jsonNames = json.encode(componentNames);
      try {
        await controller.evaluateJavascript(
          source: "window.nativeBridge.register($jsonNames)",
        );
      } catch (error) {
        _log('registerComponents error=$error');
      }
    }
  }

  void _handleBridgeMessage(String payload) {
    if (payload == 'ready') {
      _log('bridge ready');
      return;
    }
    try {
      final decoded = json.decode(payload);
      if (decoded is Map<String, dynamic>) {
        _bridge.handleMessage(decoded);
      }
    } catch (_) {
      _log('bridge message decode failed');
    }
  }

  Future<void> _sendBridgeReply(BridgeMessage message) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final reply = message.toMap();
    final jsonReply = json.encode(reply);
    try {
      await controller.evaluateJavascript(
        source: "window.nativeBridge.replyWith($jsonReply)",
      );
    } catch (error) {
      _log('bridge reply error=$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAgent = _resolvedUserAgent ?? _buildUserAgent();

    final webView =
        widget.webViewOverride ??
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            javaScriptCanOpenWindowsAutomatically: true,
            useShouldOverrideUrlLoading: true,
            userAgent: userAgent,
          ),
          keepAlive: widget.keepAlive,
          onWebViewCreated: _onWebViewCreated,
          onLoadStart: (controller, url) {
            final location = url?.toString();
            if (mounted) setState(() => _isLoading = true);
            if (location != null) {
              _log('pageStarted $location');
              widget.session.delegate?.sessionDidStartPage(
                widget.session,
                location,
              );
            }
          },
          onLoadStop: (controller, url) async {
            final location = url?.toString();
            if (location != null) {
              _log('pageFinished $location');
              await _injectScripts();
              widget.session.markInitialized();
              widget.session.recordVisitLocation(location);
              widget.session.delegate?.sessionDidFinishPage(
                widget.session,
                location,
              );
            }
            if (mounted) setState(() => _isLoading = false);
          },
          shouldOverrideUrlLoading: (controller, action) async {
            return _handleNavigation(action);
          },
          onCreateWindow: (controller, action) async {
            return _handleCreateWindow(action);
          },
          onReceivedHttpAuthRequest: (controller, challenge) async {
            return _handleHttpAuth(challenge);
          },
          onGeolocationPermissionsShowPrompt: (controller, origin) async {
            return _handleGeolocationPermission(origin);
          },
          shouldInterceptRequest: (controller, request) async {
            return _handleOfflineRequest(request);
          },
          onWebContentProcessDidTerminate: (controller) {
            _handleProcessTermination();
          },
          onRenderProcessGone: (controller, detail) {
            _handleProcessTermination(didCrash: detail.didCrash);
          },
        );

    return Stack(
      children: [
        webView,
        if (_isLoading) const Center(child: CircularProgressIndicator()),
        if (_error != null) _buildErrorView(),
      ],
    );
  }

  @override
  void dispose() {
    if (_adapter != null) {
      widget.session.detachWebView(_adapter!);
    }
    if (widget.session.onError == _handleSessionError) {
      widget.session.onError = _previousErrorHandler;
    }
    _bridge.deactivate();
    super.dispose();
  }

  void _handleSessionError(VisitError error, void Function() retry) {
    _previousErrorHandler?.call(error, retry);
    if (mounted) {
      _log('session error ${error.description}');
      setState(() {
        _error = error;
        _retry = retry;
        _isLoading = false;
      });
    }
  }

  void _log(String message) {
    if (Hotwire().config.debugLoggingEnabled) {
      debugPrint('[HotwireWebView] $message');
    }
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              "Page Load Failed",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _error?.description ?? '',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final retry = _retry;
                if (mounted) {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                }
                retry?.call();
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

class _InAppWebViewAdapter implements SessionWebViewAdapter {
  final InAppWebViewController controller;

  _InAppWebViewAdapter({required this.controller});

  @override
  Future<void> load(String url) {
    return controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  @override
  Future<void> reload() {
    return controller.reload();
  }

  @override
  Future<void> runJavaScript(String javaScript) {
    return controller.evaluateJavascript(source: javaScript);
  }
}
