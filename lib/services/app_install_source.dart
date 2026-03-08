import 'package:flutter/services.dart';

class AppInstallSource {
  static const MethodChannel _channel = MethodChannel('app.install.source');

  static Future<List<Map<String, dynamic>>> getAllInstalledApps() async {
    final List result = await _channel.invokeMethod('getAllInstalledApps');

    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<List<String>> getAppPermissions(String packageName) async {
    final List result = await _channel.invokeMethod(
      'getAppPermissions',
      {"packageName": packageName},
    );

    return List<String>.from(result);
  }
}
