import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../hotwire.dart';
import '../navigation/navigation_stack.dart';
import '../turbo/path_properties.dart';
import '../turbo/errors/visit_error.dart';
import '../turbo/visit/visit_action.dart';
import '../turbo/visit/visit_options.dart';
import '../turbo/visit/visit_proposal.dart';
import '../turbo/visit/visit_state.dart';
import 'route_decision.dart';
import 'turbo_event_tracker.dart';

abstract class SessionDelegate {
  void sessionDidStartRequest(Session session) {}
  void sessionDidFinishRequest(Session session) {}
  void sessionDidStartVisit(
    Session session,
    String identifier,
    bool hasCachedSnapshot,
    bool isPageRefresh,
  ) {}
  void sessionDidRenderVisit(Session session, String identifier) {}
  void sessionDidCompleteVisit(
    Session session,
    String identifier,
    String? restorationIdentifier,
  ) {}
  void sessionDidStartFormSubmission(Session session) {}
  void sessionDidFinishFormSubmission(Session session) {}
  void sessionDidLoadWebView(Session session) {}
  void sessionDidInvalidatePage(Session session) {}
  void sessionDidProposeVisit(Session session, VisitProposal proposal) {}
  void sessionDidFailRequest(Session session, VisitError error) {}
  void sessionDidFailRequestWithRetry(
    Session session,
    VisitError error,
    void Function() retry,
  ) {}
  void sessionDidFailRequestWithNonHttpStatus(
    Session session,
    String location,
    String identifier,
  ) {}
  void sessionDidProposeVisitToCrossOriginRedirect(
    Session session,
    String location,
  ) {}
  void sessionDidStartPage(Session session, String location) {}
  void sessionDidFinishPage(Session session, String location) {}
}

abstract class SessionVisitable {
  String get visitableIdentifier;
}

abstract class SessionWebViewAdapter {
  Future<void> load(String url);
  Future<void> runJavaScript(String javaScript);
  Future<void> reload();
}

class Session {
  SessionDelegate? delegate;
  final TurboEventTracker _tracker = TurboEventTracker();
  final RouteDecisionHandler _routeDecisionHandler;
  final NavigationStack? _navigationStack;
  bool _initialized = false;
  bool _turboReady = false;
  String? _lastVisitedLocation;
  SessionWebViewAdapter? _adapter;
  final Map<String, String> _restorationIdentifiers = {};
  final Map<String, String> _visitableRestorationIdentifiers = {};
  String? _currentVisitableId;
  String? _topmostVisitableId;
  String? _previousVisitableId;
  _PendingVisit? _pendingVisit;
  void Function(VisitError error, void Function() retry)? onError;

  Session({
    SessionDelegate? delegate,
    RouteDecisionHandler? routeDecisionHandler,
    NavigationStack? navigationStack,
  }) : delegate = delegate,
       _routeDecisionHandler = routeDecisionHandler ?? defaultRouteDecision,
       _navigationStack =
           navigationStack ??
           (Hotwire().config.startLocation == null
               ? null
               : NavigationStack(
                   startLocation:
                       Hotwire().config.startLocation?.toString(),
                 ));

  bool get isInitialized => _initialized;

  void markInitialized() {
    _initialized = true;
    delegate?.sessionDidLoadWebView(this);
  }

  void reset() {
    _initialized = false;
    _turboReady = false;
    _lastVisitedLocation = null;
    _restorationIdentifiers.clear();
    _visitableRestorationIdentifiers.clear();
    _currentVisitableId = null;
    _topmostVisitableId = null;
    _previousVisitableId = null;
    _pendingVisit = null;
    _tracker.reset();
    _navigationStack?.reset(
      startLocation: Hotwire().config.startLocation?.toString(),
    );
  }

  void attachWebView(SessionWebViewAdapter adapter) {
    _adapter = adapter;
  }

  void detachWebView(SessionWebViewAdapter adapter) {
    if (_adapter == adapter) {
      _adapter = null;
    }
  }

