import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

class TestDestination extends BridgeDestination {
  int initializedCount = 0;

  @override
  void onBridgeComponentInitialized(BridgeComponent component) {
    initializedCount += 1;
  }
}

class TestComponent extends BridgeComponent {
  int receivedCount = 0;
  int willAppearCount = 0;
  int didAppearCount = 0;
  int willDisappearCount = 0;
  int didDisappearCount = 0;

  @override
  String get name => 'test';

  @override
  void onReceive(BridgeMessage message) {
    receivedCount += 1;
  }

  @override
  void onViewWillAppear() {
    willAppearCount += 1;
  }

  @override
  void onViewDidAppear() {
    didAppearCount += 1;
  }

  @override
  void onViewWillDisappear() {
    willDisappearCount += 1;
  }

  @override
  void onViewDidDisappear() {
    didDisappearCount += 1;
  }
}

class TestFactory extends BridgeComponentFactory<TestComponent> {
  @override
  String get name => 'test';

  @override
  TestComponent create() => TestComponent();
}

BridgeMessage _message(String url) {
  return BridgeMessage(
    id: '1',
    component: 'test',
    event: 'connect',
    metadata: BridgeMessageMetadata(url: url),
    jsonData: '{}',
  );
}

void main() {
  test('BridgeDelegate initializes components and notifies destination', () {
    final destination = TestDestination();
    final delegate = BridgeDelegate(
      location: 'https://example.com',
      destination: destination,
      componentFactories: [TestFactory()],
    );

    delegate.onViewDidLoad();
    delegate.bridgeDidReceiveMessage(_message('https://example.com'));

    final component = delegate.component<TestComponent>();
    expect(component, isNotNull);
    expect(destination.initializedCount, 1);
    expect(component?.destination, destination);
    expect(component?.delegate, delegate);
  });

  test('BridgeDelegate ignores messages when inactive', () {
    final destination = TestDestination();
    final delegate = BridgeDelegate(
      location: 'https://example.com',
      destination: destination,
      componentFactories: [TestFactory()],
    );

    delegate.bridgeDidReceiveMessage(_message('https://example.com'));

    expect(delegate.component<TestComponent>(), isNull);
    expect(destination.initializedCount, 0);
  });

  test('BridgeDelegate ignores messages for mismatched locations', () {
    final destination = TestDestination();
    final delegate = BridgeDelegate(
      location: 'https://example.com',
      destination: destination,
      componentFactories: [TestFactory()],
    );

    delegate.onViewDidLoad();
    delegate.bridgeDidReceiveMessage(_message('https://other.example.com'));

    expect(delegate.component<TestComponent>(), isNull);
    expect(destination.initializedCount, 0);
  });

  test('BridgeDelegate forwards reply to bridge', () {
    final destination = TestDestination();
    final bridge = Bridge();
    BridgeMessage? replied;
    bridge.replyHandler = (message) {
      replied = message;
    };
    final delegate = BridgeDelegate(
      location: 'https://example.com',
      destination: destination,
      componentFactories: const <BridgeComponentFactory>[],
      bridge: bridge,
    );

    final didReply = delegate.replyWith(_message('https://example.com'));

    expect(didReply, isTrue);
    expect(replied?.id, '1');
  });

  test('BridgeDelegate relays lifecycle callbacks to components', () {
    final destination = TestDestination();
    final delegate = BridgeDelegate(
      location: 'https://example.com',
      destination: destination,
      componentFactories: [TestFactory()],
    );

    delegate.onViewDidLoad();
    delegate.bridgeDidReceiveMessage(_message('https://example.com'));
    final component = delegate.component<TestComponent>();

    delegate.onViewWillAppear();
    delegate.onViewDidAppear();
    delegate.onViewWillDisappear();
    delegate.onViewDidDisappear();

    expect(component?.willAppearCount, 1);
    expect(component?.didAppearCount, 1);
    expect(component?.willDisappearCount, 1);
    expect(component?.didDisappearCount, 1);
  });
}
