import '../turbo/path_properties.dart';
import '../turbo/visit/visit_action.dart';
import '../turbo/visit/visit_options.dart';

enum NavigationStackType { main, modal }

enum NavigationMode { inContext, toModal, toMain }

enum NavigationAction {
  push,
  replace,
  pop,
  clearAll,
  replaceRoot,
  refresh,
  none,
}

class NavigationStackException implements Exception {
  final String message;

  const NavigationStackException(this.message);

  @override
  String toString() => message;
}

class NavigationInstruction {
  final NavigationMode mode;
  final NavigationStackType targetStack;
  final NavigationAction action;
  final bool didDismissModal;
  final String? refreshLocation;

  const NavigationInstruction({
    required this.mode,
    required this.targetStack,
    required this.action,
    required this.didDismissModal,
    this.refreshLocation,
  });
}

class NavigationStackState {
  final List<String> mainStack;
  final List<String> modalStack;

  const NavigationStackState({
    required this.mainStack,
    required this.modalStack,
  });
}

class NavigationStack {
  final List<String> _mainStack = [];
  final List<String> _modalStack = [];
  final String? _startLocation;

  NavigationStack({String? startLocation}) : _startLocation = startLocation {
    if (_startLocation != null) {
      _mainStack.add(_startLocation);
    }
  }

  NavigationStackState get state => NavigationStackState(
    mainStack: List.unmodifiable(_mainStack),
    modalStack: List.unmodifiable(_modalStack),
  );

  NavigationInstruction route({
    required String location,
    required Map<String, dynamic> properties,
    VisitOptions? options,
  }) {
    final resolvedProperties = Map<String, dynamic>.from(properties);
    final targetContext =
        resolvedProperties.context == PresentationContext.modal
        ? NavigationStackType.modal
        : NavigationStackType.main;
    final isModalActive = _modalStack.isNotEmpty;
    final currentContext = isModalActive
        ? NavigationStackType.modal
        : NavigationStackType.main;
    final presentation = _resolvePresentation(
      location: location,
      properties: resolvedProperties,
      targetContext: targetContext,
      options: options,
    );

    if (targetContext == NavigationStackType.modal &&
        presentation == Presentation.replaceRoot) {
      throw const NavigationStackException(
        'A `modal` destination cannot use presentation `REPLACE_ROOT`',
      );
    }

    final mode = _navigationMode(
      currentContext: currentContext,
      targetContext: targetContext,
    );

    if (mode == NavigationMode.toMain &&
        presentation != Presentation.pop &&
        presentation != Presentation.refresh &&
        presentation != Presentation.none &&
        _modalStack.isNotEmpty) {
      _modalStack.clear();
    }

    final isHistorical = resolvedProperties.isHistoricalLocation;
    if (isHistorical && _modalStack.isNotEmpty) {
      _modalStack.clear();
    }

    if (presentation == Presentation.none) {
      return NavigationInstruction(
        mode: mode,
        targetStack: currentContext,
        action: NavigationAction.none,
        didDismissModal: isModalActive && _modalStack.isEmpty,
      );
    }

    if (presentation == Presentation.pop) {
      return _applyPop(mode: mode);
    }

    if (presentation == Presentation.refresh) {
      return _applyRefresh(mode: mode);
    }

    if (presentation == Presentation.clearAll) {
      _modalStack.clear();
      _mainStack
        ..clear()
        ..add(location);
      return NavigationInstruction(
        mode: NavigationMode.inContext,
        targetStack: NavigationStackType.main,
        action: NavigationAction.clearAll,
        didDismissModal: isModalActive,
      );
    }

    if (presentation == Presentation.replaceRoot) {
      _modalStack.clear();
      _mainStack
        ..clear()
        ..add(location);
      return NavigationInstruction(
        mode: NavigationMode.inContext,
        targetStack: NavigationStackType.main,
        action: NavigationAction.replaceRoot,
        didDismissModal: isModalActive,
      );
    }

    final targetStack = targetContext == NavigationStackType.modal
        ? _modalStack
        : _mainStack;
    final action = _applyPushOrReplace(
      stack: targetStack,
      location: location,
      presentation: presentation,
    );

    return NavigationInstruction(
      mode: mode,
      targetStack: targetContext,
      action: action,
      didDismissModal: mode == NavigationMode.toMain && isModalActive,
    );
  }

