import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'path_configuration_decoder.dart';
import 'path_configuration_rule.dart';

typedef PathConfigurationSettings = Map<String, dynamic>;

class PathConfiguration {
  PathConfiguration({
    List<PathConfigurationSource> sources = const [],
    PathConfigurationLoaderOptions? options,
  }) : _loaderOptions = options {
    this.sources = sources;
  }

  final StreamController<void> _updateController =
      StreamController<void>.broadcast();
  final StreamController<PathConfigurationError> _errorController =
      StreamController<PathConfigurationError>.broadcast();

  /// Enable to include the query string (in addition to the path) when applying rules.
  bool matchQueryStrings = true;

  PathConfigurationSettings settings = {};
  List<PathConfigurationRule> rules = List.unmodifiable(_defaultServerRules);

  List<PathConfigurationSource> _sources = const [];
  PathConfigurationLoader? _loader;
  final PathConfigurationLoaderOptions? _loaderOptions;

  Stream<void> get onUpdated => _updateController.stream;
  Stream<PathConfigurationError> get onError => _errorController.stream;

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
    _loader ??= PathConfigurationLoader(options: _loaderOptions);
    _loader?.load(
      sources: _sources,
      onLoaded: _updateWithDecoder,
      onError: _handleError,
    );
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
    _errorController.close();
  }

  void _handleError(PathConfigurationError error) {
    if (!_errorController.isClosed) {
      _errorController.add(error);
    }
  }
}

enum PathConfigurationSourceType { data, asset, server }

class PathConfigurationLoaderOptions {
  final Map<String, String> headers;

  const PathConfigurationLoaderOptions({this.headers = const {}});
}

enum PathConfigurationErrorType { invalidData, downloadFailed }

class PathConfigurationError {
  final PathConfigurationErrorType type;
  final PathConfigurationSource source;
  final String message;

  const PathConfigurationError({
    required this.type,
    required this.source,
    required this.message,
  });
}

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
  final PathConfigurationLoaderOptions? options;

  PathConfigurationLoader({
    PathConfigurationRepository? repository,
    this.options,
  }) : repository = repository ?? PathConfigurationRepository();

  Future<void> load({
    required List<PathConfigurationSource> sources,
    required void Function(PathConfigurationDecoder decoder) onLoaded,
    required void Function(PathConfigurationError error) onError,
  }) async {
    for (final source in sources) {
      switch (source.type) {
        case PathConfigurationSourceType.data:
          _loadData(source, source.value, onLoaded, onError);
          break;
        case PathConfigurationSourceType.asset:
          try {
            final data = await rootBundle.loadString(source.value);
            _loadData(source, data, onLoaded, onError);
          } catch (error) {
            onError(
              PathConfigurationError(
                type: PathConfigurationErrorType.invalidData,
                source: source,
                message: 'Failed to load asset: ${source.value}',
              ),
            );
          }
          break;
        case PathConfigurationSourceType.server:
          await _loadRemote(source, onLoaded, onError);
          break;
      }
    }
  }

  Future<void> _loadRemote(
    PathConfigurationSource source,
    void Function(PathConfigurationDecoder decoder) onLoaded,
    void Function(PathConfigurationError error) onError,
  ) async {
    final cached = await repository.readCached(source.value);
    if (cached != null) {
      _loadData(source, cached, onLoaded, onError);
    }

    final headers = <String, String>{...?options?.headers, ...?source.headers};
    final data = await repository.download(
      source.value,
      headers: headers.isEmpty ? null : headers,
    );
    if (data != null) {
      _loadData(source, data, onLoaded, onError);
      await repository.writeCached(source.value, data);
    } else {
      onError(
        PathConfigurationError(
          type: PathConfigurationErrorType.downloadFailed,
          source: source,
          message: 'Failed to download configuration: ${source.value}',
        ),
      );
    }
  }

  void _loadData(
    PathConfigurationSource source,
    String data,
    void Function(PathConfigurationDecoder decoder) onLoaded,
    void Function(PathConfigurationError error) onError,
  ) {
    try {
      final decodedJson = json.decode(data);
      if (decodedJson is! Map<String, dynamic>) {
        onError(
          PathConfigurationError(
            type: PathConfigurationErrorType.invalidData,
            source: source,
            message: 'Path configuration JSON was not an object.',
          ),
        );
        return;
      }
      final decoder = PathConfigurationDecoder.fromJson(decodedJson);
      onLoaded(decoder);
    } catch (_) {
      onError(
        PathConfigurationError(
          type: PathConfigurationErrorType.invalidData,
          source: source,
          message: 'Failed to decode path configuration JSON.',
        ),
      );
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
