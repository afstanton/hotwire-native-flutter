import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

class TestComponent extends BridgeComponent {
  final List<String> events = [];
  int startCalls = 0;
  int stopCalls = 0;

  @override
  String get name => 'test';

  @override
  void onReceive(BridgeMessage message) {
    events.add(message.event);
  }

  @override
  void onStart() {
    startCalls += 1;
  }

  @override
  void onStop() {
    stopCalls += 1;
  }
}

class TestFactory extends BridgeComponentFactory<TestComponent> {
  @override
  String get name => 'factory';

  @override
  TestComponent create() => TestComponent();
}

void main() {
  tearDown(() {
    Hotwire().config.bridgeJsonEncoder = null;
    Hotwire().config.bridgeJsonDecoder = null;
    Hotwire().config.bridgeJsonErrorHandler = null;
  });

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

  test('BridgeMessage encodes data as object in map', () {
    final message = BridgeMessage(
      id: '1',
      component: 'test',
      event: 'update',
      metadata: const BridgeMessageMetadata(url: 'https://example.com'),
      jsonData: '{"title":"Hello"}',
    );

    final payload = message.toMap();

    expect(payload['data'], isA<Map>());
    expect((payload['data'] as Map)['title'], 'Hello');
  });

  test('BridgeMessage reports decode errors', () {
    Object? error;
    Hotwire().config.bridgeJsonErrorHandler = (err) => error = err;

    final message = BridgeMessage(
      id: '1',
      component: 'test',
      event: 'connect',
      metadata: null,
      jsonData: '{bad',
    );

    final data = message.data<Map<String, dynamic>>();
    expect(data, isNull);
    expect(error, isNotNull);
  });

  test('BridgeMessage reports encoder errors', () {
    Object? error;
    Hotwire().config.bridgeJsonErrorHandler = (err) => error = err;
    Hotwire().config.bridgeJsonEncoder = (_) => throw StateError('bad');

    final message = BridgeMessage(
      id: '1',
      component: 'test',
      event: 'update',
      metadata: null,
      jsonData: '{}',
    );

    final replaced = message.replacingData({'value': 1});
    expect(replaced.jsonData, '{}');
    expect(error, isNotNull);
  });

  test('Bridge dispatches to registered components', () {
    final bridge = Bridge();
    final component = TestComponent();
    bridge.register(component);
    bridge.activate();

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
    bridge.activate();

    final handled = bridge.handleMessage({
      'id': '1',
      'component': 'factory',
      'event': 'display',
      'data': '{}',
    });

    expect(handled, isTrue);
    expect(bridge.registeredComponentNames(), contains('factory'));
  });

  test('Bridge notifies component lifecycle on activate/deactivate', () {
    final bridge = Bridge();
    final component = TestComponent();
    bridge.register(component);

    bridge.activate();
    expect(component.startCalls, 1);

    bridge.deactivate();
    expect(component.stopCalls, 1);
  });

  test('BridgeComponent replies using cached messages', () {
    final bridge = Bridge();
    final component = TestComponent();
    BridgeMessage? replied;
    bridge.replyHandler = (message) {
      replied = message;
    };
    bridge.register(component);
    bridge.activate();

    bridge.handleMessage({
      'id': '99',
      'component': 'test',
      'event': 'connected',
      'data': {'status': 'ok'},
    });

    final didReply = component.replyTo('connected');

    expect(didReply, isTrue);
    expect(replied?.event, 'connected');
    expect(replied?.id, '99');
  });

  test('BridgeComponent async reply returns false when missing message', () async {
    final component = TestComponent();

    final didReply = await component.replyToAsync('missing');

    expect(didReply, isFalse);
  });

  test('BridgeComponent async reply uses delegate', () async {
    final bridge = Bridge();
    final component = TestComponent();
    BridgeMessage? replied;
    bridge.replyHandler = (message) {
      replied = message;
    };
    bridge.register(component);
    bridge.activate();

    bridge.handleMessage({
      'id': '1',
      'component': 'test',
      'event': 'connected',
      'data': {'status': 'ok'},
    });

    final didReply = await component.replyToAsync('connected');

    expect(didReply, isTrue);
    expect(replied?.event, 'connected');
  });
}
