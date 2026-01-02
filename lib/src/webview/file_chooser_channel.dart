import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'file_chooser_handler.dart';
import 'platform_hooks.dart';

class FileChooserChannel {
  static const MethodChannel _channel = MethodChannel(
    'hotwire_native_flutter/file_chooser',
  );
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  @visibleForTesting
  static Future<dynamic> handleMethodCall(MethodCall call) {
    return _handleMethodCall(call);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method != 'showFileChooser') {
      return null;
    }
    final params = _parseParams(call.arguments);
    if (params == null) {
      return null;
    }
    final result = await handleFileChooserRequest(params);
    return result?.paths;
  }

  static WebViewFileChooserParams? _parseParams(Object? arguments) {
    if (arguments is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(arguments);
    final acceptTypes =
        map['acceptTypes'] is List
            ? (map['acceptTypes'] as List)
                .map((item) => item.toString())
                .toList()
            : const <String>[];
    final allowMultiple = map['allowMultiple'] == true;
    final capture = map['capture'] == true;
    return WebViewFileChooserParams(
      acceptTypes: acceptTypes,
      allowMultiple: allowMultiple,
      capture: capture,
    );
  }
}
