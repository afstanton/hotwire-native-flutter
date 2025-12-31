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

typedef StartLocationProvider = Uri? Function();

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

RouteDecisionEvaluator appNavigationRouteDecisionHandler(
  StartLocationProvider startLocationProvider,
) {
  return ({
    required String location,
    required Map<String, dynamic> properties,
    required bool initialized,
  }) {
    final startLocation = startLocationProvider();
    if (startLocation == null) {
      return null;
    }
    final locationUri = Uri.tryParse(location);
    if (locationUri == null || !_isHttpScheme(locationUri.scheme)) {
      return null;
    }
    if (locationUri.host == startLocation.host) {
      return RouteDecision.navigate;
    }
    return null;
  };
}

RouteDecisionEvaluator browserTabRouteDecisionHandler(
  StartLocationProvider startLocationProvider,
) {
  return ({
    required String location,
    required Map<String, dynamic> properties,
    required bool initialized,
  }) {
    final startLocation = startLocationProvider();
    if (startLocation == null) {
      return null;
    }
    final locationUri = Uri.tryParse(location);
    if (locationUri == null || !_isHttpScheme(locationUri.scheme)) {
      return null;
    }
    if (locationUri.host != startLocation.host) {
      return RouteDecision.external;
    }
    return null;
  };
}

RouteDecisionEvaluator systemNavigationRouteDecisionHandler(
  StartLocationProvider startLocationProvider,
) {
  return ({
    required String location,
    required Map<String, dynamic> properties,
    required bool initialized,
  }) {
    final startLocation = startLocationProvider();
    if (startLocation == null) {
      return null;
    }
    final locationUri = Uri.tryParse(location);
    if (locationUri == null) {
      return null;
    }
    if (!_isHttpScheme(locationUri.scheme)) {
      return RouteDecision.external;
    }
    if (locationUri.host != startLocation.host) {
      return RouteDecision.external;
    }
    return null;
  };
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

bool _isHttpScheme(String scheme) {
  return scheme == 'http' || scheme == 'https';
}
