import 'session/route_decision.dart';
import 'turbo/path_configuration.dart';
import 'webview/platform_hooks.dart';
import 'webview/policy/handlers/external_navigation_policy_handler.dart';
import 'webview/policy/handlers/link_activated_policy_handler.dart';
import 'webview/policy/handlers/new_window_policy_handler.dart';
import 'webview/policy/webview_policy_manager.dart';

typedef BridgeJsonDecoder = Map<String, dynamic> Function(dynamic data);
typedef BridgeJsonEncoder = Object? Function(Object data);

class HotwireConfig {
  /// Configure options for matching path rules.
  final PathConfiguration pathConfiguration = PathConfiguration();

  /// Set a custom user agent application prefix for every WebView instance.
  String? applicationUserAgentPrefix;

  /// Enable or disable debug logging.
  bool debugLoggingEnabled = false;

  /// Optional custom JSON decoder for bridge component payloads.
  BridgeJsonDecoder? bridgeJsonDecoder;

  /// Optional custom JSON encoder for bridge component payloads.
  BridgeJsonEncoder? bridgeJsonEncoder;

  /// Optional error handler for bridge JSON encode/decode failures.
  void Function(Object error)? bridgeJsonErrorHandler;

  /// Optional default user agent to apply when the platform WebView exposes it.
  String? webViewDefaultUserAgent;

  /// Optional web view debugging toggle when supported by platform.
  bool? webViewDebuggingEnabled;

  /// Optional hooks for platform-specific web view events.
  void Function(WebViewProcessTermination event)? onWebViewProcessTerminated;
  Future<WebViewHttpAuthResponse?> Function(WebViewHttpAuthChallenge challenge)?
  onHttpAuthChallenge;
  Future<WebViewFileChooserResult?> Function(WebViewFileChooserParams params)?
  onFileChooser;
  Future<WebViewGeolocationPermissionResponse?> Function(
    WebViewGeolocationPermissionRequest request,
  )?
  onGeolocationPermissionRequest;
  Future<OfflineResponse?> Function(OfflineRequest request)?
  offlineRequestHandler;

  /// WebView navigation policy manager.
  WebViewPolicyManager webViewPolicyManager = WebViewPolicyManager(
    handlers: [
      NewWindowPolicyHandler(),
      LinkActivatedPolicyHandler(),
      ExternalNavigationPolicyHandler(),
    ],
  );

  /// Optional hook to configure the WebViewController as it's created.
  void Function(Object controller)? webViewControllerConfigurator;

  /// Route decision chain for app navigation.
  RouteDecisionManager routeDecisionManager = RouteDecisionManager();

  /// Builds the user agent string, optionally including bridge components.
  String buildUserAgent({
    String platformTag = "Flutter",
    List<String> components = const [],
  }) {
    final String componentsString = components.isNotEmpty
        ? "bridge-components: [${components.join(' ')}];"
        : "";

    final String base = applicationUserAgentPrefix != null
        ? "${applicationUserAgentPrefix!} Hotwire Native $platformTag;"
        : "Hotwire Native $platformTag;";

    final List<String> parts = [base, "Turbo Native $platformTag;"];

    if (componentsString.isNotEmpty) {
      parts.add(componentsString);
    }

    return parts.join(" ");
  }
}

class Hotwire {
  static final Hotwire _instance = Hotwire._internal();
  factory Hotwire() => _instance;
  Hotwire._internal();

  /// Global configuration entrypoint.
  final HotwireConfig config = HotwireConfig();
}
