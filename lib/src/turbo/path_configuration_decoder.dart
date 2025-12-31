import 'path_configuration_rule.dart';

class PathConfigurationDecoder {
  final Map<String, dynamic> settings;
  final List<PathConfigurationRule> rules;

  const PathConfigurationDecoder({required this.settings, required this.rules});

  factory PathConfigurationDecoder.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] is Map
        ? Map<String, dynamic>.from(json['settings'] as Map)
        : <String, dynamic>{};
    final rulesJson = json['rules'];
    if (rulesJson is! List) {
      throw const FormatException("Invalid path configuration");
    }
    final rules = rulesJson
        .whereType<Map>()
        .map(
          (rule) =>
              PathConfigurationRule.fromJson(Map<String, dynamic>.from(rule)),
        )
        .toList();

    return PathConfigurationDecoder(settings: settings, rules: rules);
  }
}
