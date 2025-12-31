import 'dart:convert';

import 'visit_action.dart';
import 'visit_response.dart';

class VisitOptions {
  final VisitAction action;
  final String? snapshotHTML;
  final VisitResponse? response;

  const VisitOptions({
    this.action = VisitAction.advance,
    this.snapshotHTML,
    this.response,
  });

  factory VisitOptions.fromJson(Map<String, dynamic> json) {
    return VisitOptions(
      action: VisitActionX.from(json['action']?.toString()),
      snapshotHTML: json['snapshotHTML']?.toString(),
      response: json['response'] is Map
          ? VisitResponse.fromJson(
              Map<String, dynamic>.from(json['response'] as Map),
            )
          : null,
    );
  }

  static VisitOptions? fromJsonString(String? jsonString) {
    if (jsonString == null) {
      return null;
    }
    try {
      final decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return VisitOptions.fromJson(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
