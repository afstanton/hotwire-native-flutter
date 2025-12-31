import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';
import 'package:hotwire_native_flutter/src/webview/policy/handlers/external_navigation_policy_handler.dart';
import 'package:hotwire_native_flutter/src/webview/policy/handlers/new_window_policy_handler.dart';
import 'package:hotwire_native_flutter/src/webview/policy/handlers/link_activated_policy_handler.dart';

void main() {
  test('WebViewPolicyManager defaults to allow', () {
    final manager = WebViewPolicyManager();
    final decision = manager.decide(
      const WebViewPolicyRequest(url: 'https://example.com', isMainFrame: true),
    );
    expect(decision, WebViewPolicyDecision.allow);
  });

  test('ExternalNavigationPolicyHandler flags non-http schemes', () {
    final handler = ExternalNavigationPolicyHandler();
    final decision = handler.evaluate(
      const WebViewPolicyRequest(
        url: 'mailto:test@example.com',
        isMainFrame: true,
      ),
    );
    expect(decision, WebViewPolicyDecision.external);
  });

  test('NewWindowPolicyHandler flags new windows as external', () {
    final handler = NewWindowPolicyHandler();
    final decision = handler.evaluate(
      const WebViewPolicyRequest(
        url: 'https://example.com',
        isMainFrame: true,
        isNewWindow: true,
      ),
    );
    expect(decision, WebViewPolicyDecision.external);
  });

  test('LinkActivatedPolicyHandler allows link navigations', () {
    final handler = LinkActivatedPolicyHandler();
    final decision = handler.evaluate(
      const WebViewPolicyRequest(
        url: 'https://example.com',
        isMainFrame: true,
        navigationType: 'link',
      ),
    );
    expect(decision, WebViewPolicyDecision.allow);
  });
}
