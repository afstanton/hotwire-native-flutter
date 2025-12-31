import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

void main() {
  test('HotwireSessionPair selects sessions by context', () {
    final pair = HotwireSessionPair();

    expect(pair.sessionForContext(PresentationContext.defaultValue), pair.mainSession);
    expect(pair.sessionForContext(PresentationContext.modal), pair.modalSession);
  });
}
