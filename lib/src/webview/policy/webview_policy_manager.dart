import 'webview_policy_decision.dart';
import 'webview_policy_handler.dart';
import 'webview_policy_request.dart';

class WebViewPolicyManager {
  final List<WebViewPolicyDecisionHandler> handlers;

  WebViewPolicyManager({List<WebViewPolicyDecisionHandler>? handlers})
    : handlers = handlers ?? [];

  WebViewPolicyDecision decide(WebViewPolicyRequest request) {
    for (final handler in handlers) {
      final decision = handler.evaluate(request);
      if (decision != null) {
        return decision;
      }
    }
    return WebViewPolicyDecision.allow;
  }
}
