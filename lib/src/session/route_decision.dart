import '../turbo/path_properties.dart';

enum RouteDecision { navigate, delegate, external }

typedef RouteDecisionHandler =
    RouteDecision Function({
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

  if (initialized) {
    return RouteDecision.delegate;
  }

  return RouteDecision.navigate;
}
