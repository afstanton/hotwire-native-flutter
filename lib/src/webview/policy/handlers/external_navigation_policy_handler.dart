import '../webview_policy_decision.dart';
import '../webview_policy_handler.dart';
import '../webview_policy_request.dart';

class ExternalNavigationPolicyHandler implements WebViewPolicyDecisionHandler {
  @override
  WebViewPolicyDecision? evaluate(WebViewPolicyRequest request) {
    final uri = request.uri;
    if (uri == null) {
      return null;
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme.isEmpty) {
      return null;
    }

    if (scheme == 'http' || scheme == 'https') {
      return null;
    }

    return WebViewPolicyDecision.external;
  }
}
