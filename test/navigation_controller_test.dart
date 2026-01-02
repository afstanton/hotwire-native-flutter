import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

class _ExecutorSpy implements NavigationExecutor {
  final List<String> calls = [];

  @override
  void clearAll(String location) => calls.add('clearAll:$location');

  @override
  void dismissModal() => calls.add('dismissModal');

  @override
  void pop({required bool isModal}) => calls.add('pop:${isModal ? 'modal' : 'main'}');

  @override
  void presentModal() => calls.add('presentModal');

  @override
  void push(String location, {required bool isModal}) =>
      calls.add('push:${isModal ? 'modal' : 'main'}:$location');

  @override
  void refresh(String location, {required bool isModal}) =>
      calls.add('refresh:${isModal ? 'modal' : 'main'}:$location');

  @override
  void replace(String location, {required bool isModal}) =>
      calls.add('replace:${isModal ? 'modal' : 'main'}:$location');

  @override
  void replaceRoot(String location) => calls.add('replaceRoot:$location');
}

void main() {
  test('NavigationHierarchyController pushes main routes', () {
    final stack = NavigationStack(startLocation: 'https://example.com');
    final executor = _ExecutorSpy();
    final controller = NavigationHierarchyController(
      stack: stack,
      executor: executor,
    );

    controller.route(
      const NavigationRequest(
        location: 'https://example.com/features',
        properties: {},
      ),
    );

    expect(executor.calls, ['push:main:https://example.com/features']);
  });

  test('NavigationHierarchyController presents modal routes', () {
    final stack = NavigationStack(startLocation: 'https://example.com');
    final executor = _ExecutorSpy();
    final controller = NavigationHierarchyController(
      stack: stack,
      executor: executor,
    );

    controller.route(
      const NavigationRequest(
        location: 'https://example.com/modal/new',
        properties: {'context': 'modal'},
      ),
    );

    expect(executor.calls, [
      'push:modal:https://example.com/modal/new',
      'presentModal',
    ]);
  });

  test('NavigationHierarchyController clears all on clear_all', () {
    final stack = NavigationStack(startLocation: 'https://example.com');
    final executor = _ExecutorSpy();
    final controller = NavigationHierarchyController(
      stack: stack,
      executor: executor,
    );

    controller.route(
      const NavigationRequest(
        location: 'https://example.com/clear',
        properties: {'presentation': 'clear_all'},
      ),
    );

    expect(executor.calls, ['clearAll:https://example.com/clear']);
  });

  test('NavigationHierarchyController refreshes on pop', () {
    final stack = NavigationStack(startLocation: 'https://example.com');
    final executor = _ExecutorSpy();
    final controller = NavigationHierarchyController(
      stack: stack,
      executor: executor,
    );

    controller.route(
      const NavigationRequest(
        location: 'https://example.com/modal/new',
        properties: {'context': 'modal'},
      ),
    );
    controller.route(
      const NavigationRequest(
        location: 'https://example.com/pop',
        properties: {'presentation': 'pop'},
      ),
    );

    expect(executor.calls, [
      'push:modal:https://example.com/modal/new',
      'presentModal',
      'dismissModal',
      'pop:modal',
      'refresh:modal:https://example.com',
    ]);
  });
}
