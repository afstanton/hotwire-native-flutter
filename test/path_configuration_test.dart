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
