import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

class SessionDelegateSpy extends SessionDelegate {
  int proposedVisits = 0;
  int startRequests = 0;
  int finishRequests = 0;
  String? lastError;
  VisitProposal? lastProposal;

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
  void sessionDidFailRequest(Session session, String errorMessage) {
    lastError = errorMessage;
  }
}

class FakeWebViewAdapter implements SessionWebViewAdapter {
  String? lastLoadedUrl;
  String? lastJavaScript;
  int reloadCount = 0;

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

    session.handleTurboMessage('visitRequestStarted', {'identifier': '1'});
    session.handleTurboMessage('visitRequestFinished', {'identifier': '1'});
    session.handleTurboMessage('visitRequestFailed', {
      'identifier': '1',
      'statusCode': 500,
    });

    expect(delegate.startRequests, 1);
    expect(delegate.finishRequests, 1);
    expect(delegate.lastError, 'Visit Failed: 500');
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
