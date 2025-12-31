import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../hotwire.dart';
import '../session/route_decision.dart';
import '../session/session.dart';

typedef HotwireRouteRequestCallback =
    void Function(String location, Map<String, dynamic> properties);
typedef HotwireExternalNavigationCallback = void Function(String location);

class HotwireWebView extends StatefulWidget {
  final String url;
  final Session session;
  final HotwireRouteRequestCallback? onRouteRequest;
  final HotwireExternalNavigationCallback? onExternalNavigation;

  const HotwireWebView({
    required this.url,
    required this.session,
    this.onRouteRequest,
    this.onExternalNavigation,
    super.key,
  });

  @override
  State<HotwireWebView> createState() => _HotwireWebViewState();
}

class _HotwireWebViewState extends State<HotwireWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'HotwireNative',
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
            widget.session.markInitialized();
            widget.session.recordVisitLocation(url);
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
