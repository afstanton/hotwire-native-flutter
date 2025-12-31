import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

class SessionDelegateSpy extends SessionDelegate {
  int proposedVisits = 0;
  int startRequests = 0;
  int finishRequests = 0;
  int startVisits = 0;
  int renderVisits = 0;
  int completeVisits = 0;
  String? lastVisitIdentifier;
  String? lastRestorationIdentifier;
  int nonHttpFailures = 0;
  int retryCallbacks = 0;
  VisitError? lastError;
  VisitProposal? lastProposal;
  String? lastNonHttpLocation;
  String? lastNonHttpIdentifier;
  String? lastCrossOriginLocation;

  @override
  void sessionDidProposeVisit(Session session, VisitProposal proposal) {
    proposedVisits += 1;
    lastProposal = proposal;
  }

  @override
  void sessionDidStartRequest(Session session) {
    startRequests += 1;
  }

  @override
  void sessionDidFinishRequest(Session session) {
    finishRequests += 1;
  }

  @override
  void sessionDidStartVisit(
    Session session,
    String identifier,
    bool hasCachedSnapshot,
    bool isPageRefresh,
  ) {
    startVisits += 1;
    lastVisitIdentifier = identifier;
  }

  @override
  void sessionDidRenderVisit(Session session, String identifier) {
    renderVisits += 1;
    lastVisitIdentifier = identifier;
  }

  @override
  void sessionDidCompleteVisit(
    Session session,
    String identifier,
    String? restorationIdentifier,
  ) {
    completeVisits += 1;
    lastVisitIdentifier = identifier;
    lastRestorationIdentifier = restorationIdentifier;
  }

  @override
  void sessionDidFailRequest(Session session, VisitError error) {
    lastError = error;
  }

  @override
  void sessionDidFailRequestWithRetry(
    Session session,
    VisitError error,
    void Function() retry,
  ) {
    retryCallbacks += 1;
    retry();
  }

  @override
  void sessionDidFailRequestWithNonHttpStatus(
    Session session,
    String location,
    String identifier,
  ) {
    nonHttpFailures += 1;
    lastNonHttpLocation = location;
    lastNonHttpIdentifier = identifier;
  }

  @override
  void sessionDidProposeVisitToCrossOriginRedirect(
    Session session,
    String location,
  ) {
    lastCrossOriginLocation = location;
  }
}

class FakeWebViewAdapter implements SessionWebViewAdapter {
  String? lastLoadedUrl;
  String? lastJavaScript;
  int reloadCount = 0;
  int javaScriptCalls = 0;

  @override
  Future<void> load(String url) async {
    lastLoadedUrl = url;
  }

  @override
  Future<void> reload() async {
    reloadCount += 1;
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    javaScriptCalls += 1;
    lastJavaScript = javaScript;
  }
}

