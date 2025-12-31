import 'dart:convert';

import '../hotwire.dart';
import '../turbo/path_properties.dart';
import '../turbo/visit/visit_action.dart';
import '../turbo/visit/visit_options.dart';
import '../turbo/visit/visit_proposal.dart';
import 'route_decision.dart';
import 'turbo_event_tracker.dart';

abstract class SessionDelegate {
  void sessionDidStartRequest(Session session) {}
  void sessionDidFinishRequest(Session session) {}
  void sessionDidStartFormSubmission(Session session) {}
  void sessionDidFinishFormSubmission(Session session) {}
  void sessionDidLoadWebView(Session session) {}
  void sessionDidInvalidatePage(Session session) {}
  void sessionDidProposeVisit(Session session, VisitProposal proposal) {}
  void sessionDidFailRequest(Session session, String errorMessage) {}
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
    if (outcome.errorMessage != null) {
      delegate?.sessionDidFailRequest(this, outcome.errorMessage!);
    }

    if (outcome.proposedLocation != null) {
      final location = outcome.proposedLocation!;
      final options = _parseVisitOptions(outcome.proposedOptions);
      _proposeVisit(location, options);
    }

    switch (name) {
      case 'formSubmissionStarted':
        delegate?.sessionDidStartFormSubmission(this);
        break;
      case 'formSubmissionFinished':
        delegate?.sessionDidFinishFormSubmission(this);
        break;
      case 'pageInvalidated':
        delegate?.sessionDidInvalidatePage(this);
        break;
      case 'visitRequestStarted':
        delegate?.sessionDidStartRequest(this);
        break;
      case 'visitRequestFinished':
        delegate?.sessionDidFinishRequest(this);
        break;
      default:
        break;
    }
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
    return _routeDecisionHandler(
      location: location,
      properties: properties,
      initialized: _initialized,
    );
  }

  void recordVisitLocation(String location) {
    _lastVisitedLocation = location;
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