  void handleTurboMessage(String name, Map<String, dynamic> data) {
    _log('turboMessage $name data=$data');
    final outcome = _tracker.handle(name, data);

    if (outcome.proposedLocation != null) {
      final location = outcome.proposedLocation!;
      final options = _parseVisitOptions(outcome.proposedOptions);
      _proposeVisit(location, options);
    }

    switch (name) {
      case 'visitStarted':
        final identifier = data['identifier']?.toString();
        if (identifier != null) {
          final visit = _tracker.visitFor(identifier);
          if (visit != null) {
            delegate?.sessionDidStartVisit(
              this,
              identifier,
              visit.hasCachedSnapshot,
              visit.isPageRefresh,
            );
          }
        }
        break;
      case 'visitRendered':
        final identifier = data['identifier']?.toString();
        if (identifier != null) {
          delegate?.sessionDidRenderVisit(this, identifier);
        }
        break;
      case 'visitCompleted':
        final identifier = data['identifier'];
        final restorationIdentifier = data['restorationIdentifier'];
        if (identifier is String && restorationIdentifier is String) {
          _restorationIdentifiers[identifier] = restorationIdentifier;
          _storeRestorationIdentifierForCurrentVisitable(restorationIdentifier);
        }
        if (identifier is String) {
          delegate?.sessionDidCompleteVisit(
            this,
            identifier,
            restorationIdentifier?.toString(),
          );
        }
        break;
      case 'pageLoaded':
        final restorationIdentifier = data['restorationIdentifier'];
        if (restorationIdentifier is String &&
            restorationIdentifier.isNotEmpty) {
          _storeRestorationIdentifierForCurrentVisitable(restorationIdentifier);
        }
        break;
      case 'visitRequestFailedWithNonHttpStatusCode':
        final location = data['location'];
        final identifier = data['identifier'];
        if (location is String && identifier is String) {
          delegate?.sessionDidFailRequestWithNonHttpStatus(
            this,
            location,
            identifier,
          );
          _resolveCrossOriginRedirect(location, identifier);
        }
        break;
      case 'turboIsReady':
        final ready = data['ready'];
        if (ready is bool) {
          _setTurboReady(ready);
        }
        break;
      case 'formSubmissionStarted':
        delegate?.sessionDidStartFormSubmission(this);
        break;
      case 'formSubmissionFinished':
        delegate?.sessionDidFinishFormSubmission(this);
        break;
      case 'pageInvalidated':
        delegate?.sessionDidInvalidatePage(this);
        if (_initialized) {
          reload();
        }
        break;
      case 'visitRequestStarted':
        delegate?.sessionDidStartRequest(this);
        break;
      case 'visitRequestFinished':
        delegate?.sessionDidFinishRequest(this);
        break;
      case 'visitRequestFailed':
        final statusCode = data['statusCode'];
        if (statusCode is int) {
          _emitError(TurboError.http(statusCode));
        }
        break;
      case 'pageLoadFailed':
        _emitError(TurboError.pageLoadFailure());
        break;
      case 'errorRaised':
        final message =
            data['error']?.toString() ?? 'An unknown error occurred.';
        _emitError(TurboError.message(message));
        break;
      default:
        break;
    }
  }

  void _emitError(VisitError error) {
    void retry() {
      if (_initialized) {
        reload();
        return;
      }
      final lastLocation = _lastVisitedLocation;
      if (lastLocation != null) {
        visit(lastLocation);
      }
    }

    delegate?.sessionDidFailRequest(this, error);
    delegate?.sessionDidFailRequestWithRetry(this, error, retry);
    onError?.call(error, retry);
  }

  Future<void> visit(String location) async {
    _lastVisitedLocation = location;
    await _adapter?.load(location);
  }

  Future<void> visitWithOptions(
    String location, {
    VisitOptions options = const VisitOptions(),
    String? restorationIdentifier,
  }) async {
    _lastVisitedLocation = location;
    if (!_initialized) {
      await visit(location);
      return;
    }
    if (!_turboReady) {
      _pendingVisit = _PendingVisit(
        location: location,
        options: options,
        restorationIdentifier: restorationIdentifier,
      );
      return;
    }

    await _runVisitWithOptions(
      location,
      options: options,
      restorationIdentifier: restorationIdentifier,
    );
  }

  Future<void> restoreOrVisit(String location) async {
    final properties = Hotwire().config.pathConfiguration.properties(location);
    if (shouldRestore(nextLocation: location, properties: properties)) {
      await visitWithOptions(
        location,
        options: const VisitOptions(action: VisitAction.restore),
        restorationIdentifier: _tracker.lastRestorationIdentifier,
      );
      return;
    }
    await visit(location);
  }

  Future<void> cacheSnapshot() async {
    if (!_initialized) {
      return;
    }
    await _adapter?.runJavaScript("window.turboNative.cacheSnapshot()");
  }

  Future<void> clearSnapshotCache() async {
    if (!_initialized) {
      return;
    }
    await _adapter?.runJavaScript("window.turboNative.clearSnapshotCache()");
  }

  Future<void> reload() async {
    await _adapter?.reload();
  }