void main() {
  test('Session proposes visit with properties', () async {
    final configuration = Hotwire().config.pathConfiguration;
    await _applySources(configuration, [
      PathConfigurationSource.data(r'''
      {
        "rules": [
          {
            "patterns": ["/modal$"],
            "properties": {"context": "modal"}
          }
        ]
      }
      '''),
    ]);

    final delegate = SessionDelegateSpy();
    final session = Session(delegate: delegate);

    session.handleTurboMessage('visitProposed', {
      'location': 'https://example.com/modal',
      'options': {'action': 'advance'},
    });

    expect(delegate.proposedVisits, 1);
    expect(delegate.lastProposal?.context, PresentationContext.modal);
  });

  test('Session reports request lifecycle and errors', () {
    final delegate = SessionDelegateSpy();
    final session = Session(delegate: delegate);
    final adapter = FakeWebViewAdapter();
    session.attachWebView(adapter);
    session.markInitialized();

    session.handleTurboMessage('visitRequestStarted', {'identifier': '1'});
    session.handleTurboMessage('visitRequestFinished', {'identifier': '1'});
    session.handleTurboMessage('visitRequestFailed', {
      'identifier': '1',
      'statusCode': 500,
    });

    expect(delegate.startRequests, 1);
    expect(delegate.finishRequests, 1);
    expect(delegate.lastError?.description, 'There was an HTTP error (500).');
    expect(delegate.retryCallbacks, 1);
    expect(adapter.reloadCount, 1);
  });

  test('RouteDecisionManager uses first matching handler', () {
    final manager = RouteDecisionManager(
      handlers: [
        ({
          required String location,
          required Map<String, dynamic> properties,
          required bool initialized,
        }) => location.contains('external') ? RouteDecision.external : null,
      ],
    );

    final decision = manager.decide(
      location: 'https://example.com/external',
      properties: const {},
      initialized: false,
    );

    expect(decision, RouteDecision.external);
  });

  test('Default route decision navigates non-modal links', () {
    final decision = defaultRouteDecision(
      location: 'https://example.com',
      properties: const {},
      initialized: true,
    );

    expect(decision, RouteDecision.navigate);
  });

  test('Session forwards page load failures and errors', () {
    final delegate = SessionDelegateSpy();
    final session = Session(delegate: delegate);
    final adapter = FakeWebViewAdapter();
    session.attachWebView(adapter);
    session.markInitialized();

    session.handleTurboMessage('pageLoadFailed', {});
    expect(
      delegate.lastError?.description,
      'The page could not be loaded due to a configuration error.',
    );
    expect(delegate.retryCallbacks, 1);
    expect(adapter.reloadCount, 1);

    session.handleTurboMessage('errorRaised', {'error': 'Boom'});
    expect(delegate.lastError?.description, 'Boom');
    expect(delegate.retryCallbacks, 2);
    expect(adapter.reloadCount, 2);
  });

  test('Session forwards non-http failures for redirect handling', () {
    final delegate = SessionDelegateSpy();
    final session = Session(delegate: delegate);

    session.handleTurboMessage('visitRequestFailedWithNonHttpStatusCode', {
      'location': 'https://example.com/redirect',
      'identifier': 'visit-1',
    });

    expect(delegate.nonHttpFailures, 1);
    expect(delegate.lastNonHttpLocation, 'https://example.com/redirect');
    expect(delegate.lastNonHttpIdentifier, 'visit-1');
  });

  test('Session compares locations with query string presentation', () {
    final session = Session();
    session.markInitialized();
    session.recordVisitLocation('https://example.com/items?one=1');

    final properties = {'query_string_presentation': 'replace'};
    expect(
      session.shouldRestore(
        nextLocation: 'https://example.com/items?two=2',
        properties: properties,
      ),
      isTrue,
    );
  });

  test('Session visits with JS after initialization', () async {
    final session = Session();
    final adapter = FakeWebViewAdapter();
    session.attachWebView(adapter);

    session.markInitialized();
    await session.visitWithOptions(
      'https://example.com/items',
      options: const VisitOptions(action: VisitAction.replace),
    );

    expect(adapter.lastLoadedUrl, isNull);
    expect(
      adapter.lastJavaScript,
      contains('visitLocationWithOptionsAndRestorationIdentifier'),
    );
  });

  test('Session performs cold boot load before initialization', () async {
    final session = Session();
    final adapter = FakeWebViewAdapter();
    session.attachWebView(adapter);

    await session.visitWithOptions('https://example.com/start');

    expect(adapter.lastLoadedUrl, 'https://example.com/start');
    expect(adapter.lastJavaScript, isNull);
  });

  test('Session snapshot cache only runs when initialized', () async {
    final session = Session();
    final adapter = FakeWebViewAdapter();
    session.attachWebView(adapter);

    await session.cacheSnapshot();
    expect(adapter.javaScriptCalls, 0);

    session.markInitialized();
    await session.cacheSnapshot();
    expect(adapter.javaScriptCalls, 1);
    expect(adapter.lastJavaScript, contains('cacheSnapshot'));
  });

  test('Session restoreOrVisit uses restore when matching location', () async {
    final session = Session();
    final adapter = FakeWebViewAdapter();
    session.attachWebView(adapter);

    session.markInitialized();
    session.recordVisitLocation('https://example.com/items?one=1');

    await session.restoreOrVisit('https://example.com/items?two=2');

    expect(adapter.lastLoadedUrl, 'https://example.com/items?two=2');
    expect(adapter.lastJavaScript, isNull);
  });

  test('Session pageInvalidated triggers reload when initialized', () async {
    final session = Session();
    final adapter = FakeWebViewAdapter();
    session.attachWebView(adapter);
    session.markInitialized();

    session.handleTurboMessage('pageInvalidated', {});

    expect(adapter.reloadCount, 1);
  });

  test('Session reset clears initialization state', () {
    final session = Session();
    session.markInitialized();
    session.recordVisitLocation('https://example.com/items');

    session.reset();

    expect(session.isInitialized, isFalse);
    expect(
      session.shouldRestore(
        nextLocation: 'https://example.com/items',
        properties: const {},
      ),
      isFalse,
    );
  });

  test('Session stores restoration identifier on visit completion', () {
    final session = Session();
    session.handleTurboMessage('visitCompleted', {
      'identifier': 'visit-1',
      'restorationIdentifier': 'rest-1',
    });

    expect(session.restorationIdentifierFor('visit-1'), 'rest-1');
  });

  test('Session tracks visit lifecycle events and state', () {
    final delegate = SessionDelegateSpy();
    final session = Session(delegate: delegate);

    session.handleTurboMessage('visitStarted', {
      'identifier': 'visit-1',
      'hasCachedSnapshot': true,
      'isPageRefresh': false,
    });
    session.handleTurboMessage('visitRendered', {'identifier': 'visit-1'});
    session.handleTurboMessage('visitCompleted', {
      'identifier': 'visit-1',
      'restorationIdentifier': 'rest-1',
    });

    expect(delegate.startVisits, 1);
    expect(delegate.renderVisits, 1);
    expect(delegate.completeVisits, 1);
    expect(delegate.lastVisitIdentifier, 'visit-1');
    expect(delegate.lastRestorationIdentifier, 'rest-1');

    final state = session.visitState('visit-1');
    expect(state?.started, isTrue);
    expect(state?.rendered, isTrue);
    expect(state?.completed, isTrue);
    expect(state?.hasCachedSnapshot, isTrue);
  });

  test('Session marks visits as failed on request errors', () {
    final session = Session();

    session.handleTurboMessage('visitStarted', {
      'identifier': 'visit-2',
      'hasCachedSnapshot': false,
      'isPageRefresh': false,
    });
    session.handleTurboMessage('visitRequestFailed', {
      'identifier': 'visit-2',
      'statusCode': 503,
    });

    final state = session.visitState('visit-2');
    expect(state?.failed, isTrue);
    expect(state?.statusCode, 503);
  });

  test('Session detects cross-origin redirects', () {
    final session = Session();
    session.recordVisitLocation('https://example.com/items');

    expect(
      session.isCrossOriginLocation('https://other.example.com/items'),
      isTrue,
    );
    expect(session.isCrossOriginLocation('https://example.com/other'), isFalse);
  });

  test('Session reports cross-origin redirect proposals', () {
    final delegate = SessionDelegateSpy();
    final session = Session(delegate: delegate);

    session.handleCrossOriginRedirect('https://other.example.com/items');

    expect(delegate.lastCrossOriginLocation, 'https://other.example.com/items');
  });
}

Future<void> _applySources(
  PathConfiguration configuration,
  List<PathConfigurationSource> sources,
) async {
  final completer = Completer<void>();
  late final StreamSubscription sub;
  sub = configuration.onUpdated.listen((_) {
    sub.cancel();
    completer.complete();
  });
  configuration.sources = sources;
  await completer.future;
}
