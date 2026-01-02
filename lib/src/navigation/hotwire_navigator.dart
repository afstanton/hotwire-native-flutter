import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../hotwire.dart';
import '../session/route_decision.dart';
import '../session/session.dart';
import '../session/session_pair.dart';
import '../turbo/errors/visit_error.dart';
import '../turbo/path_properties.dart';
import '../turbo/visit/visit_action.dart';
import '../turbo/visit/visit_options.dart';
import '../turbo/visit/visit_proposal.dart';
import '../visitable/hotwire_visitable.dart';
import 'navigation_controller.dart';
import 'navigation_stack.dart';

enum HotwireProposalDecision { accept, acceptCustom, reject }

class HotwireProposalResult {
  final HotwireProposalDecision decision;
  final Widget? customPage;

  const HotwireProposalResult._(this.decision, this.customPage);

  static const HotwireProposalResult accept = HotwireProposalResult._(
    HotwireProposalDecision.accept,
    null,
  );

  static const HotwireProposalResult reject = HotwireProposalResult._(
    HotwireProposalDecision.reject,
    null,
  );

  factory HotwireProposalResult.acceptCustom(Widget page) {
    return HotwireProposalResult._(HotwireProposalDecision.acceptCustom, page);
  }
}

abstract class HotwireNavigatorDelegate extends SessionDelegate {
  HotwireProposalResult handle(VisitProposal proposal, HotwireNavigator navigator);
}

class DefaultHotwireNavigatorDelegate extends HotwireNavigatorDelegate {
  @override
  HotwireProposalResult handle(VisitProposal proposal, HotwireNavigator navigator) {
    return HotwireProposalResult.accept;
  }
}

abstract class HotwireRouteBuilder {
  PageRoute<dynamic> buildRoute(
    Widget page, {
    required bool isModal,
    required String location,
  });
}

class MaterialHotwireRouteBuilder implements HotwireRouteBuilder {
  const MaterialHotwireRouteBuilder();

  @override
  PageRoute<dynamic> buildRoute(
    Widget page, {
    required bool isModal,
    required String location,
  }) {
    return MaterialPageRoute(
      fullscreenDialog: isModal,
      settings: HotwireRouteSettings(location: location, isModal: isModal),
      builder: (_) => page,
    );
  }
}

class HotwireRouteSettings extends RouteSettings {
  final String location;
  final bool isModal;

  const HotwireRouteSettings({
    required this.location,
    required this.isModal,
    super.name,
    super.arguments,
  });
}

typedef HotwireVisitableBuilder =
    Widget Function({
      required VisitProposal proposal,
      required Session session,
      required InAppWebViewKeepAlive keepAlive,
      required RouteObserver<PageRoute<dynamic>> routeObserver,
      required bool isModal,
    });

abstract class HotwireProposalExecutor {
  void setActiveProposal(VisitProposal? proposal);
  void setCustomPage(Widget? page);
}

class HotwireNavigator implements SessionDelegate {
  final GlobalKey<NavigatorState> navigatorKey;
  final HotwireNavigatorDelegate delegate;
  final HotwireRouteBuilder routeBuilder;
  final HotwireVisitableBuilder visitableBuilder;
  late final HotwireSessionPair sessions;
  late final NavigationStack navigationStack;
  late final RouteObserver<PageRoute<dynamic>> routeObserver;
  late final NavigationHierarchyController navigationController;
  late final NavigationExecutor _executor;

  HotwireNavigator({
    required this.navigatorKey,
    HotwireNavigatorDelegate? delegate,
    HotwireRouteBuilder? routeBuilder,
    HotwireVisitableBuilder? visitableBuilder,
    HotwireSessionPair? sessions,
    NavigationStack? navigationStack,
    RouteObserver<PageRoute<dynamic>>? routeObserver,
    NavigationExecutor? executorOverride,
  })  : delegate = delegate ?? DefaultHotwireNavigatorDelegate(),
        routeBuilder = routeBuilder ?? const MaterialHotwireRouteBuilder(),
        visitableBuilder = visitableBuilder ?? _defaultVisitableBuilder {
    assert(
      sessions == null || navigationStack != null,
      'Provide navigationStack when supplying sessions to HotwireNavigator.',
    );
    final stack =
        navigationStack ??
        NavigationStack(
          startLocation: Hotwire().config.startLocation?.toString(),
        );
    final observer = routeObserver ?? RouteObserver<PageRoute<dynamic>>();
    final sessionPair =
        sessions ??
        HotwireSessionPair(
          mainSession: Session(navigationStack: stack),
          modalSession: Session(),
        );

    this.navigationStack = stack;
    this.routeObserver = observer;
    this.sessions = sessionPair;

    _executor =
        executorOverride ??
        HotwireNavigationExecutor(
          navigatorKey: navigatorKey,
          routeBuilder: this.routeBuilder,
          visitableBuilder: this.visitableBuilder,
          sessionPair: sessionPair,
          routeObserver: observer,
        );

    navigationController = NavigationHierarchyController(
      stack: stack,
      executor: _executor,
    );

    sessionPair.mainSession.delegate = this;
    sessionPair.modalSession.delegate = this;
  }

