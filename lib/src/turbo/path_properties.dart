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

  bool get animated =>
      this['animated'] == null ? true : this['animated'] == true;

  bool get isHistoricalLocation => this['historical_location'] == true;
}
