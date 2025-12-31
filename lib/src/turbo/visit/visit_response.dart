class VisitResponse {
  final int statusCode;
  final bool redirected;
  final String? responseHTML;

  const VisitResponse({
    required this.statusCode,
    this.redirected = false,
    this.responseHTML,
  });

  factory VisitResponse.fromJson(Map<String, dynamic> json) {
    return VisitResponse(
      statusCode: json['statusCode'] is int
          ? json['statusCode'] as int
          : int.tryParse(json['statusCode']?.toString() ?? '') ?? 0,
      redirected: json['redirected'] == true,
      responseHTML: json['responseHTML']?.toString(),
    );
  }

  bool get isSuccessful => statusCode >= 200 && statusCode <= 299;
}
