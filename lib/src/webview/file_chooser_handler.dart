import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';

import '../hotwire.dart';
import 'platform_hooks.dart';

Future<WebViewFileChooserResult?> handleFileChooserRequest(
  WebViewFileChooserParams params,
) async {
  final handler = Hotwire().config.onFileChooser ?? _defaultFileChooserHandler;
  return handler(params);
}

Future<WebViewFileChooserResult?> _defaultFileChooserHandler(
  WebViewFileChooserParams params,
) async {
  if (params.capture) {
    final captured = await _captureMedia(params.acceptTypes);
    if (captured == null) {
      return null;
    }
    return WebViewFileChooserResult(paths: [captured]);
  }

  final typeGroups = _buildTypeGroups(params.acceptTypes);
  if (params.allowMultiple) {
    final files = await openFiles(acceptedTypeGroups: typeGroups);
    if (files.isEmpty) {
      return null;
    }
    return WebViewFileChooserResult(
      paths: files.map((file) => file.path).toList(),
    );
  }

  final file = await openFile(acceptedTypeGroups: typeGroups);
  if (file == null) {
    return null;
  }
  return WebViewFileChooserResult(paths: [file.path]);
}

List<XTypeGroup> _buildTypeGroups(List<String> acceptTypes) {
  final mimeTypes = <String>[];
  final extensions = <String>[];

  for (final type in acceptTypes) {
    final normalized = type.trim();
    if (normalized.isEmpty || normalized == '*/*') {
      continue;
    }
    if (normalized.startsWith('.')) {
      extensions.add(normalized.substring(1));
      continue;
    }
    if (normalized.contains('/')) {
      mimeTypes.add(normalized);
    }
  }

  if (mimeTypes.isEmpty && extensions.isEmpty) {
    return const [];
  }

  return [
    XTypeGroup(
      label: 'files',
      mimeTypes: mimeTypes.isEmpty ? null : mimeTypes,
      extensions: extensions.isEmpty ? null : extensions,
    ),
  ];
}

Future<String?> _captureMedia(List<String> acceptTypes) async {
  final picker = ImagePicker();
  final acceptsVideo = _acceptsType(acceptTypes, 'video/');
  final acceptsImage = _acceptsType(acceptTypes, 'image/');

  if (acceptsVideo && !acceptsImage) {
    final result = await picker.pickVideo(source: ImageSource.camera);
    return result?.path;
  }

  final result = await picker.pickImage(source: ImageSource.camera);
  return result?.path;
}

bool _acceptsType(List<String> acceptTypes, String prefix) {
  for (final type in acceptTypes) {
    if (type.toLowerCase().startsWith(prefix)) {
      return true;
    }
  }
  return false;
}
