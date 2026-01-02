import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';
import 'package:hotwire_native_flutter/src/webview/file_chooser_channel.dart';
import 'package:hotwire_native_flutter/src/webview/platform_hooks.dart';

void main() {
  tearDown(() {
    Hotwire().config.onFileChooser = null;
  });

  test('FileChooserChannel forwards parsed params to handler', () async {
    WebViewFileChooserParams? captured;
    Hotwire().config.onFileChooser = (params) async {
      captured = params;
      return const WebViewFileChooserResult(paths: ['a']);
    };

    final result = await FileChooserChannel.handleMethodCall(
      const MethodCall('showFileChooser', {
        'acceptTypes': ['image/*', '.pdf'],
        'allowMultiple': true,
        'capture': true,
      }),
    );

    expect(result, ['a']);
    expect(captured, isNotNull);
    expect(captured!.acceptTypes, ['image/*', '.pdf']);
    expect(captured!.allowMultiple, isTrue);
    expect(captured!.capture, isTrue);
  });

  test('FileChooserChannel ignores invalid calls', () async {
    var called = false;
    Hotwire().config.onFileChooser = (params) async {
      called = true;
      return null;
    };

    final wrongMethod = await FileChooserChannel.handleMethodCall(
      const MethodCall('nope'),
    );
    expect(wrongMethod, isNull);
    expect(called, isFalse);

    final badArgs = await FileChooserChannel.handleMethodCall(
      const MethodCall('showFileChooser', 'nope'),
    );
    expect(badArgs, isNull);
    expect(called, isFalse);
  });
}
