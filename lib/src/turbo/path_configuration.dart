import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'path_configuration_decoder.dart';
import 'path_configuration_rule.dart';

typedef PathConfigurationSettings = Map<String, dynamic>;

class PathConfiguration {
  PathConfiguration({List<PathConfigurationSource> sources = const []}) {
    this.sources = sources;
  }

  final StreamController<void> _updateController =
      StreamController<void>.broadcast();

  /// Enable to include the query string (in addition to the path) when applying rules.
  bool matchQueryStrings = true;

  PathConfigurationSettings settings = {};
  List<PathConfigurationRule> rules = List.unmodifiable(_defaultServerRules);

  List<PathConfigurationSource> _sources = const [];
  PathConfigurationLoader? _loader;

  Stream<void> get onUpdated => _updateController.stream;

  List<PathConfigurationSource> get sources => _sources;
  set sources(List<PathConfigurationSource> value) {
    _sources = value;
    _load();
  }

  Map<String, dynamic> properties(String location) {
    final path = _pathForLocation(location);
    final properties = <String, dynamic>{};

    for (final rule in rules) {
      if (rule.matches(path)) {
        properties.addAll(rule.properties);
      }
    }

    return properties;
  }

  String _pathForLocation(String location) {
    final uri = Uri.tryParse(location);
    if (uri == null) {
      return location;
    }

    if (!matchQueryStrings || uri.query.isEmpty) {
      return uri.path;
    }

    return "${uri.path}?${uri.query}";
  }

  void _load() {
    if (_sources.isEmpty) {
      return;
    }
    _loader ??= PathConfigurationLoader();
    _loader?.load(sources: _sources, onLoaded: _updateWithDecoder);
  }

  void _updateWithDecoder(PathConfigurationDecoder decoder) {
    settings = decoder.settings;
    rules = List.unmodifiable(decoder.rules + _defaultServerRules);
    if (!_updateController.isClosed) {
      _updateController.add(null);
    }
  }

  void dispose() {
    _updateController.close();
  }
}

enum PathConfigurationSourceType { data, asset, server }

class PathConfigurationSource {
  final PathConfigurationSourceType type;
  final String value;
  final Map<String, String>? headers;

  const PathConfigurationSource._(this.type, this.value, {this.headers});

  const PathConfigurationSource.data(String data)
    : this._(PathConfigurationSourceType.data, data);

  const PathConfigurationSource.asset(String assetPath)
    : this._(PathConfigurationSourceType.asset, assetPath);

  const PathConfigurationSource.server(
    String url, {
    Map<String, String>? headers,
  }) : this._(PathConfigurationSourceType.server, url, headers: headers);
}

class PathConfigurationLoader {
  final PathConfigurationRepository repository;

  PathConfigurationLoader({PathConfigurationRepository? repository})
    : repository = repository ?? PathConfigurationRepository();

  Future<void> load({
    required List<PathConfigurationSource> sources,
    required void Function(PathConfigurationDecoder decoder) onLoaded,
  }) async {
    for (final source in sources) {
      switch (source.type) {
        case PathConfigurationSourceType.data:
          _loadData(source.value, onLoaded);
          break;
        case PathConfigurationSourceType.asset:
          final data = await rootBundle.loadString(source.value);
          _loadData(data, onLoaded);
          break;
        case PathConfigurationSourceType.server:
          await _loadRemote(source, onLoaded);
          break;
      }
    }
  }

  Future<void> _loadRemote(
    PathConfigurationSource source,
    void Function(PathConfigurationDecoder decoder) onLoaded,
  ) async {
    final cached = await repository.readCached(source.value);
    if (cached != null) {
      _loadData(cached, onLoaded);
    }

    final data = await repository.download(
      source.value,
      headers: source.headers,
    );
    if (data != null) {
      _loadData(data, onLoaded);
      await repository.writeCached(source.value, data);
    }
  }

  void _loadData(
    String data,
    void Function(PathConfigurationDecoder decoder) onLoaded,
  ) {
    try {
      final decodedJson = json.decode(data);
      if (decodedJson is! Map<String, dynamic>) {
        return;
      }
      final decoder = PathConfigurationDecoder.fromJson(decodedJson);
      onLoaded(decoder);
    } catch (_) {
      // Ignore invalid payloads.
    }
  }
}

class PathConfigurationRepository {
  Future<String?> download(String url, {Map<String, String>? headers}) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      headers?.forEach(request.headers.add);
      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  Future<void> writeCached(String url, String data) async {
    final file = await _cacheFile(url);
    await file.writeAsString(data);
  }

  Future<String?> readCached(String url) async {
    final file = await _cacheFile(url);
    if (!await file.exists()) {
      return null;
    }
    return await file.readAsString();
  }

  Future<File> _cacheFile(String url) async {
    final uri = Uri.parse(url);
    final filename = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : uri.host.replaceAll(":", "_");
    final directory = Directory("${Directory.systemTemp.path}/hotwire");
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File("${directory.path}/$filename");
  }
}

final List<PathConfigurationRule> _defaultServerRules = [
  PathConfigurationRule(
    patterns: const ["/recede_historical_location"],
    properties: const {
      "presentation": "pop",
      "context": "default",
      "historical_location": true,
    },
  ),
  PathConfigurationRule(
    patterns: const ["/resume_historical_location"],
    properties: const {
      "presentation": "none",
      "context": "default",
      "historical_location": true,
    },
  ),
  PathConfigurationRule(
    patterns: const ["/refresh_historical_location"],
    properties: const {
      "presentation": "refresh",
      "context": "default",
      "historical_location": true,
    },
  ),
];
