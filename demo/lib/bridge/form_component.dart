import 'package:flutter/foundation.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

import 'demo_bridge_destination.dart';

class FormActionState {
  final String title;
  final bool enabled;
  final VoidCallback onPressed;

  const FormActionState({
    required this.title,
    required this.enabled,
    required this.onPressed,
  });

  FormActionState copyWith({bool? enabled}) {
    return FormActionState(
      title: title,
      enabled: enabled ?? this.enabled,
      onPressed: onPressed,
    );
  }
}

class DemoFormComponent extends BridgeComponent {
  @override
  String get name => 'form';

  String? _submitTitle;
  bool _enabled = true;

  @override
  void onReceive(BridgeMessage message) {
    switch (message.event) {
      case 'connect':
        _handleConnect(message);
        break;
      case 'submitEnabled':
        _setEnabled(true);
        break;
      case 'submitDisabled':
        _setEnabled(false);
        break;
      default:
        break;
    }
  }

  void _handleConnect(BridgeMessage message) {
    final data = message.data<Map<String, dynamic>>();
    final title = data?['submitTitle']?.toString();
    if (title == null || title.isEmpty) {
      return;
    }
    _submitTitle = title;
    _enabled = true;
    _notify();
  }

  void _setEnabled(bool enabled) {
    if (_submitTitle == null) {
      return;
    }
    _enabled = enabled;
    _notify();
  }

  void _notify() {
    final destination = this.destination;
    if (destination is! DemoBridgeDestination) {
      return;
    }
    final title = _submitTitle;
    if (title == null) {
      return;
    }
    destination.setFormAction(
      FormActionState(
        title: title,
        enabled: _enabled,
        onPressed: () => replyTo('connect'),
      ),
    );
  }
}

class DemoFormComponentFactory extends BridgeComponentFactory<DemoFormComponent> {
  @override
  String get name => 'form';

  @override
  DemoFormComponent create() => DemoFormComponent();
}
