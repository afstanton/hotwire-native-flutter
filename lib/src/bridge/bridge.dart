import '../hotwire.dart';
import 'bridge_component.dart';
import 'bridge_component_factory.dart';
import 'bridge_delegate.dart';
import 'message.dart';

typedef BridgeMessageHandler = bool Function(BridgeMessage message);

class Bridge implements BridgeDelegate {
  final Map<String, BridgeComponent> _components = {};
  final Map<String, BridgeComponentFactory> _factories = {};
  bool _isActive = false;

  BridgeMessageHandler? messageHandler;
  void Function(BridgeMessage message)? replyHandler;

  void register(BridgeComponent component) {
    component.delegate = this;
    _components[component.name] = component;
    if (_isActive) {
      component.didStart();
    }
  }

  void unregister(String name) {
    final component = _components.remove(name);
    if (_isActive) {
      component?.didStop();
    }
  }

  void registerFactory(BridgeComponentFactory factory) {
    _factories[factory.name] = factory;
  }

  void unregisterFactory(String name) {
    _factories.remove(name);
  }

  List<String> registeredComponentNames() {
    return {..._components.keys, ..._factories.keys}.toList();
  }

  void activate() {
    if (_isActive) {
      return;
    }
    _isActive = true;
    for (final component in _components.values) {
      component.didStart();
    }
  }

  void deactivate() {
    if (!_isActive) {
      return;
    }
    for (final component in _components.values) {
      component.didStop();
    }
    _isActive = false;
  }

  bool handleMessage(Map<String, dynamic> payload) {
    if (!_isActive) {
      return false;
    }

    final message = BridgeMessage.fromMap(payload);
    if (messageHandler?.call(message) == true) {
      return true;
    }

    final componentName = message.component;
    final existing = _components[componentName];
    if (existing != null) {
      existing.didReceive(message);
      return true;
    }

    final factory = _factories[componentName];
    if (factory != null) {
      final component = factory.create();
      component.delegate = this;
      _components[componentName] = component;
      if (_isActive) {
        component.didStart();
      }
      component.didReceive(message);
      return true;
    }

    return false;
  }

  String buildUserAgent({String platformTag = 'Flutter'}) {
    final components = registeredComponentNames();
    return Hotwire().config.buildUserAgent(
      platformTag: platformTag,
      components: components,
    );
  }

  @override
  @override
  bool replyWith(BridgeMessage message) {
    if (replyHandler == null) {
      return false;
    }
    replyHandler?.call(message);
    return true;
  }
}