  RouteDecision decideNavigation(String location) {
    final properties = Hotwire().config.pathConfiguration.properties(location);
    if (_routeDecisionHandler != defaultRouteDecision) {
      return _routeDecisionHandler(
        location: location,
        properties: properties,
        initialized: _initialized,
      );
    }
    return Hotwire().config.routeDecisionManager.decide(
      location: location,
      properties: properties,
      initialized: _initialized,
    );
  }

  NavigationInstruction? routeWithNavigationStack(
    String location, {
    VisitOptions? options,
    Map<String, dynamic>? properties,
  }) {
    final stack = _navigationStack;
    if (stack == null) {
      return null;
    }
    final resolvedProperties =
        properties ?? Hotwire().config.pathConfiguration.properties(location);
    return stack.route(
      location: location,
      properties: resolvedProperties,
      options: options,
    );
  }

  bool isCrossOriginLocation(String location) {
    final lastLocation = _lastVisitedLocation;
    if (lastLocation == null) {
      return false;
    }
    final current = Uri.tryParse(lastLocation);
    final next = Uri.tryParse(location);
    if (current == null || next == null) {
      return false;
    }
    if (!_isHttpScheme(current.scheme) || !_isHttpScheme(next.scheme)) {
      return false;
    }
    return current.origin != next.origin;
  }

  void handleCrossOriginRedirect(String location) {
    delegate?.sessionDidProposeVisitToCrossOriginRedirect(this, location);
  }

  VisitState? visitState(String identifier) {
    final visit = _tracker.visitFor(identifier);
    if (visit == null) {
      return null;
    }
    return VisitState(
      identifier: visit.identifier,
      hasCachedSnapshot: visit.hasCachedSnapshot,
      isPageRefresh: visit.isPageRefresh,
      started: visit.started,
      rendered: visit.rendered,
      completed: visit.completed,
      failed: visit.statusCode != null,
      statusCode: visit.statusCode,
      restorationIdentifier: visit.restorationIdentifier,
    );
  }

  void recordVisitLocation(String location) {
    _lastVisitedLocation = location;
  }

  String? restorationIdentifierFor(String visitIdentifier) {
    return _restorationIdentifiers[visitIdentifier];
  }

  void attachVisitable(SessionVisitable visitable) {
    _currentVisitableId = visitable.visitableIdentifier;
    final restorationIdentifier =
        _visitableRestorationIdentifiers[visitable.visitableIdentifier];
    if (restorationIdentifier != null) {
      _tracker.setLastRestorationIdentifier(restorationIdentifier);
    }
  }

  void detachVisitable(SessionVisitable visitable) {
    if (_currentVisitableId == visitable.visitableIdentifier) {
      _currentVisitableId = null;
    }
  }

  void visitableDidAppear(SessionVisitable visitable) {
    if (_topmostVisitableId != visitable.visitableIdentifier) {
      _previousVisitableId = _topmostVisitableId;
      _topmostVisitableId = visitable.visitableIdentifier;
    }
  }

  void visitableDidDisappear(SessionVisitable visitable) {
    if (_topmostVisitableId == visitable.visitableIdentifier) {
      _topmostVisitableId = _previousVisitableId;
    }
  }

  String? get topmostVisitableIdentifier => _topmostVisitableId;
  String? get previousVisitableIdentifier => _previousVisitableId;

  String? restorationIdentifierForVisitable(SessionVisitable visitable) {
    return _visitableRestorationIdentifiers[visitable.visitableIdentifier];
  }

  void storeRestorationIdentifierForVisitable(
    SessionVisitable visitable,
    String restorationIdentifier,
  ) {
    _visitableRestorationIdentifiers[visitable.visitableIdentifier] =
        restorationIdentifier;
  }

  bool shouldRestore({
    required String nextLocation,
    required Map<String, dynamic> properties,
  }) {
    if (!_initialized || _lastVisitedLocation == null) {
      return false;
    }
    return isSameLocation(
      currentLocation: _lastVisitedLocation!,
      nextLocation: nextLocation,
      properties: properties,
    );
  }

  static bool isSameLocation({
    required String currentLocation,
    required String nextLocation,
    required Map<String, dynamic> properties,
  }) {
    final presentation = properties.queryStringPresentation;
    if (presentation == QueryStringPresentation.replace) {
      final currentPath = _pathWithoutQuery(currentLocation);
      final nextPath = _pathWithoutQuery(nextLocation);
      return currentPath == nextPath;
    }
    return currentLocation == nextLocation;
  }

  static String _pathWithoutQuery(String location) {
    try {
      return Uri.parse(location).path;
    } catch (_) {
      return location;
    }
  }