  static Widget _defaultVisitableBuilder({
    required VisitProposal proposal,
    required Session session,
    required InAppWebViewKeepAlive keepAlive,
    required RouteObserver<PageRoute<dynamic>> routeObserver,
    required bool isModal,
  }) {
    return HotwireVisitable(
      url: proposal.url.toString(),
      session: session,
      routeObserver: routeObserver,
      keepAlive: keepAlive,
    );
  }

  List<NavigatorObserver> get observers {
    final observers = <NavigatorObserver>[routeObserver];
    if (_executor is HotwireNavigationExecutor) {
      observers.add(
        (_executor as HotwireNavigationExecutor).navigatorObserver,
      );
    }
    return observers;
  }

  Session get session => sessions.mainSession;
  Session get modalSession => sessions.modalSession;

  void start() {
    final startLocation = Hotwire().config.startLocation?.toString();
    if (startLocation == null) {
      return;
    }
    routeLocation(startLocation);
  }

  void routeLocation(
    String location, {
    VisitOptions options = const VisitOptions(),
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? properties,
  }) {
    final uri = Uri.tryParse(location);
    if (uri == null) {
      return;
    }
    final resolvedProperties =
        properties ?? Hotwire().config.pathConfiguration.properties(location);
    routeProposal(
      VisitProposal(
        url: uri,
        options: options,
        properties: resolvedProperties,
        parameters: parameters,
      ),
    );
  }

  void routeProposal(VisitProposal proposal) {
    final decision = Hotwire().config.routeDecisionManager.decide(
      location: proposal.url.toString(),
      properties: proposal.properties,
      initialized: session.isInitialized,
    );
    if (decision == RouteDecision.external) {
      return;
    }

    final result = delegate.handle(proposal, this);
    if (result.decision == HotwireProposalDecision.reject) {
      return;
    }

    if (_executor is HotwireProposalExecutor) {
      final proposalExecutor = _executor as HotwireProposalExecutor;
      proposalExecutor.setActiveProposal(proposal);
      proposalExecutor.setCustomPage(result.customPage);
    }

    navigationController.route(
      NavigationRequest(
        location: proposal.url.toString(),
        properties: proposal.properties,
        options: proposal.options,
      ),
    );

    if (_executor is HotwireProposalExecutor) {
      final proposalExecutor = _executor as HotwireProposalExecutor;
      proposalExecutor.setActiveProposal(null);
      proposalExecutor.setCustomPage(null);
    }
  }

  void pop() {
    final state = navigationStack.state;
    if (state.modalStack.isEmpty && state.mainStack.isEmpty) {
      return;
    }
    final isModal = state.modalStack.isNotEmpty;
    final location = isModal
        ? state.modalStack.last
        : (state.mainStack.isNotEmpty ? state.mainStack.last : null);
    if (location == null) {
      return;
    }
    _routeWithPresentation(
      location,
      presentation: Presentation.pop,
      context: isModal ? PresentationContext.modal : PresentationContext.defaultValue,
    );
  }

  void clearAll({String? location}) {
    final target = location ?? Hotwire().config.startLocation?.toString();
    if (target == null) {
      return;
    }
    _routeWithPresentation(
      target,
      presentation: Presentation.clearAll,
      context: PresentationContext.defaultValue,
    );
  }

  void replaceRoot({String? location}) {
    final target = location ?? Hotwire().config.startLocation?.toString();
    if (target == null) {
      return;
    }
    _routeWithPresentation(
      target,
      presentation: Presentation.replaceRoot,
      context: PresentationContext.defaultValue,
    );
  }

