import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../bridge/bridge.dart';
import '../bridge/message.dart';
import '../hotwire.dart';
import '../session/route_decision.dart';
import '../session/session.dart';
import '../turbo/errors/visit_error.dart';
import 'bridge_js.dart';
import 'policy/webview_policy_decision.dart';
import 'policy/webview_policy_request.dart';
import 'turbo_js.dart';

typedef HotwireRouteRequestCallback =
    void Function(String location, Map<String, dynamic> properties);
typedef HotwireExternalNavigationCallback = void Function(String location);

class HotwireWebView extends StatefulWidget {
  final String url;
  final Session session;
  final Bridge? bridge;
  final HotwireRouteRequestCallback? onRouteRequest;
  final HotwireExternalNavigationCallback? onExternalNavigation;

  const HotwireWebView({
    required this.url,
    required this.session,
    this.bridge,
    this.onRouteRequest,
    this.onExternalNavigation,
    super.key,
  });

  @override
  State<HotwireWebView> createState() => _HotwireWebViewState();
}

class _HotwireWebViewState extends State<HotwireWebView> {
  late final WebViewController _controller;
  late final Bridge _bridge;
  late final _WebViewAdapter _adapter;
  bool _isLoading = true;
  VisitError? _error;
  void Function()? _retry;
  void Function(VisitError error, void Function() retry)? _previousErrorHandler;

  @override
  void initState() {
    super.initState();
    _bridge = widget.bridge ?? Bridge();
    _bridge.replyHandler = _sendBridgeReply;
    _bridge.activate();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        Hotwire().config.buildUserAgent(
          components: _bridge.registeredComponentNames(),
        ),
      )
      ..addJavaScriptChannel(
        'HotwireNative',
        onMessageReceived: (message) {
          _log('bridge->native ${message.message}');
          _handleBridgeMessage(message.message);
        },
      )
      ..addJavaScriptChannel(
        'TurboNative',
        onMessageReceived: (message) {
          _log('turbo->native ${message.message}');
          widget.session.updateFromJavaScriptMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
            _log('pageStarted $url');
            widget.session.delegate?.sessionDidStartPage(widget.session, url);
          },
          onPageFinished: (url) {
            _log('pageFinished $url');
            _injectScripts();
            widget.session.markInitialized();
            widget.session.recordVisitLocation(url);
            widget.session.delegate?.sessionDidFinishPage(widget.session, url);
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
    _adapter = _WebViewAdapter(controller: _controller);
    widget.session.attachWebView(_adapter);
    _previousErrorHandler = widget.session.onError;
    widget.session.onError = _handleSessionError;
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    _log(
      'navRequest url=${request.url} isMainFrame=${request.isMainFrame}',
    );
    final policyDecision = Hotwire().config.webViewPolicyManager.decide(
      WebViewPolicyRequest(
        url: request.url,
        isMainFrame: request.isMainFrame,
        navigationType: request.isMainFrame ? 'link' : null,
      ),
    );
    _log('policyDecision $policyDecision');
    if (policyDecision == WebViewPolicyDecision.external) {
      widget.onExternalNavigation?.call(request.url);
      return NavigationDecision.prevent;
    }
    if (policyDecision == WebViewPolicyDecision.cancel) {
      return NavigationDecision.prevent;
    }

    if (request.isMainFrame &&
        widget.session.isCrossOriginLocation(request.url)) {
      _log('crossOriginRedirect ${request.url}');
      widget.session.handleCrossOriginRedirect(request.url);
      return NavigationDecision.prevent;
    }

    final location = request.url;
    final properties = Hotwire().config.pathConfiguration.properties(location);
    final decision = widget.session.decideNavigation(location);
    _log('routeDecision $decision');

    switch (decision) {
      case RouteDecision.navigate:
        return NavigationDecision.navigate;
      case RouteDecision.delegate:
        widget.onRouteRequest?.call(location, properties);
        return NavigationDecision.prevent;
      case RouteDecision.external:
        widget.onExternalNavigation?.call(location);
        return NavigationDecision.prevent;
    }
  }

  Future<void> _injectScripts() async {
    try {
      await _controller.runJavaScript(bridgeJs);
      await _controller.runJavaScript(turboJs);
    } catch (error) {
      _log('injectScripts error=$error');
    }

    final componentNames = _bridge.registeredComponentNames();
    if (componentNames.isNotEmpty) {
      final jsonNames = json.encode(componentNames);
      try {
        await _controller.runJavaScript(
          "window.nativeBridge.register($jsonNames)",
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
    final reply = message.toMap();
    final jsonReply = json.encode(reply);
    try {
      await _controller.runJavaScript(
        "window.nativeBridge.replyWith($jsonReply)",
      );
    } catch (error) {
      _log('bridge reply error=$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
        if (_error != null) _buildErrorView(),
      ],
    );
  }

  @override
  void dispose() {
    widget.session.detachWebView(_adapter);
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

class _WebViewAdapter implements SessionWebViewAdapter {
  final WebViewController controller;

  _WebViewAdapter({required this.controller});

  @override
  Future<void> load(String url) {
    return controller.loadRequest(Uri.parse(url));
  }

  @override
  Future<void> reload() {
    return controller.reload();
  }

  @override
  Future<void> runJavaScript(String javaScript) {
    return controller.runJavaScript(javaScript);
  }
}
