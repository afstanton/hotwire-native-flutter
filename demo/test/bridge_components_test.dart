import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';
import 'package:hotwire_native/bridge/form_component.dart';
import 'package:hotwire_native/bridge/overflow_menu_component.dart';

void main() {
  test('Form component configures submit action and replies', () {
    final bridge = Bridge();
    FormActionState? actionState;
    BridgeMessage? replied;

    final component = DemoFormComponent(
      onChanged: (state) => actionState = state,
    );

    bridge.register(component);
    bridge.replyHandler = (message) => replied = message;
    bridge.activate();

    bridge.handleMessage({
      'id': '1',
      'component': 'form',
      'event': 'connect',
      'data': {'submitTitle': 'Save'},
    });

    expect(actionState, isNotNull);
    expect(actionState?.title, 'Save');
    expect(actionState?.enabled, isTrue);

    actionState?.onPressed();
    expect(replied?.event, 'connect');
  });

  test('Form component toggles enabled state', () {
    final bridge = Bridge();
    FormActionState? actionState;

    final component = DemoFormComponent(
      onChanged: (state) => actionState = state,
    );

    bridge.register(component);
    bridge.activate();

    bridge.handleMessage({
      'id': '1',
      'component': 'form',
      'event': 'connect',
      'data': {'submitTitle': 'Save'},
    });

    bridge.handleMessage({
      'id': '2',
      'component': 'form',
      'event': 'submitDisabled',
      'data': {},
    });

    expect(actionState?.enabled, isFalse);
  });

  test('Overflow menu component configures action and replies', () {
    final bridge = Bridge();
    OverflowActionState? actionState;
    BridgeMessage? replied;

    final component = DemoOverflowMenuComponent(
      onChanged: (state) => actionState = state,
    );

    bridge.register(component);
    bridge.replyHandler = (message) => replied = message;
    bridge.activate();

    bridge.handleMessage({
      'id': '1',
      'component': 'overflow-menu',
      'event': 'connect',
      'data': {'label': 'More'},
    });

    expect(actionState, isNotNull);
    expect(actionState?.label, 'More');

    actionState?.onPressed();
    expect(replied?.event, 'connect');
  });
}
