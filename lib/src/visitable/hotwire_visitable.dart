import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../bridge/bridge.dart';
import '../session/session.dart';
import '../webview/hotwire_webview.dart';

class HotwireVisitable extends StatefulWidget {
  final String url;
  final Session session;
  final Bridge? bridge;
  final HotwireRouteRequestCallback? onRouteRequest;
  final HotwireExternalNavigationCallback? onExternalNavigation;
  final HotwireWebViewCreatedCallback? onWebViewCreated;
  final HotwireVisitableController? controller;
  final RouteObserver<PageRoute<dynamic>>? routeObserver;
  final String? visitableIdentifier;
  final Widget? webViewOverride;
  final SessionWebViewAdapter? adapterOverride;
  final Object? controllerOverride;
  final InAppWebViewKeepAlive? keepAlive;

  const HotwireVisitable({
    required this.url,
    required this.session,
    this.bridge,
    this.onRouteRequest,
    this.onExternalNavigation,
    this.onWebViewCreated,
    this.controller,
    this.routeObserver,
    this.visitableIdentifier,
    this.webViewOverride,
    this.adapterOverride,
    this.controllerOverride,
    this.keepAlive,
    super.key,
  });

  @override
  State<HotwireVisitable> createState() => _HotwireVisitableState();
}

class _HotwireVisitableState extends State<HotwireVisitable>
    implements RouteAware, SessionVisitable {
  late final String _visitableId;
  bool _attached = false;

  @override
  void initState() {
    super.initState();
    _visitableId = widget.visitableIdentifier ?? UniqueKey().toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = widget.routeObserver;
    if (observer != null) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        observer.subscribe(this, route);
      }
    } else {
      _attach();
    }
  }

  @override
  void dispose() {
    widget.routeObserver?.unsubscribe(this);
    _detach();
    super.dispose();
  }

  @override
  void didPush() {
    _attach();
  }

  @override
  void didPopNext() {
    _attach();
    widget.session.restoreOrVisit(widget.url);
  }

  @override
  void didPushNext() {
    _detach();
  }

  @override
  void didPop() {
    _detach();
  }

  @override
  String get visitableIdentifier => _visitableId;

  void _attach() {
    if (_attached) {
      return;
    }
    _attached = true;
    widget.session.attachVisitable(this);
    widget.controller?._attach(widget.session);
    widget.session.visitableDidAppear(this);
  }

  void _detach() {
    if (!_attached) {
      return;
    }
    widget.session.cacheSnapshot();
    _attached = false;
    widget.session.detachVisitable(this);
    widget.controller?._detach();
    widget.session.visitableDidDisappear(this);
  }

  @override
  Widget build(BuildContext context) {
    return HotwireWebView(
      url: widget.url,
      session: widget.session,
      bridge: widget.bridge,
      onRouteRequest: widget.onRouteRequest,
      onExternalNavigation: widget.onExternalNavigation,
      onWebViewCreated: widget.onWebViewCreated,
      webViewOverride: widget.webViewOverride,
      adapterOverride: widget.adapterOverride,
      controllerOverride: widget.controllerOverride,
      keepAlive: widget.keepAlive,
    );
  }
}

class HotwireVisitableController {
  Session? _session;

  bool get isAttached => _session != null;

  Future<void> reload() async {
    await _session?.reload();
  }

  Future<void> refresh() async {
    final session = _session;
    if (session == null) {
      return;
    }
    await session.clearSnapshotCache();
    await session.reload();
  }

  void _attach(Session session) {
    _session = session;
  }

  void _detach() {
    _session = null;
  }
}
