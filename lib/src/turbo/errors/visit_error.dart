enum TurboErrorKind {
  networkFailure,
  timeoutFailure,
  contentTypeMismatch,
  pageLoadFailure,
  http,
  message,
}

abstract class VisitError {
  String get description;
}

class TurboError extends VisitError {
  final TurboErrorKind kind;
  final int? statusCode;
  final String? message;

  TurboError._(this.kind, {this.statusCode, this.message});

  factory TurboError.networkFailure() =>
      TurboError._(TurboErrorKind.networkFailure);

  factory TurboError.timeoutFailure() =>
      TurboError._(TurboErrorKind.timeoutFailure);

  factory TurboError.contentTypeMismatch() =>
      TurboError._(TurboErrorKind.contentTypeMismatch);

  factory TurboError.pageLoadFailure() =>
      TurboError._(TurboErrorKind.pageLoadFailure);

  factory TurboError.http(int statusCode) =>
      TurboError._(TurboErrorKind.http, statusCode: statusCode);

  factory TurboError.message(String message) =>
      TurboError._(TurboErrorKind.message, message: message);

  factory TurboError.fromStatusCode(int statusCode) {
    switch (statusCode) {
      case 0:
        return TurboError.networkFailure();
      case -1:
        return TurboError.timeoutFailure();
      case -2:
        return TurboError.contentTypeMismatch();
      default:
        return TurboError.http(statusCode);
    }
  }

  @override
  String get description {
    switch (kind) {
      case TurboErrorKind.networkFailure:
        return 'A network error occurred.';
      case TurboErrorKind.timeoutFailure:
        return 'A network timeout occurred.';
      case TurboErrorKind.contentTypeMismatch:
        return 'The server returned an invalid content type.';
      case TurboErrorKind.pageLoadFailure:
        return 'The page could not be loaded due to a configuration error.';
      case TurboErrorKind.http:
        return 'There was an HTTP error (${statusCode ?? 0}).';
      case TurboErrorKind.message:
        return message ?? 'An unknown error occurred.';
    }
  }
}
