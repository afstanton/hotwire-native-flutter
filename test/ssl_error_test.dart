import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

void main() {
  test('WebSslError maps known error codes', () {
    expect(
      WebSslError.fromErrorCode(WebSslError.expiredCode).description,
      'Expired',
    );
    expect(
      WebSslError.fromErrorCode(WebSslError.untrustedCode).description,
      'Untrusted',
    );
  });

  test('WebSslError preserves unknown error codes', () {
    final error = WebSslError.fromErrorCode(42);
    expect(error.errorCode, 42);
    expect(error.description, isNull);
  });
}
