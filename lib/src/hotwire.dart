import 'turbo/path_configuration.dart';

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
