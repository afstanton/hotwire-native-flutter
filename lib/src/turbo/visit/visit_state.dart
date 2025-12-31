class VisitState {
  final String identifier;
  final bool hasCachedSnapshot;
  final bool isPageRefresh;
  final bool started;
  final bool rendered;
  final bool completed;
  final bool failed;
  final int? statusCode;
  final String? restorationIdentifier;

  const VisitState({
    required this.identifier,
    required this.hasCachedSnapshot,
    required this.isPageRefresh,
    required this.started,
    required this.rendered,
    required this.completed,
    required this.failed,
    this.statusCode,
    this.restorationIdentifier,
  });
}
