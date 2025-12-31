import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

class TestComponent extends BridgeComponent {
  final List<String> events = [];

  @override
  String get name => 'test';

  @override
  void onReceive(BridgeMessage message) {
    events.add(message.event);
  }
}

class TestFactory extends BridgeComponentFactory<TestComponent> {
  @override
  String get name => 'factory';

  @override
  TestComponent create() => TestComponent();
}

void main() {
  test('BridgeMessage replaces data with encoder', () {
    Hotwire().config.bridgeJsonEncoder = (data) => {'wrapped': data};

    final message = BridgeMessage(
      id: '1',
      component: 'test',
      event: 'connect',
      metadata: null,
      jsonData: '{}',
    );

    final replaced = message.replacingData({'value': 1});
    expect(replaced.jsonData, '{"wrapped":{"value":1}}');
  });

  test('BridgeMessage accepts map data payloads', () {
    final message = BridgeMessage.fromMap({
      'id': '1',
      'component': 'test',
      'event': 'connect',
      'data': {'title': 'Hello'},
    });

    final data = message.data<Map<String, dynamic>>();
    expect(data?['title'], 'Hello');
  });

  test('Bridge dispatches to registered components', () {
    final bridge = Bridge();
    final component = TestComponent();
    bridge.register(component);

    final handled = bridge.handleMessage({
      'id': '1',
      'component': 'test',
      'event': 'connect',
      'data': '{}',
    });

    expect(handled, isTrue);
    expect(component.events, ['connect']);
  });

  test('Bridge builds components using factories', () {
    final bridge = Bridge();
    bridge.registerFactory(TestFactory());

    final handled = bridge.handleMessage({
      'id': '1',
      'component': 'factory',
      'event': 'display',
      'data': '{}',
    });

    expect(handled, isTrue);
    expect(bridge.registeredComponentNames(), contains('factory'));
  });
}
