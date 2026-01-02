import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';
import 'package:hotwire_native/bridge/demo_actions.dart';
import 'package:hotwire_native/bridge/demo_bridge_destination.dart';
import 'package:hotwire_native/bridge/form_component.dart';
import 'package:hotwire_native/bridge/overflow_menu_component.dart';

void main() {
  test('Form component configures submit action and replies', () {
    final bridge = Bridge();
    final actions = DemoActionController();
    final navigatorKey = GlobalKey<NavigatorState>();
    final destination = DemoBridgeDestination(
      navigatorKey: navigatorKey,
      actions: actions,
    );
    BridgeMessage? replied;

    final delegate = BridgeDelegate(
      location: 'https://example.com',
      destination: destination,
      componentFactories: [DemoFormComponentFactory()],
      bridge: bridge,
    );

    bridge.replyHandler = (message) => replied = message;
    bridge.activate();
    delegate.onViewDidLoad();

    bridge.handleMessage({
      'id': '1',
      'component': 'form',
      'event': 'connect',
      'metadata': {'url': 'https://example.com'},
      'data': {'submitTitle': 'Save'},
    });

    final actionState = actions.formAction.value;
    expect(actionState, isNotNull);
    expect(actionState?.title, 'Save');
    expect(actionState?.enabled, isTrue);

    actionState?.onPressed();
    expect(replied?.event, 'connect');
  });

  test('Form component toggles enabled state', () {
    final bridge = Bridge();
    final actions = DemoActionController();
    final navigatorKey = GlobalKey<NavigatorState>();
    final destination = DemoBridgeDestination(
      navigatorKey: navigatorKey,
      actions: actions,
    );

    final delegate = BridgeDelegate(
      location: 'https://example.com',
      destination: destination,
      componentFactories: [DemoFormComponentFactory()],
      bridge: bridge,
    );

    bridge.activate();
    delegate.onViewDidLoad();

    bridge.handleMessage({
      'id': '1',
      'component': 'form',
      'event': 'connect',
      'metadata': {'url': 'https://example.com'},
      'data': {'submitTitle': 'Save'},
    });

    bridge.handleMessage({
      'id': '2',
      'component': 'form',
      'event': 'submitDisabled',
      'metadata': {'url': 'https://example.com'},
      'data': {},
    });

    expect(actions.formAction.value?.enabled, isFalse);
  });

  test('Overflow menu component configures action and replies', () {
    final bridge = Bridge();
    final actions = DemoActionController();
    final navigatorKey = GlobalKey<NavigatorState>();
    final destination = DemoBridgeDestination(
      navigatorKey: navigatorKey,
      actions: actions,
    );
    BridgeMessage? replied;

    final delegate = BridgeDelegate(
      location: 'https://example.com',
      destination: destination,
      componentFactories: [DemoOverflowMenuComponentFactory()],
      bridge: bridge,
    );

    bridge.replyHandler = (message) => replied = message;
    bridge.activate();
    delegate.onViewDidLoad();

    bridge.handleMessage({
      'id': '1',
      'component': 'overflow-menu',
      'event': 'connect',
      'metadata': {'url': 'https://example.com'},
      'data': {'label': 'More'},
    });

    final actionState = actions.overflowAction.value;
    expect(actionState, isNotNull);
    expect(actionState?.label, 'More');

    actionState?.onPressed();
    expect(replied?.event, 'connect');
  });
}
