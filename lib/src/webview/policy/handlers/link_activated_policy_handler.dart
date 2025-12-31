import '../webview_policy_decision.dart';
import '../webview_policy_handler.dart';
import '../webview_policy_request.dart';

class LinkActivatedPolicyHandler implements WebViewPolicyDecisionHandler {
  @override
  WebViewPolicyDecision? evaluate(WebViewPolicyRequest request) {
    if (request.navigationType == 'link') {
      return WebViewPolicyDecision.allow;
    }
    return null;
  }
}
