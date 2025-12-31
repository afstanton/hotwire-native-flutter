import '../hotwire.dart';
import 'bridge_component.dart';
import 'bridge_component_factory.dart';
import 'bridge_delegate.dart';
import 'message.dart';

typedef BridgeMessageHandler = bool Function(BridgeMessage message);

class Bridge implements BridgeDelegate {
  final Map<String, BridgeComponent> _components = {};
  final Map<String, BridgeComponentFactory> _factories = {};

  BridgeMessageHandler? messageHandler;
  void Function(BridgeMessage originalMessage, Map<String, dynamic> data)?
  replyHandler;

  void register(BridgeComponent component) {
    component.delegate = this;
    _components[component.name] = component;
  }

  void unregister(String name) {
    _components.remove(name);
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

  bool handleMessage(Map<String, dynamic> payload) {
    final message = BridgeMessage.fromMap(payload);
    if (messageHandler?.call(message) == true) {
      return true;
    }

    final componentName = message.component;
    final existing = _components[componentName];
    if (existing != null) {
      existing.didReceive(message);
      existing.onReceive(message);
      return true;
    }

    final factory = _factories[componentName];
    if (factory != null) {
      final component = factory.create();
      component.delegate = this;
      _components[componentName] = component;
      component.didReceive(message);
      component.onReceive(message);
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
  void replyWith(BridgeMessage originalMessage, Map<String, dynamic> data) {
    replyHandler?.call(originalMessage, data);
  }
}
