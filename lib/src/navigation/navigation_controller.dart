import '../turbo/visit/visit_options.dart';
import 'navigation_stack.dart';

class NavigationRequest {
  final String location;
  final Map<String, dynamic> properties;
  final VisitOptions? options;

  const NavigationRequest({
    required this.location,
    required this.properties,
    this.options,
  });
}

abstract class NavigationExecutor {
  void push(String location, {required bool isModal});
  void replace(String location, {required bool isModal});
  void pop({required bool isModal});
  void clearAll(String location);
  void replaceRoot(String location);
  void presentModal();
  void dismissModal();
  void refresh(String location, {required bool isModal});
}

class NavigationHierarchyController {
  final NavigationStack stack;
  final NavigationExecutor executor;

  NavigationHierarchyController({required this.stack, required this.executor});

  NavigationInstruction? route(NavigationRequest request) {
    final instruction = stack.route(
      location: request.location,
      properties: request.properties,
      options: request.options,
    );

    if (instruction.didDismissModal) {
      executor.dismissModal();
    }

    switch (instruction.action) {
      case NavigationAction.none:
        break;
      case NavigationAction.pop:
        executor.pop(isModal: instruction.targetStack == NavigationStackType.modal);
        if (instruction.refreshLocation != null) {
          executor.refresh(
            instruction.refreshLocation!,
            isModal: instruction.targetStack == NavigationStackType.modal,
          );
        }
        break;
      case NavigationAction.refresh:
        if (instruction.refreshLocation != null) {
          executor.refresh(
            instruction.refreshLocation!,
            isModal: instruction.targetStack == NavigationStackType.modal,
          );
        }
        break;
      case NavigationAction.clearAll:
        executor.clearAll(request.location);
        break;
      case NavigationAction.replaceRoot:
        executor.replaceRoot(request.location);
        break;
      case NavigationAction.replace:
        executor.replace(
          request.location,
          isModal: instruction.targetStack == NavigationStackType.modal,
        );
        if (instruction.targetStack == NavigationStackType.modal) {
          executor.presentModal();
        }
        break;
      case NavigationAction.push:
        executor.push(
          request.location,
          isModal: instruction.targetStack == NavigationStackType.modal,
        );
        if (instruction.targetStack == NavigationStackType.modal) {
          executor.presentModal();
        }
        break;
    }

    return instruction;
  }
}
