import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

void main() {
  test('VisitAction parses string values', () {
    expect(VisitActionX.from('advance'), VisitAction.advance);
    expect(VisitActionX.from('replace'), VisitAction.replace);
    expect(VisitActionX.from('restore'), VisitAction.restore);
    expect(VisitActionX.from(null), VisitAction.advance);
  });

  test('VisitResponse reports success for 2xx', () {
    expect(const VisitResponse(statusCode: 200).isSuccessful, isTrue);
    expect(const VisitResponse(statusCode: 299).isSuccessful, isTrue);
    expect(const VisitResponse(statusCode: 302).isSuccessful, isFalse);
  });

  test('VisitOptions parses from json string', () {
    final options = VisitOptions.fromJsonString('''
      {
        "action": "replace",
        "snapshotHTML": "<html></html>",
        "response": {"statusCode": 200, "redirected": true}
      }
    ''');

    expect(options, isNotNull);
    expect(options?.action, VisitAction.replace);
    expect(options?.snapshotHTML, '<html></html>');
    expect(options?.response?.statusCode, 200);
    expect(options?.response?.redirected, isTrue);
  });
}
