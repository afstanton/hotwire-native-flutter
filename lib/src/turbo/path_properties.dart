enum Presentation {
  defaultValue,
  clearAll,
  replaceRoot,
  replace,
  pop,
  none,
  refresh,
}

enum PresentationContext { defaultValue, modal }

enum QueryStringPresentation { defaultValue, replace }

enum ModalStyle { medium, large, full, pageSheet, formSheet }

class PathTab {
  final String label;
  final String path;

  const PathTab({required this.label, required this.path});
}

extension PathPropertiesX on Map<String, dynamic> {
  Presentation get presentation {
    final value = this['presentation']?.toString().toLowerCase() ?? 'default';
    switch (value) {
      case 'clear_all':
        return Presentation.clearAll;
      case 'replace_root':
        return Presentation.replaceRoot;
      case 'replace':
        return Presentation.replace;
      case 'pop':
        return Presentation.pop;
      case 'none':
        return Presentation.none;
      case 'refresh':
        return Presentation.refresh;
      default:
        return Presentation.defaultValue;
    }
  }

  PresentationContext get context {
    final value = this['context']?.toString().toLowerCase() ?? 'default';
    switch (value) {
      case 'modal':
        return PresentationContext.modal;
      default:
        return PresentationContext.defaultValue;
    }
  }

  QueryStringPresentation get queryStringPresentation {
    final value =
        this['query_string_presentation']?.toString().toLowerCase() ??
        'default';
    switch (value) {
      case 'replace':
        return QueryStringPresentation.replace;
      default:
        return QueryStringPresentation.defaultValue;
    }
  }

  Uri? get uri {
    final value = this['uri']?.toString();
    return value == null ? null : Uri.tryParse(value);
  }

  Uri? get fallbackUri {
    final value = this['fallback_uri']?.toString();
    return value == null ? null : Uri.tryParse(value);
  }

  String? get title => this['title']?.toString();

  bool get pullToRefreshEnabled => this['pull_to_refresh_enabled'] == true;

  ModalStyle get modalStyle {
    final value = this['modal_style']?.toString().toLowerCase() ?? 'large';
    switch (value) {
      case 'medium':
        return ModalStyle.medium;
      case 'full':
        return ModalStyle.full;
      case 'page_sheet':
        return ModalStyle.pageSheet;
      case 'form_sheet':
        return ModalStyle.formSheet;
      default:
        return ModalStyle.large;
    }
  }

  bool get modalDismissGestureEnabled =>
      this['modal_dismiss_gesture_enabled'] == null
      ? true
      : this['modal_dismiss_gesture_enabled'] == true;

  String get viewController => this['view_controller']?.toString() ?? 'web';

  bool get animated =>
      this['animated'] == null ? true : this['animated'] == true;

  bool get isHistoricalLocation => this['historical_location'] == true;

  List<PathTab>? get tabs {
    final rawTabs = this['tabs'];
    if (rawTabs is! List) {
      return null;
    }
    final tabs = rawTabs
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          final label = map['label']?.toString();
          final path = map['path']?.toString();
          if (label == null || label.isEmpty || path == null || path.isEmpty) {
            return null;
          }
          return PathTab(label: label, path: path);
        })
        .whereType<PathTab>()
        .toList();
    return tabs.isEmpty ? null : tabs;
  }
}
