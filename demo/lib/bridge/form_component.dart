import 'package:flutter/foundation.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

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
  final void Function(FormActionState state) onChanged;

  DemoFormComponent({required this.onChanged});

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
    final title = _submitTitle;
    if (title == null) {
      return;
    }
    onChanged(
      FormActionState(
        title: title,
        enabled: _enabled,
        onPressed: () => replyTo('connect'),
      ),
    );
  }
}
