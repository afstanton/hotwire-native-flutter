class WebViewProcessTermination {
  final WebViewProcessTerminationReason reason;

  const WebViewProcessTermination({required this.reason});
}

enum WebViewProcessTerminationReason { crashed, killed, unknown }

class WebViewHttpAuthChallenge {
  final String host;
  final String realm;

  const WebViewHttpAuthChallenge({required this.host, required this.realm});
}

enum WebViewHttpAuthAction { cancel, useCredential, performDefaultHandling }

class WebViewHttpAuthResponse {
  final WebViewHttpAuthAction action;
  final String? username;
  final String? password;

  const WebViewHttpAuthResponse({
    required this.action,
    this.username,
    this.password,
  });
}

class WebViewFileChooserParams {
  final List<String> acceptTypes;
  final bool allowMultiple;
  final bool capture;

  const WebViewFileChooserParams({
    this.acceptTypes = const [],
    this.allowMultiple = false,
    this.capture = false,
  });
}

class WebViewFileChooserResult {
  final List<String> paths;

  const WebViewFileChooserResult({required this.paths});
}

class WebViewGeolocationPermissionRequest {
  final String origin;

  const WebViewGeolocationPermissionRequest({required this.origin});
}

class WebViewGeolocationPermissionResponse {
  final bool allow;
  final bool retain;

  const WebViewGeolocationPermissionResponse({
    required this.allow,
    required this.retain,
  });
}

class OfflineRequest {
  final String url;
  final String method;
  final Map<String, String> headers;

  const OfflineRequest({
    required this.url,
    this.method = 'GET',
    this.headers = const {},
  });
}

class OfflineResponse {
  final int statusCode;
  final Map<String, String> headers;
  final List<int> body;

  const OfflineResponse({
    required this.statusCode,
    this.headers = const {},
    this.body = const [],
  });
}