  void reset({String? startLocation}) {
    _mainStack.clear();
    _modalStack.clear();
    final effectiveStart = startLocation ?? _startLocation;
    if (effectiveStart != null) {
      _mainStack.add(effectiveStart);
    }
  }

  NavigationAction _applyPushOrReplace({
    required List<String> stack,
    required String location,
    required Presentation presentation,
  }) {
    if (presentation == Presentation.replace) {
      if (stack.isEmpty) {
        stack.add(location);
      } else {
        stack[stack.length - 1] = location;
      }
      return NavigationAction.replace;
    }

    stack.add(location);
    return NavigationAction.push;
  }

  NavigationInstruction _applyPop({required NavigationMode mode}) {
    if (_modalStack.isNotEmpty) {
      final hadModal = _modalStack.isNotEmpty;
      if (_modalStack.length == 1) {
        _modalStack.clear();
        return NavigationInstruction(
          mode: mode,
          targetStack: NavigationStackType.modal,
          action: NavigationAction.pop,
          didDismissModal: hadModal,
        );
      }
      _modalStack.removeLast();
      return NavigationInstruction(
        mode: mode,
        targetStack: NavigationStackType.modal,
        action: NavigationAction.pop,
        didDismissModal: false,
      );
    }

    if (_mainStack.isNotEmpty) {
      _mainStack.removeLast();
    }

    return NavigationInstruction(
      mode: mode,
      targetStack: NavigationStackType.main,
      action: NavigationAction.pop,
      didDismissModal: false,
    );
  }

  NavigationInstruction _applyRefresh({required NavigationMode mode}) {
    if (_modalStack.isNotEmpty) {
      if (_modalStack.length == 1) {
        _modalStack.clear();
        return NavigationInstruction(
          mode: mode,
          targetStack: NavigationStackType.modal,
          action: NavigationAction.refresh,
          didDismissModal: true,
          refreshLocation: _mainStack.isNotEmpty ? _mainStack.last : null,
        );
      }
      _modalStack.removeLast();
      return NavigationInstruction(
        mode: mode,
        targetStack: NavigationStackType.modal,
        action: NavigationAction.refresh,
        didDismissModal: false,
        refreshLocation: _modalStack.isNotEmpty ? _modalStack.last : null,
      );
    }

    if (_mainStack.length > 1) {
      _mainStack.removeLast();
    }

    return NavigationInstruction(
      mode: mode,
      targetStack: NavigationStackType.main,
      action: NavigationAction.refresh,
      didDismissModal: false,
      refreshLocation: _mainStack.isNotEmpty ? _mainStack.last : null,
    );
  }

  NavigationMode _navigationMode({
    required NavigationStackType currentContext,
    required NavigationStackType targetContext,
  }) {
    if (currentContext == NavigationStackType.main &&
        targetContext == NavigationStackType.modal) {
      return NavigationMode.toModal;
    }
    if (currentContext == NavigationStackType.modal &&
        targetContext == NavigationStackType.main) {
      return NavigationMode.toMain;
    }
    return NavigationMode.inContext;
  }

  Presentation _resolvePresentation({
    required String location,
    required Map<String, dynamic> properties,
    required NavigationStackType targetContext,
    VisitOptions? options,
  }) {
    if (options?.action == VisitAction.replace) {
      return Presentation.replace;
    }
    final presentation = properties.presentation;
    if (presentation != Presentation.defaultValue) {
      return presentation;
    }
    final stack = targetContext == NavigationStackType.modal
        ? _modalStack
        : _mainStack;
    if (stack.isNotEmpty && stack.last == location) {
      return Presentation.replace;
    }
    return Presentation.defaultValue;
  }
}
