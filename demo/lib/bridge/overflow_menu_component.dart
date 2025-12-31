import 'package:flutter/foundation.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

class OverflowActionState {
  final String label;
  final VoidCallback onPressed;

  const OverflowActionState({required this.label, required this.onPressed});
}

class DemoOverflowMenuComponent extends BridgeComponent {
  final void Function(OverflowActionState state) onChanged;

  DemoOverflowMenuComponent({required this.onChanged});

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
    onChanged(
      OverflowActionState(label: label, onPressed: () => replyTo('connect')),
    );
  }
}
