import 'package:flutter/services.dart';

abstract final class ExternalLinkLauncher {
  static const _channel = MethodChannel('rayssa_delivery/external_links');

  static Future<bool> open(Uri uri) async {
    try {
      return await _channel.invokeMethod<bool>(
            'openUrl',
            {'url': uri.toString()},
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
