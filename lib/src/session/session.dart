import 'dart:convert';

import '../hotwire.dart';
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

abstract class SessionWebViewAdapter {
  Future<void> load(String url);
  Future<void> runJavaScript(String javaScript);
  Future<void> reload();
}

class Session {
  SessionDelegate? delegate;
  final TurboEventTracker _tracker = TurboEventTracker();
  final RouteDecisionHandler _routeDecisionHandler;
  bool _initialized = false;
  String? _lastVisitedLocation;
  SessionWebViewAdapter? _adapter;
  final Map<String, String> _restorationIdentifiers = {};
  void Function(VisitError error, void Function() retry)? onError;

  Session({
    SessionDelegate? delegate,
    RouteDecisionHandler? routeDecisionHandler,
  }) : delegate = delegate,
       _routeDecisionHandler = routeDecisionHandler ?? defaultRouteDecision;

  bool get isInitialized => _initialized;

  void markInitialized() {
    _initialized = true;
    delegate?.sessionDidLoadWebView(this);
  }

  void reset() {
    _initialized = false;
    _lastVisitedLocation = null;
    _restorationIdentifiers.clear();
    _tracker.reset();
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
        }
        if (identifier is String) {
          delegate?.sessionDidCompleteVisit(
            this,
            identifier,
            restorationIdentifier?.toString(),
          );
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

    final optionsJson = json.encode({'action': options.action.name});
    final restoration = json.encode(
      restorationIdentifier ?? _tracker.lastRestorationIdentifier ?? '',
    );
    final locationJson = json.encode(location);

    await _adapter?.runJavaScript(
      "window.turboNative.visitLocationWithOptionsAndRestorationIdentifier($locationJson, $optionsJson, $restoration)",
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
      // Ignore invalid payloads.
    }
  }
}
