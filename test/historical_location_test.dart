import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

void main() {
  test('Historical location action resolves presentation', () {
    final properties = {'presentation': 'pop', 'historical_location': true};

    final action = resolveHistoricalLocationAction(
      properties: properties,
      isModal: false,
    );

    expect(action, isNotNull);
    expect(action?.presentation, Presentation.pop);
    expect(action?.dismissModal, isFalse);
  });

  test('Historical location action defaults to none', () {
    final properties = {'historical_location': true};

    final action = resolveHistoricalLocationAction(
      properties: properties,
      isModal: false,
    );

    expect(action?.presentation, Presentation.none);
  });

  test('Historical location action dismisses modal', () {
    final properties = {'presentation': 'refresh', 'historical_location': true};

    final action = resolveHistoricalLocationAction(
      properties: properties,
      isModal: true,
    );

    expect(action?.presentation, Presentation.refresh);
    expect(action?.dismissModal, isTrue);
  });

  test('Historical location action returns null when not historical', () {
    final action = resolveHistoricalLocationAction(
      properties: const {},
      isModal: false,
    );

    expect(action, isNull);
  });
}
