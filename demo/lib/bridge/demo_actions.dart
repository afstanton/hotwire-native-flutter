import 'package:flutter/foundation.dart';

import 'form_component.dart';
import 'overflow_menu_component.dart';

class DemoActionController {
  final ValueNotifier<FormActionState?> formAction =
      ValueNotifier<FormActionState?>(null);
  final ValueNotifier<OverflowActionState?> overflowAction =
      ValueNotifier<OverflowActionState?>(null);
  final ValueNotifier<bool> showFormProgress = ValueNotifier<bool>(false);

  void dispose() {
    formAction.dispose();
    overflowAction.dispose();
    showFormProgress.dispose();
  }
}
