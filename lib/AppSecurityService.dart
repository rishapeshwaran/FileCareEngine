import 'package:flutter/services.dart';

class AppSecurityService {
  static const MethodChannel _channel = MethodChannel('app.install.source');

  static Future<List<dynamic>> getAllAppsWithPermissions() async {
    final result = await _channel.invokeMethod('getAllAppsWithPermissions');
    return result;
  }
}