  void reload() {
    session.reload();
    modalSession.reload();
  }

  void _routeWithPresentation(
    String location, {
    required Presentation presentation,
    required PresentationContext context,
  }) {
    navigationController.route(
      NavigationRequest(
        location: location,
        properties: {
          'presentation': _presentationValue(presentation),
          'context': _contextValue(context),
        },
        options: const VisitOptions(action: VisitAction.advance),
      ),
    );
  }

  String _presentationValue(Presentation presentation) {
    switch (presentation) {
      case Presentation.clearAll:
        return 'clear_all';
      case Presentation.replaceRoot:
        return 'replace_root';
      case Presentation.replace:
        return 'replace';
      case Presentation.pop:
        return 'pop';
      case Presentation.none:
        return 'none';
      case Presentation.refresh:
        return 'refresh';
      case Presentation.defaultValue:
        return 'default';
    }
  }

  String _contextValue(PresentationContext context) {
    switch (context) {
      case PresentationContext.modal:
        return 'modal';
      case PresentationContext.defaultValue:
        return 'default';
    }
  }

  @override
  void sessionDidStartRequest(Session session) {
    delegate.sessionDidStartRequest(session);
  }

  @override
  void sessionDidFinishRequest(Session session) {
    delegate.sessionDidFinishRequest(session);
  }

  @override
  void sessionDidStartVisit(
    Session session,
    String identifier,
    bool hasCachedSnapshot,
    bool isPageRefresh,
  ) {
    delegate.sessionDidStartVisit(
      session,
      identifier,
      hasCachedSnapshot,
      isPageRefresh,
    );
  }

  @override
  void sessionDidRenderVisit(Session session, String identifier) {
    delegate.sessionDidRenderVisit(session, identifier);
  }

  @override
  void sessionDidCompleteVisit(
    Session session,
    String identifier,
    String? restorationIdentifier,
  ) {
    delegate.sessionDidCompleteVisit(session, identifier, restorationIdentifier);
  }

  @override
  void sessionDidStartFormSubmission(Session session) {
    delegate.sessionDidStartFormSubmission(session);
  }

  @override
  void sessionDidFinishFormSubmission(Session session) {
    delegate.sessionDidFinishFormSubmission(session);
  }

  @override
  void sessionDidLoadWebView(Session session) {
    delegate.sessionDidLoadWebView(session);
  }

  @override
  void sessionDidInvalidatePage(Session session) {
    delegate.sessionDidInvalidatePage(session);
  }

  @override
  void sessionDidProposeVisit(Session session, VisitProposal proposal) {
    final response = proposal.options.response;
    final isRedirect = response?.redirected == true;
    if (isRedirect &&
        session == modalSession &&
        proposal.context == PresentationContext.defaultValue) {
      pop();
    }
    routeProposal(proposal);
    delegate.sessionDidProposeVisit(session, proposal);
  }

  @override
  void sessionDidFailRequest(Session session, VisitError error) {
    delegate.sessionDidFailRequest(session, error);
  }

  @override
  void sessionDidFailRequestWithRetry(
    Session session,
    VisitError error,
    void Function() retry,
  ) {
    delegate.sessionDidFailRequestWithRetry(session, error, retry);
  }

  @override
  void sessionDidFailRequestWithNonHttpStatus(
    Session session,
    String location,
    String identifier,
  ) {
    delegate.sessionDidFailRequestWithNonHttpStatus(
      session,
      location,
      identifier,
    );
  }

  @override
  void sessionDidProposeVisitToCrossOriginRedirect(
    Session session,
    String location,
  ) {
    pop();
    routeLocation(location);
    delegate.sessionDidProposeVisitToCrossOriginRedirect(session, location);
  }

  @override
  void sessionDidStartPage(Session session, String location) {
    delegate.sessionDidStartPage(session, location);
  }

  @override
  void sessionDidFinishPage(Session session, String location) {
    delegate.sessionDidFinishPage(session, location);
  }
}

