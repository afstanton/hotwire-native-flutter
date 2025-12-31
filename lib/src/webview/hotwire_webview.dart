import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../bridge/bridge.dart';
import '../bridge/message.dart';
import '../hotwire.dart';
import '../session/route_decision.dart';
import '../session/session.dart';
import 'bridge_js.dart';
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

  @override
  void initState() {
    super.initState();
    _bridge = widget.bridge ?? Bridge();
    _bridge.replyHandler = _sendBridgeReply;
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
          _handleBridgeMessage(message.message);
        },
      )
      ..addJavaScriptChannel(
        'TurboNative',
        onMessageReceived: (message) {
          widget.session.updateFromJavaScriptMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            _injectScripts();
            widget.session.markInitialized();
            widget.session.recordVisitLocation(url);
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
    _adapter = _WebViewAdapter(controller: _controller);
    widget.session.attachWebView(_adapter);
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final location = request.url;
    final properties = Hotwire().config.pathConfiguration.properties(location);
    final decision = widget.session.decideNavigation(location);

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
    await _controller.runJavaScript(bridgeJs);
    await _controller.runJavaScript(turboJs);

    final componentNames = _bridge.registeredComponentNames();
    if (componentNames.isNotEmpty) {
      final jsonNames = json.encode(componentNames);
      await _controller.runJavaScript(
        "window.nativeBridge.register($jsonNames)",
      );
    }
  }

  void _handleBridgeMessage(String payload) {
    if (payload == 'ready') {
      return;
    }
    try {
      final decoded = json.decode(payload);
      if (decoded is Map<String, dynamic>) {
        _bridge.handleMessage(decoded);
      }
    } catch (_) {
      // Ignore invalid payloads.
    }
  }

  Future<void> _sendBridgeReply(
    BridgeMessage originalMessage,
    Map<String, dynamic> data,
  ) async {
    final reply = originalMessage.replacingData(data).toMap();
    final jsonReply = json.encode(reply);
    await _controller.runJavaScript(
      "window.nativeBridge.replyWith($jsonReply)",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  @override
  void dispose() {
    widget.session.detachWebView(_adapter);
    super.dispose();
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
