import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

void main() {
  test('NavigationStack pushes on main stack by default', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');

    final instruction = stack.route(
      location: 'https://example.com/features',
      properties: const {},
    );

    expect(instruction.mode, NavigationMode.inContext);
    expect(instruction.targetStack, NavigationStackType.main);
    expect(instruction.action, NavigationAction.push);
    expect(stack.state.mainStack, [
      'https://example.com/home',
      'https://example.com/features',
    ]);
  });

  test('NavigationStack replaces when routing to same location', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');
    stack.route(location: 'https://example.com/features', properties: const {});

    final instruction = stack.route(
      location: 'https://example.com/features',
      properties: const {},
    );

    expect(instruction.action, NavigationAction.replace);
    expect(stack.state.mainStack, [
      'https://example.com/home',
      'https://example.com/features',
    ]);
  });

  test('NavigationStack routes to modal context', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');

    final instruction = stack.route(
      location: 'https://example.com/modal/new',
      properties: const {'context': 'modal'},
    );

    expect(instruction.mode, NavigationMode.toModal);
    expect(instruction.targetStack, NavigationStackType.modal);
    expect(instruction.action, NavigationAction.push);
    expect(stack.state.modalStack, ['https://example.com/modal/new']);
  });

  test('NavigationStack dismisses modal when routing to main context', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');
    stack.route(
      location: 'https://example.com/modal/new',
      properties: const {'context': 'modal'},
    );

    final instruction = stack.route(
      location: 'https://example.com/features',
      properties: const {},
    );

    expect(instruction.mode, NavigationMode.toMain);
    expect(instruction.didDismissModal, isTrue);
    expect(stack.state.modalStack, isEmpty);
    expect(stack.state.mainStack.last, 'https://example.com/features');
  });

  test('NavigationStack forbids modal replaceRoot presentation', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');

    expect(
      () => stack.route(
        location: 'https://example.com/modal/new',
        properties: const {'context': 'modal', 'presentation': 'replace_root'},
      ),
      throwsA(isA<NavigationStackException>()),
    );
  });

  test('NavigationStack refreshes previous location', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');
    stack.route(location: 'https://example.com/features', properties: const {});

    final instruction = stack.route(
      location: 'https://example.com/refresh_historical_location',
      properties: const {'presentation': 'refresh'},
    );

    expect(instruction.action, NavigationAction.refresh);
    expect(instruction.refreshLocation, 'https://example.com/home');
    expect(stack.state.mainStack, ['https://example.com/home']);
  });

  test('NavigationStack reset restores start location', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');
    stack.route(location: 'https://example.com/features', properties: const {});

    stack.reset();

    expect(stack.state.mainStack, ['https://example.com/home']);
    expect(stack.state.modalStack, isEmpty);
  });

  test('NavigationStack pop removes modal top when modal stack present', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');
    stack.route(
      location: 'https://example.com/modal/new',
      properties: const {'context': 'modal'},
    );
    stack.route(
      location: 'https://example.com/modal/next',
      properties: const {'context': 'modal'},
    );

    final instruction = stack.route(
      location: 'https://example.com/pop',
      properties: const {'presentation': 'pop'},
    );

    expect(instruction.action, NavigationAction.pop);
    expect(stack.state.modalStack, ['https://example.com/modal/new']);
  });

  test('NavigationStack pop refreshes main when dismissing modal', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');
    stack.route(
      location: 'https://example.com/modal/new',
      properties: const {'context': 'modal'},
    );

    final instruction = stack.route(
      location: 'https://example.com/pop',
      properties: const {'presentation': 'pop'},
    );

    expect(instruction.action, NavigationAction.pop);
    expect(instruction.refreshLocation, 'https://example.com/home');
    expect(stack.state.modalStack, isEmpty);
  });

  test('NavigationStack clearAll resets to new root', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');
    stack.route(location: 'https://example.com/features', properties: const {});

    final instruction = stack.route(
      location: 'https://example.com/new-home',
      properties: const {'presentation': 'clear_all'},
    );

    expect(instruction.action, NavigationAction.clearAll);
    expect(stack.state.mainStack, ['https://example.com/new-home']);
    expect(stack.state.modalStack, isEmpty);
  });

  test('NavigationStack replaceRoot resets main stack', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');
    stack.route(location: 'https://example.com/features', properties: const {});

    final instruction = stack.route(
      location: 'https://example.com/new-root',
      properties: const {'presentation': 'replace_root'},
    );

    expect(instruction.action, NavigationAction.replaceRoot);
    expect(stack.state.mainStack, ['https://example.com/new-root']);
  });

  test('NavigationStack treats replace action as replace presentation', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');

    final instruction = stack.route(
      location: 'https://example.com/home',
      properties: const {},
      options: const VisitOptions(action: VisitAction.replace),
    );

    expect(instruction.action, NavigationAction.replace);
    expect(stack.state.mainStack, ['https://example.com/home']);
  });

  test('NavigationStack replaces when query string presentation is replace', () {
    final stack = NavigationStack(startLocation: 'https://example.com/items');
    stack.route(
      location: 'https://example.com/items?filter=one',
      properties: const {'query_string_presentation': 'replace'},
    );

    final instruction = stack.route(
      location: 'https://example.com/items?filter=two',
      properties: const {'query_string_presentation': 'replace'},
    );

    expect(instruction.action, NavigationAction.replace);
    expect(stack.state.mainStack.length, 1);
    expect(stack.state.mainStack.last, 'https://example.com/items?filter=two');
  });

  test('NavigationStack clears modal stack for historical locations', () {
    final stack = NavigationStack(startLocation: 'https://example.com/home');
    stack.route(
      location: 'https://example.com/modal/new',
      properties: const {'context': 'modal'},
    );

    final instruction = stack.route(
      location: 'https://example.com/recede_historical_location',
      properties: const {'historical_location': true, 'presentation': 'pop'},
    );

    expect(instruction.action, NavigationAction.pop);
    expect(stack.state.modalStack, isEmpty);
  });

  test(
    'NavigationStack refresh pops modal and refreshes main when single modal',
    () {
      final stack = NavigationStack(startLocation: 'https://example.com/home');
      stack.route(
        location: 'https://example.com/modal/new',
        properties: const {'context': 'modal'},
      );

      final instruction = stack.route(
        location: 'https://example.com/refresh_historical_location',
        properties: const {'presentation': 'refresh'},
      );

      expect(instruction.action, NavigationAction.refresh);
      expect(instruction.didDismissModal, isTrue);
      expect(instruction.refreshLocation, 'https://example.com/home');
      expect(stack.state.modalStack, isEmpty);
    },
  );
}
