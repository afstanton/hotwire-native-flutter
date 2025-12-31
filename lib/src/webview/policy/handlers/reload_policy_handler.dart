import '../webview_policy_decision.dart';
import '../webview_policy_handler.dart';
import '../webview_policy_request.dart';

class ReloadPolicyHandler extends WebViewPolicyDecisionHandler {
  @override
  WebViewPolicyDecision? evaluate(WebViewPolicyRequest request) {
    if (request.navigationType == 'reload') {
      return WebViewPolicyDecision.cancel;
    }
    return null;
  }
}
