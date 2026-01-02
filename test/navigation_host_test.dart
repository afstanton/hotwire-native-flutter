import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

void main() {
  test('NavigationHostRegistry registers and activates hosts', () {
    final registry = NavigationHostRegistry();
    registry.ensureHost(id: 'main', startLocation: 'https://example.com');
    registry.ensureHost(
      id: 'modal',
      startLocation: 'https://example.com/modal',
    );

    registry.setActive('main');
    expect(registry.activeHostId, 'main');
    expect(registry.activeHost, isNotNull);
  });

  test('NavigationHostRegistry routes using host stack', () {
    final registry = NavigationHostRegistry();
    registry.ensureHost(id: 'main', startLocation: 'https://example.com');

    final instruction = registry.route(
      hostId: 'main',
      location: 'https://example.com/features',
      properties: const {},
    );

    expect(instruction, isNotNull);
    expect(instruction?.action, NavigationAction.push);
  });
}
