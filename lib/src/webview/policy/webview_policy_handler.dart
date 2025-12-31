import 'webview_policy_decision.dart';
import 'webview_policy_request.dart';

abstract class WebViewPolicyDecisionHandler {
  WebViewPolicyDecision? evaluate(WebViewPolicyRequest request);
}
