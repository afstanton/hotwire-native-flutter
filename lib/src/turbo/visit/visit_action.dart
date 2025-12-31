enum VisitAction { advance, replace, restore }

extension VisitActionX on VisitAction {
  String get value => switch (this) {
    VisitAction.advance => 'advance',
    VisitAction.replace => 'replace',
    VisitAction.restore => 'restore',
  };

  static VisitAction from(String? value) {
    switch (value?.toLowerCase()) {
      case 'replace':
        return VisitAction.replace;
      case 'restore':
        return VisitAction.restore;
      case 'advance':
      default:
        return VisitAction.advance;
    }
  }
}
