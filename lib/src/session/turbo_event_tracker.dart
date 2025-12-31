class TurboVisitState {
  final String identifier;
  String? restorationIdentifier;
  bool hasCachedSnapshot;
  bool isPageRefresh;
  bool started;
  bool rendered;
  bool completed;
  int? statusCode;

  TurboVisitState({
    required this.identifier,
    this.restorationIdentifier,
    this.hasCachedSnapshot = false,
    this.isPageRefresh = false,
    this.started = false,
    this.rendered = false,
    this.completed = false,
    this.statusCode,
  });
}

class TurboEventOutcome {
  final String? proposedLocation;
  final Map<String, dynamic>? proposedOptions;
  final bool shouldReload;
  final String? errorMessage;

  const TurboEventOutcome({
    this.proposedLocation,
    this.proposedOptions,
    this.shouldReload = false,
    this.errorMessage,
  });
}

class TurboEventTracker {
  final Map<String, TurboVisitState> _visits = {};
  String? _currentVisitIdentifier;
  String? _lastRestorationIdentifier;
  String? _lastFormSubmissionLocation;
  bool _formSubmissionInProgress = false;

  TurboVisitState? visitFor(String identifier) => _visits[identifier];
  String? get currentVisitIdentifier => _currentVisitIdentifier;
  String? get lastRestorationIdentifier => _lastRestorationIdentifier;
  String? get lastFormSubmissionLocation => _lastFormSubmissionLocation;
  bool get formSubmissionInProgress => _formSubmissionInProgress;

  void setLastRestorationIdentifier(String? restorationIdentifier) {
    _lastRestorationIdentifier = restorationIdentifier;
  }

  void reset() {
    _visits.clear();
    _currentVisitIdentifier = null;
    _lastRestorationIdentifier = null;
    _lastFormSubmissionLocation = null;
    _formSubmissionInProgress = false;
  }

  TurboEventOutcome handle(String name, Map<String, dynamic> data) {
    switch (name) {
      case 'visitProposed':
        return _handleVisitProposed(data);
      case 'visitStarted':
        return _handleVisitStarted(data);
      case 'visitRequestStarted':
      case 'visitRequestCompleted':
      case 'visitRequestFinished':
      case 'visitRendered':
      case 'visitCompleted':
      case 'visitRequestFailed':
      case 'visitRequestFailedWithNonHttpStatusCode':
        return _handleVisitEvent(name, data);
      case 'formSubmissionStarted':
      case 'formSubmissionFinished':
      case 'pageLoaded':
      case 'pageInvalidated':
      case 'pageLoadFailed':
      case 'errorRaised':
      case 'visitProposalScrollingToAnchor':
      case 'visitProposalRefreshingPage':
      case 'log':
        return _handleLifecycleEvent(name, data);
      default:
        return const TurboEventOutcome();
    }
  }

  TurboEventOutcome _handleVisitProposed(Map<String, dynamic> data) {
    final location = data['location'];
    final options = data['options'];
    if (location is! String) {
      return const TurboEventOutcome();
    }
    return TurboEventOutcome(
      proposedLocation: location,
      proposedOptions: options is Map<String, dynamic> ? options : const {},
    );
  }

  TurboEventOutcome _handleVisitStarted(Map<String, dynamic> data) {
    final identifier = data['identifier'];
    if (identifier is! String) {
      return const TurboEventOutcome();
    }

    final visit = _visits.putIfAbsent(
      identifier,
      () => TurboVisitState(identifier: identifier),
    );
    visit.started = true;
    visit.hasCachedSnapshot = data['hasCachedSnapshot'] == true;
    visit.isPageRefresh = data['isPageRefresh'] == true;
    _currentVisitIdentifier = identifier;

    return const TurboEventOutcome();
  }

  TurboEventOutcome _handleVisitEvent(String name, Map<String, dynamic> data) {
    final identifier = data['identifier'];
    if (identifier is! String) {
      return const TurboEventOutcome();
    }

    final visit = _visits.putIfAbsent(
      identifier,
      () => TurboVisitState(identifier: identifier),
    );

    switch (name) {
      case 'visitRendered':
        visit.rendered = true;
        break;
      case 'visitCompleted':
        visit.completed = true;
        visit.restorationIdentifier = data['restorationIdentifier']?.toString();
        _lastRestorationIdentifier = visit.restorationIdentifier;
        if (_currentVisitIdentifier == identifier) {
          _currentVisitIdentifier = null;
        }
        break;
      case 'visitRequestFailed':
        visit.statusCode = data['statusCode'] as int?;
        return TurboEventOutcome(
          errorMessage: "Visit Failed: ${visit.statusCode}",
        );
      case 'visitRequestFailedWithNonHttpStatusCode':
        visit.statusCode = -1;
        return const TurboEventOutcome(
          errorMessage: "Visit Failed: non-HTTP status",
        );
      default:
        break;
    }

    return const TurboEventOutcome();
  }

  TurboEventOutcome _handleLifecycleEvent(
    String name,
    Map<String, dynamic> data,
  ) {
    switch (name) {
      case 'pageLoaded':
        final restorationIdentifier = data['restorationIdentifier'];
        if (restorationIdentifier is String &&
            restorationIdentifier.isNotEmpty) {
          _lastRestorationIdentifier = restorationIdentifier;
        }
        return const TurboEventOutcome();
      case 'formSubmissionStarted':
        final location = data['location'];
        if (location is String) {
          _lastFormSubmissionLocation = location;
          _formSubmissionInProgress = true;
        }
        return const TurboEventOutcome();
      case 'formSubmissionFinished':
        final location = data['location'];
        if (location is String) {
          _lastFormSubmissionLocation = location;
        }
        _formSubmissionInProgress = false;
        return const TurboEventOutcome();
      case 'pageInvalidated':
        return const TurboEventOutcome(shouldReload: true);
      case 'pageLoadFailed':
        return const TurboEventOutcome(errorMessage: "Turbo Page Load Failed");
      case 'errorRaised':
        return TurboEventOutcome(
          errorMessage: data['error']?.toString() ?? "Turbo Error",
        );
      default:
        return const TurboEventOutcome();
    }
  }
}
