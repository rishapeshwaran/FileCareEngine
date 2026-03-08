// import 'package:flutter/services.dart';

// class AppInstallSource {
//   static const MethodChannel _channel = MethodChannel('app.install.source');

//   static Future<String> getInstallSource(String packageName) async {
//     final String source = await _channel.invokeMethod('getInstallSource', {
//       'packageName': packageName,
//     });

//     return source;
//   }
// }

// import 'package:flutter/services.dart';

// class AppInstallSource {
//   static const MethodChannel _channel = MethodChannel('app.install.source');

//   static Future<List<dynamic>> getAllInstalledApps() async {
//     final List<dynamic> apps =
//         await _channel.invokeMethod('getAllInstalledApps');

//     return apps;
//   }
// }

// import 'package:flutter/services.dart';

// class AppInstallSource {
//   static const MethodChannel _channel = MethodChannel('app.install.source');

//   static Future<List<dynamic>> getAllInstalledApps() async {
//     final result = await _channel.invokeMethod('getAllInstalledApps');
//     return result;
//   }

//   static Future<List<dynamic>> getAppPermissions(String packageName) async {
//     final result = await _channel.invokeMethod(
//       'getAppPermissions',
//       {"packageName": packageName},
//     );
//     return result;
//   }
// }

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
