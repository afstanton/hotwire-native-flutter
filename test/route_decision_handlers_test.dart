import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

void main() {
  test('AppNavigation handler matches same host http(s) URLs', () {
    final handler = appNavigationRouteDecisionHandler(
      () => Uri.parse('https://my.app.com'),
    );

    final decision = handler(
      location: 'https://my.app.com/page',
      properties: const {},
      initialized: true,
    );

    expect(decision, RouteDecision.navigate);
  });

  test('AppNavigation handler ignores non-http schemes', () {
    final handler = appNavigationRouteDecisionHandler(
      () => Uri.parse('https://my.app.com'),
    );

    final decision = handler(
      location: 'sms:555-555-5555',
      properties: const {},
      initialized: true,
    );

    expect(decision, isNull);
  });

  test('AppNavigation handler ignores other hosts', () {
    final handler = appNavigationRouteDecisionHandler(
      () => Uri.parse('https://my.app.com'),
    );

    final decision = handler(
      location: 'https://app.com/page',
      properties: const {},
      initialized: true,
    );

    expect(decision, isNull);
  });

  test('BrowserTab handler matches external http(s) hosts', () {
    final handler = browserTabRouteDecisionHandler(
      () => Uri.parse('https://my.app.com'),
    );

    final decision = handler(
      location: 'https://external.com/page',
      properties: const {},
      initialized: true,
    );

    expect(decision, RouteDecision.external);
  });

  test('BrowserTab handler ignores non-http schemes', () {
    final handler = browserTabRouteDecisionHandler(
      () => Uri.parse('https://my.app.com'),
    );

    final decision = handler(
      location: 'sms:555-555-5555',
      properties: const {},
      initialized: true,
    );

    expect(decision, isNull);
  });

  test('SystemNavigation handler matches external hosts', () {
    final handler = systemNavigationRouteDecisionHandler(
      () => Uri.parse('https://my.app.com'),
    );

    final decision = handler(
      location: 'https://external.com/page',
      properties: const {},
      initialized: true,
    );

    expect(decision, RouteDecision.external);
  });

  test('SystemNavigation handler matches non-http schemes', () {
    final handler = systemNavigationRouteDecisionHandler(
      () => Uri.parse('https://my.app.com'),
    );

    final decision = handler(
      location: 'sms:555-555-5555',
      properties: const {},
      initialized: true,
    );

    expect(decision, RouteDecision.external);
  });
}
