class WebSslError implements Exception {
  final int errorCode;
  final String? description;

  const WebSslError._(this.errorCode, this.description);

  static const int notYetValidCode = 0;
  static const int expiredCode = 1;
  static const int idMismatchCode = 2;
  static const int untrustedCode = 3;
  static const int dateInvalidCode = 4;
  static const int invalidCode = 5;

  factory WebSslError.fromErrorCode(int errorCode) {
    switch (errorCode) {
      case notYetValidCode:
        return const WebSslError._(notYetValidCode, 'Not Yet Valid');
      case expiredCode:
        return const WebSslError._(expiredCode, 'Expired');
      case idMismatchCode:
        return const WebSslError._(idMismatchCode, 'ID Mismatch');
      case untrustedCode:
        return const WebSslError._(untrustedCode, 'Untrusted');
      case dateInvalidCode:
        return const WebSslError._(dateInvalidCode, 'Date Invalid');
      case invalidCode:
        return const WebSslError._(invalidCode, 'Invalid');
      default:
        return WebSslError._(errorCode, null);
    }
  }
}
