import 'package:flutter/foundation.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

import 'demo_bridge_destination.dart';

class OverflowActionState {
  final String label;
  final VoidCallback onPressed;

  const OverflowActionState({required this.label, required this.onPressed});
}

class DemoOverflowMenuComponent extends BridgeComponent {
  @override
  String get name => 'overflow-menu';

  @override
  void onReceive(BridgeMessage message) {
    if (message.event != 'connect') {
      return;
    }
    final data = message.data<Map<String, dynamic>>();
    final label = data?['label']?.toString();
    if (label == null || label.isEmpty) {
      return;
    }
    final destination = this.destination;
    if (destination is! DemoBridgeDestination) {
      return;
    }
    destination.setOverflowAction(
      OverflowActionState(label: label, onPressed: () => replyTo('connect')),
    );
  }
}

class DemoOverflowMenuComponentFactory
    extends BridgeComponentFactory<DemoOverflowMenuComponent> {
  @override
  String get name => 'overflow-menu';

  @override
  DemoOverflowMenuComponent create() => DemoOverflowMenuComponent();
}
