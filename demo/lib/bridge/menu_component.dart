import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

import 'demo_bridge_destination.dart';

class DemoMenuComponent extends BridgeComponent {
  @override
  String get name => 'menu';

  @override
  void onReceive(BridgeMessage message) {
    if (message.event != 'display') {
      return;
    }
    final data = message.data<Map<String, dynamic>>();
    if (data == null) {
      return;
    }
    final title = data['title']?.toString() ?? '';
    final items = _parseItems(data['items']);
    if (title.isEmpty || items.isEmpty) {
      return;
    }
    _showMenu(title, items);
  }

  List<DemoMenuItem> _parseItems(dynamic rawItems) {
    if (rawItems is! List) {
      return const [];
    }
    return rawItems
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          final title = map['title']?.toString();
          final index = map['index'];
          if (title == null || title.isEmpty) {
            return null;
          }
          final parsedIndex = index is int ? index : int.tryParse('$index');
          if (parsedIndex == null) {
            return null;
          }
          return DemoMenuItem(title: title, index: parsedIndex);
        })
        .whereType<DemoMenuItem>()
        .toList();
  }

  void _showMenu(String title, List<DemoMenuItem> items) {
    final destination = this.destination;
    if (destination is! DemoBridgeDestination) {
      return;
    }
    destination.showMenu(
      title: title,
      items: items,
      onSelected: (index) {
        replyToData('display', {'selectedIndex': index});
      },
    );
  }
}

class DemoMenuItem {
  final String title;
  final int index;

  const DemoMenuItem({required this.title, required this.index});
}

class DemoMenuComponentFactory extends BridgeComponentFactory<DemoMenuComponent> {
  @override
  String get name => 'menu';

  @override
  DemoMenuComponent create() => DemoMenuComponent();
}
