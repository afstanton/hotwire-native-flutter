import 'package:flutter/material.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

import 'demo_actions.dart';
import 'form_component.dart';
import 'menu_component.dart';
import 'overflow_menu_component.dart';

class DemoBridgeDestination extends BridgeDestination {
  final GlobalKey<NavigatorState> navigatorKey;
  final DemoActionController actions;

  DemoBridgeDestination({
    required this.navigatorKey,
    required this.actions,
  });

  BuildContext? get context => navigatorKey.currentContext;

  void setFormAction(FormActionState? state) {
    actions.formAction.value = state;
  }

  void setOverflowAction(OverflowActionState? state) {
    actions.overflowAction.value = state;
  }

  void showMenu({
    required String title,
    required List<DemoMenuItem> items,
    required void Function(int index) onSelected,
  }) {
    final context = this.context;
    if (context == null) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
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
                    onSelected(item.index);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
