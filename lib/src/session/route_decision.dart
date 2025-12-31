import '../turbo/path_properties.dart';

enum RouteDecision { navigate, delegate, external }

typedef RouteDecisionHandler =
    RouteDecision Function({
      required String location,
      required Map<String, dynamic> properties,
      required bool initialized,
    });

typedef RouteDecisionEvaluator =
    RouteDecision? Function({
      required String location,
      required Map<String, dynamic> properties,
      required bool initialized,
    });

RouteDecision defaultRouteDecision({
  required String location,
  required Map<String, dynamic> properties,
  required bool initialized,
}) {
  if (properties.context == PresentationContext.modal) {
    return RouteDecision.delegate;
  }

  if (properties.presentation != Presentation.defaultValue) {
    return RouteDecision.delegate;
  }
  return RouteDecision.navigate;
}

class RouteDecisionManager {
  final List<RouteDecisionEvaluator> handlers;

  RouteDecisionManager({List<RouteDecisionEvaluator>? handlers})
    : handlers = handlers ?? [];

  RouteDecision decide({
    required String location,
    required Map<String, dynamic> properties,
    required bool initialized,
  }) {
    for (final handler in handlers) {
      final decision = handler(
        location: location,
        properties: properties,
        initialized: initialized,
      );
      if (decision != null) {
        return decision;
      }
    }
    return defaultRouteDecision(
      location: location,
      properties: properties,
      initialized: initialized,
    );
  }
}