class HotwireNavigationExecutor
    implements NavigationExecutor, HotwireProposalExecutor {
  final GlobalKey<NavigatorState> navigatorKey;
  final HotwireRouteBuilder routeBuilder;
  final HotwireVisitableBuilder visitableBuilder;
  final HotwireSessionPair sessionPair;
  final RouteObserver<PageRoute<dynamic>> routeObserver;
  final HotwireNavigationObserver navigatorObserver = HotwireNavigationObserver();

  VisitProposal? _activeProposal;
  Widget? _customPage;

  HotwireNavigationExecutor({
    required this.navigatorKey,
    required this.routeBuilder,
    required this.visitableBuilder,
    required this.sessionPair,
    required this.routeObserver,
  });

  @override
  void setActiveProposal(VisitProposal? proposal) {
    _activeProposal = proposal;
  }

  @override
  void setCustomPage(Widget? page) {
    _customPage = page;
  }

  @override
  void push(String location, {required bool isModal}) {
    _pushRoute(location, isModal: isModal, replace: false);
  }

  @override
  void replace(String location, {required bool isModal}) {
    _pushRoute(location, isModal: isModal, replace: true);
  }

  @override
  void pop({required bool isModal}) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    if (isModal && !navigatorObserver.isModalOnTop) {
      return;
    }
    navigator.pop();
  }

  @override
  void clearAll(String location) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    final route = _buildRoute(location, isModal: false);
    navigator.pushAndRemoveUntil(route, (route) => false);
  }

  @override
  void replaceRoot(String location) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    final route = _buildRoute(location, isModal: false);
    navigator.pushAndRemoveUntil(route, (route) => false);
  }

  @override
  void presentModal() {}

  @override
  void dismissModal() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    if (!navigatorObserver.isModalOnTop) {
      return;
    }
    navigator.popUntil((route) {
      final settings = route.settings;
      if (settings is HotwireRouteSettings) {
        return !settings.isModal;
      }
      return true;
    });
  }

  @override
  void refresh(String location, {required bool isModal}) {
    final session = isModal
        ? sessionPair.modalSession
        : sessionPair.mainSession;
    session.restoreOrVisit(location);
  }

  void _pushRoute(
    String location, {
    required bool isModal,
    required bool replace,
  }) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    final route = _buildRoute(location, isModal: isModal);

    if (replace) {
      if (isModal && !navigatorObserver.isModalOnTop) {
        navigator.push(route);
        return;
      }
      navigator.pushReplacement(route);
      return;
    }

    navigator.push(route);
  }

  PageRoute<dynamic> _buildRoute(String location, {required bool isModal}) {
    final proposal =
        _activeProposal ?? _proposalFromLocation(location);
    final page = _customPage ??
        visitableBuilder(
          proposal: proposal,
          session:
              isModal ? sessionPair.modalSession : sessionPair.mainSession,
          keepAlive:
              sessionPair.keepAliveForContext(
                isModal
                    ? PresentationContext.modal
                    : PresentationContext.defaultValue,
              ),
          routeObserver: routeObserver,
          isModal: isModal,
        );
    return routeBuilder.buildRoute(
      page,
      isModal: isModal,
      location: location,
    );
  }

  VisitProposal _proposalFromLocation(String location) {
    final uri = Uri.parse(location);
    return VisitProposal(
      url: uri,
      options: const VisitOptions(),
      properties: Hotwire().config.pathConfiguration.properties(location),
    );
  }
}

class HotwireNavigationObserver extends NavigatorObserver {
  final List<_HotwireRouteEntry> _stack = [];

  bool get isModalOnTop =>
      _stack.isNotEmpty && _stack.last.isModal;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final entry = _entryFor(route);
    if (entry != null) {
      _stack.add(entry);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      _remove(oldRoute);
    }
    if (newRoute != null) {
      final entry = _entryFor(newRoute);
      if (entry != null) {
        _stack.add(entry);
      }
    }
  }

  void _remove(Route<dynamic> route) {
    _stack.removeWhere((entry) => entry.route == route);
  }

  _HotwireRouteEntry? _entryFor(Route<dynamic> route) {
    final settings = route.settings;
    if (settings is! HotwireRouteSettings) {
      return null;
    }
    return _HotwireRouteEntry(
      route: route,
      location: settings.location,
      isModal: settings.isModal,
    );
  }
}

class _HotwireRouteEntry {
  final Route<dynamic> route;
  final String location;
  final bool isModal;

  const _HotwireRouteEntry({
    required this.route,
    required this.location,
    required this.isModal,
  });
}
