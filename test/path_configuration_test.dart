import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

void main() {
  test('PathConfigurationRule matches regex patterns', () {
    final rule = PathConfigurationRule(
      patterns: [r'^/items/\d+$'],
      properties: const {'context': 'modal'},
    );

    expect(rule.matches('/items/12'), isTrue);
    expect(rule.matches('/items/abc'), isFalse);
  });

  test('PathConfiguration loads data source and merges rules', () async {
    final configJson = r'''
    {
      "settings": {"feature_enabled": true},
      "rules": [
        {
          "patterns": ["/items$"],
          "properties": {"context": "modal", "pull_to_refresh_enabled": false}
        }
      ]
    }
    ''';

    final configuration = PathConfiguration();
    await _applySources(configuration, [
      PathConfigurationSource.data(configJson),
    ]);

    final properties = configuration.properties('https://example.com/items');
    expect(properties['context'], 'modal');
    expect(properties['pull_to_refresh_enabled'], false);
    expect(configuration.settings['feature_enabled'], true);
  });

  test('PathConfiguration includes default historical routes', () async {
    final configuration = PathConfiguration();
    await _applySources(configuration, [
      PathConfigurationSource.data('{"rules": []}'),
    ]);

    final properties = configuration.properties(
      'https://example.com/recede_historical_location',
    );
    expect(properties['historical_location'], true);
    expect(properties['presentation'], 'pop');
  });

  test('PathConfiguration parses tabs property', () async {
    final configuration = PathConfiguration();
    await _applySources(configuration, [
      PathConfigurationSource.data(r'''
      {
        "rules": [
          {
            "patterns": ["/custom/tabs"],
            "properties": {
              "tabs": [
                {"label": "Tab 1", "path": "/tab-1"}
              ]
            }
          }
        ]
      }
      '''),
    ]);

    final properties = configuration.properties(
      'https://example.com/custom/tabs',
    );
    final tabs = properties.tabs;

    expect(tabs, isNotNull);
    expect(tabs?.length, 1);
    expect(tabs?.first.label, 'Tab 1');
    expect(tabs?.first.path, '/tab-1');
  });

  test('PathConfiguration parses modal properties', () async {
    final configuration = PathConfiguration();
    await _applySources(configuration, [
      PathConfigurationSource.data(r'''
      {
        "rules": [
          {
            "patterns": ["/modal"],
            "properties": {
              "modal_style": "page_sheet",
              "modal_dismiss_gesture_enabled": false,
              "view_controller": "custom"
            }
          }
        ]
      }
      '''),
    ]);

    final properties = configuration.properties('https://example.com/modal');

    expect(properties.modalStyle, ModalStyle.pageSheet);
    expect(properties.modalDismissGestureEnabled, isFalse);
    expect(properties.viewController, 'custom');
  });

  test('PathConfiguration reports invalid JSON errors', () async {
    final configuration = PathConfiguration();
    final error = await _errorFromSources(configuration, [
      const PathConfigurationSource.data('{"rules": "invalid"}'),
    ]);
    expect(error.type, PathConfigurationErrorType.invalidData);
  });

  test('PathConfiguration loader reports download failures', () async {
    final loader = PathConfigurationLoader(repository: _FailingRepository());

    final errors = <PathConfigurationError>[];
    await loader.load(
      sources: const [
        PathConfigurationSource.server('https://example.com/config.json'),
      ],
      onLoaded: (_) {},
      onError: errors.add,
    );

    expect(errors, isNotEmpty);
    expect(errors.first.type, PathConfigurationErrorType.downloadFailed);
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

Future<PathConfigurationError> _nextError(PathConfiguration configuration) {
  final completer = Completer<PathConfigurationError>();
  late final StreamSubscription sub;
  sub = configuration.onError.listen((error) {
    sub.cancel();
    completer.complete(error);
  });
  return completer.future;
}

Future<PathConfigurationError> _errorFromSources(
  PathConfiguration configuration,
  List<PathConfigurationSource> sources,
) async {
  final completer = Completer<PathConfigurationError>();
  late final StreamSubscription sub;
  sub = configuration.onError.listen((error) {
    sub.cancel();
    completer.complete(error);
  });
  configuration.sources = sources;
  return completer.future;
}

class _FailingRepository extends PathConfigurationRepository {
  @override
  Future<String?> download(String url, {Map<String, String>? headers}) async {
    return null;
  }
}
