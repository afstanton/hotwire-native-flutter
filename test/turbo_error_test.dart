import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

void main() {
  test('TurboError maps status codes to kinds', () {
    expect(TurboError.fromStatusCode(0).kind, TurboErrorKind.networkFailure);
    expect(TurboError.fromStatusCode(-1).kind, TurboErrorKind.timeoutFailure);
    expect(
      TurboError.fromStatusCode(-2).kind,
      TurboErrorKind.contentTypeMismatch,
    );
    expect(TurboError.fromStatusCode(500).kind, TurboErrorKind.http);
  });

  test('TurboError descriptions include HTTP status codes', () {
    final error = TurboError.http(403);
    expect(error.description, 'There was an HTTP error (403).');
  });

  test('TurboError description uses provided message', () {
    final error = TurboError.message('Custom error');
    expect(error.description, 'Custom error');
  });
}
