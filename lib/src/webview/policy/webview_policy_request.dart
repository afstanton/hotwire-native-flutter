class WebViewPolicyRequest {
  final String url;
  final bool isMainFrame;
  final bool isNewWindow;
  final String? navigationType;

  const WebViewPolicyRequest({
    required this.url,
    required this.isMainFrame,
    this.isNewWindow = false,
    this.navigationType,
  });

  Uri? get uri => Uri.tryParse(url);
}
