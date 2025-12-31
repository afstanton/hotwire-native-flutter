import '../webview_policy_decision.dart';
import '../webview_policy_handler.dart';
import '../webview_policy_request.dart';

class NewWindowPolicyHandler implements WebViewPolicyDecisionHandler {
  @override
  WebViewPolicyDecision? evaluate(WebViewPolicyRequest request) {
    if (request.isNewWindow) {
      return WebViewPolicyDecision.external;
    }
    return null;
  }
}