  static bool _isHttpScheme(String scheme) {
    final normalized = scheme.toLowerCase();
    return normalized == 'http' || normalized == 'https';
  }

  VisitOptions _parseVisitOptions(Map<String, dynamic>? options) {
    if (options == null) {
      return const VisitOptions();
    }
    return VisitOptions.fromJson(options);
  }

  void _proposeVisit(String location, VisitOptions options) {
    final properties = Hotwire().config.pathConfiguration.properties(location);
    final proposal = VisitProposal(
      url: Uri.parse(location),
      options: options,
      properties: properties,
    );
    delegate?.sessionDidProposeVisit(this, proposal);
  }

  void proposeVisitFromJson(String location, String optionsJson) {
    final options = VisitOptions.fromJsonString(optionsJson);
    _proposeVisit(location, options ?? const VisitOptions());
  }

  void updateFromJavaScriptMessage(String jsonMessage) {
    _log('turboRaw $jsonMessage');
    try {
      final decoded = json.decode(jsonMessage);
      if (decoded is Map<String, dynamic>) {
        final name = decoded['name']?.toString();
        final data = decoded['data'] is Map
            ? Map<String, dynamic>.from(decoded['data'] as Map)
            : <String, dynamic>{};
        if (name != null) {
          handleTurboMessage(name, data);
        }
      }
    } catch (_) {
      _log('turbo decode failed');
    }
  }

  void _log(String message) {
    if (Hotwire().config.debugLoggingEnabled) {
      // ignore: avoid_print
      print('[Session] $message');
    }
  }

  void _setTurboReady(bool ready) {
    _turboReady = ready;
    if (!ready) {
      reset();
      return;
    }

    final pending = _pendingVisit;
    if (pending != null) {
      _pendingVisit = null;
      _runVisitWithOptions(
        pending.location,
        options: pending.options,
        restorationIdentifier: pending.restorationIdentifier,
      );
    }
  }

  Future<void> _runVisitWithOptions(
    String location, {
    required VisitOptions options,
    String? restorationIdentifier,
  }) async {
    final optionsJson = json.encode({'action': options.action.name});
    final restoration = json.encode(
      restorationIdentifier ?? _tracker.lastRestorationIdentifier ?? '',
    );
    final locationJson = json.encode(location);

    await _adapter?.runJavaScript(
      "window.turboNative.visitLocationWithOptionsAndRestorationIdentifier($locationJson, $optionsJson, $restoration)",
    );
  }

  void _storeRestorationIdentifierForCurrentVisitable(
    String restorationIdentifier,
  ) {
    final visitableId = _currentVisitableId;
    if (visitableId == null) {
      return;
    }
    _visitableRestorationIdentifiers[visitableId] = restorationIdentifier;
  }

  Future<void> _resolveCrossOriginRedirect(
    String location,
    String identifier,
  ) async {
    final uri = Uri.tryParse(location);
    if (uri == null) {
      _emitError(TurboError.http(0));
      return;
    }

    final resolver =
        Hotwire().config.crossOriginRedirectResolver ??
        _defaultRedirectResolver;
    Uri? redirect;
    try {
      redirect = await resolver(uri);
    } catch (_) {
      _emitError(TurboError.http(0));
      return;
    }

    if (redirect == null) {
      _emitError(TurboError.http(0));
      return;
    }

    if (_isCrossOriginRedirect(uri, redirect)) {
      delegate?.sessionDidProposeVisitToCrossOriginRedirect(
        this,
        redirect.toString(),
      );
      return;
    }

    _emitError(TurboError.http(0));
  }

  static bool _isCrossOriginRedirect(Uri origin, Uri redirect) {
    if (!_isHttpScheme(origin.scheme) || !_isHttpScheme(redirect.scheme)) {
      return false;
    }
    return origin.origin != redirect.origin;
  }

  static Future<Uri?> _defaultRedirectResolver(Uri location) async {
    if (kIsWeb) {
      return null;
    }
    final client = HttpClient();
    try {
      final request = await client.getUrl(location);
      request.followRedirects = false;
      final response = await request.close();
      if (response.isRedirect) {
        final redirectValue = response.headers.value(HttpHeaders.locationHeader);
        if (redirectValue != null) {
          final redirect = Uri.tryParse(redirectValue);
          if (redirect != null) {
            return location.resolveUri(redirect);
          }
        }
      }
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

class _PendingVisit {
  final String location;
  final VisitOptions options;
  final String? restorationIdentifier;

  const _PendingVisit({
    required this.location,
    required this.options,
    required this.restorationIdentifier,
  });
}
