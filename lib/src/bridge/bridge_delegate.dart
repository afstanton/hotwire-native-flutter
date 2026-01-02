import 'bridge.dart';
import 'bridge_component.dart';
import 'bridge_component_factory.dart';
import 'bridge_reply_handler.dart';
import 'message.dart';

class BridgeDelegate implements BridgeReplyHandler {
  BridgeDelegate({
    required this.location,
    required this.destination,
    required List<BridgeComponentFactory> componentFactories,
    this.locationResolver,
    Bridge? bridge,
  }) : _componentFactories = List.unmodifiable(componentFactories) {
    if (bridge != null) {
      attachBridge(bridge);
    }
  }

  final String location;
  final BridgeDestination destination;
  final String Function()? locationResolver;
  final List<BridgeComponentFactory> _componentFactories;

  Bridge? _bridge;
  bool _destinationIsActive = false;
  final Map<String, BridgeComponent> _initializedComponents = {};

  Bridge? get bridge => _bridge;

  List<BridgeComponent> get activeComponents {
    if (!_destinationIsActive) {
      return const [];
    }
    return _initializedComponents.values.toList(growable: false);
  }

  String get resolvedLocation => locationResolver?.call() ?? location;

  void attachBridge(Bridge bridge) {
    _bridge = bridge;
    bridge.messageHandler = bridgeDidReceiveMessage;
    _registerFactories(bridge);
  }

  void detachBridge() {
    final bridge = _bridge;
    if (bridge != null && bridge.messageHandler == bridgeDidReceiveMessage) {
      bridge.messageHandler = null;
    }
    _bridge = null;
  }

  void webViewDidBecomeActive(Bridge bridge) {
    attachBridge(bridge);
  }

  void webViewDidBecomeDeactivated() {
    detachBridge();
  }

  void onWebViewAttached(Bridge bridge) {
    attachBridge(bridge);
  }

  void onWebViewDetached() {
    detachBridge();
  }

  void onColdBootPageStarted() {
    _bridge?.deactivate();
  }

  void onColdBootPageCompleted() {
    _bridge?.activate();
  }

  void onViewDidLoad() {
    _destinationIsActive = true;
    for (final component in activeComponents) {
      component.didViewDidLoad();
    }
  }

  void onViewWillAppear() {
    _destinationIsActive = true;
    for (final component in activeComponents) {
      component.didViewWillAppear();
    }
  }

  void onViewDidAppear() {
    _destinationIsActive = true;
    for (final component in activeComponents) {
      component.didViewDidAppear();
    }
  }

  void onViewWillDisappear() {
    for (final component in activeComponents) {
      component.didViewWillDisappear();
    }
  }

  void onViewDidDisappear() {
    for (final component in activeComponents) {
      component.didViewDidDisappear();
    }
    _destinationIsActive = false;
  }

  T? component<T extends BridgeComponent>() {
    for (final component in activeComponents) {
      if (component is T) {
        return component;
      }
    }
    return null;
  }

  void forEachComponent<T extends BridgeComponent>(void Function(T) action) {
    for (final component in activeComponents) {
      if (component is T) {
        action(component);
      }
    }
  }

  void bridgeDidInitialize() {
    final bridge = _bridge;
    if (bridge == null) {
      return;
    }
    _registerFactories(bridge);
  }

  bool bridgeDidReceiveMessage(BridgeMessage message) {
    final url = message.metadata?.url;
    if (!_destinationIsActive || url == null || url != resolvedLocation) {
      return true;
    }

    final component = _getOrCreateComponent(message.component);
    component?.didReceive(message);
    return true;
  }

  @override
  bool replyWith(BridgeMessage message) {
    final bridge = _bridge;
    if (bridge == null) {
      return false;
    }
    return bridge.replyWith(message);
  }

  void _registerFactories(Bridge bridge) {
    for (final factory in _componentFactories) {
      bridge.registerFactory(factory);
    }
  }

  BridgeComponent? _getOrCreateComponent(String name) {
    final existing = _initializedComponents[name];
    if (existing != null) {
      return existing;
    }

    final factory = _componentFactories.firstWhere(
      (factory) => factory.name == name,
      orElse: () => _MissingBridgeComponentFactory(name),
    );
    if (factory is _MissingBridgeComponentFactory) {
      return null;
    }

    final component = factory.create();
    component.delegate = this;
    component.destination = destination;
    _initializedComponents[name] = component;
    destination.onBridgeComponentInitialized(component);
    return component;
  }
}

class _MissingBridgeComponentFactory
    extends BridgeComponentFactory<BridgeComponent> {
  _MissingBridgeComponentFactory(this.missingName);

  final String missingName;

  @override
  String get name => missingName;

  @override
  BridgeComponent create() {
    throw StateError('Missing bridge component factory: $missingName');
  }
}
