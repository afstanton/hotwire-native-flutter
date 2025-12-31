import 'package:flutter_test/flutter_test.dart';

import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

void main() {
  test('builds a user agent with component list', () {
    final config = HotwireConfig()..applicationUserAgentPrefix = 'DemoApp';

    final userAgent = config.buildUserAgent(
      platformTag: 'Flutter',
      components: ['menu', 'form'],
    );

    expect(
      userAgent,
      'DemoApp Hotwire Native Flutter; Turbo Native Flutter; bridge-components: [menu form];',
    );
  });
}
