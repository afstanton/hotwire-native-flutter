class PathConfigurationRule {
  final List<String> patterns;
  final Map<String, dynamic> properties;

  PathConfigurationRule({required this.patterns, required this.properties});

  factory PathConfigurationRule.fromJson(Map<String, dynamic> json) {
    final patterns = (json['patterns'] as List<dynamic>?)
        ?.map((value) => value.toString())
        .toList();
    final properties = json['properties'] is Map
        ? Map<String, dynamic>.from(json['properties'] as Map)
        : null;

    if (patterns == null || properties == null) {
      throw const FormatException("Invalid path configuration rule");
    }

    return PathConfigurationRule(patterns: patterns, properties: properties);
  }

  bool matches(String path) {
    for (final pattern in patterns) {
      try {
        final regex = RegExp(pattern);
        if (regex.hasMatch(path)) {
          return true;
        }
      } catch (_) {
        // Ignore invalid patterns.
      }
    }
    return false;
  }
}
