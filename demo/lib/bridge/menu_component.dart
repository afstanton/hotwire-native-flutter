import 'package:flutter/material.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

class DemoMenuComponent extends BridgeComponent {
  final State state;

  DemoMenuComponent({required this.state});

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

  List<_MenuItem> _parseItems(dynamic rawItems) {
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
          return _MenuItem(title: title, index: parsedIndex);
        })
        .whereType<_MenuItem>()
        .toList();
  }

  void _showMenu(String title, List<_MenuItem> items) {
    if (!state.mounted) {
      return;
    }
    showModalBottomSheet<void>(
      context: state.context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(title)),
              for (final item in items)
                ListTile(
                  title: Text(item.title),
                  onTap: () {
                    Navigator.of(context).pop();
                    replyToData('display', {'selectedIndex': item.index});
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final String title;
  final int index;

  const _MenuItem({required this.title, required this.index});
}
