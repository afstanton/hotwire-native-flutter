import '../turbo/visit/visit_options.dart';
import 'navigation_stack.dart';

class NavigationHost {
  final String id;
  final NavigationStack stack;

  NavigationHost({required this.id, required this.stack});
}

class NavigationHostRegistry {
  final Map<String, NavigationHost> _hosts = {};
  String? _activeHostId;

  NavigationHost? get activeHost =>
      _activeHostId == null ? null : _hosts[_activeHostId];

  String? get activeHostId => _activeHostId;

  NavigationHost ensureHost({
    required String id,
    required String startLocation,
  }) {
    return _hosts.putIfAbsent(
      id,
      () => NavigationHost(
        id: id,
        stack: NavigationStack(startLocation: startLocation),
      ),
    );
  }

  void setActive(String id) {
    if (_hosts.containsKey(id)) {
      _activeHostId = id;
    }
  }

  NavigationInstruction? route({
    required String hostId,
    required String location,
    required Map<String, dynamic> properties,
    VisitOptions? options,
  }) {
    final host = _hosts[hostId];
    if (host == null) {
      return null;
    }
    return host.stack.route(
      location: location,
      properties: properties,
      options: options,
    );
  }
}
