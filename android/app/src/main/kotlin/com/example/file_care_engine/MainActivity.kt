// package com.example.file_care_engine

// import android.content.pm.ApplicationInfo
// import android.content.pm.PackageInfo
// import android.content.pm.PackageManager
// import android.os.Build
// import io.flutter.embedding.android.FlutterActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel

// class MainActivity : FlutterActivity() {

//     private val CHANNEL = "app.install.source"

//     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//         super.configureFlutterEngine(flutterEngine)

//         MethodChannel(
//             flutterEngine.dartExecutor.binaryMessenger,
//             CHANNEL
//         ).setMethodCallHandler { call, result ->

//             val pm: PackageManager = applicationContext.packageManager

//             when (call.method) {

//                 // ✅ GET ALL INSTALLED APPS
//                 "getAllInstalledApps" -> {
//                     try {

//                         @Suppress("DEPRECATION")
//                         val packages: List<PackageInfo> =
//                             pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)

//                         val appList = mutableListOf<Map<String, Any?>>()

//                         for (pkg in packages) {

//                             // 🔥 FIX: handle nullable ApplicationInfo
//                             val appInfo = pkg.applicationInfo ?: continue

//                             // 🔹 INSTALL SOURCE (Safe for all versions)
//                             @Suppress("DEPRECATION")
//                             val installer = try {
//                                 pm.getInstallerPackageName(pkg.packageName)
//                             } catch (e: Exception) {
//                                 null
//                             }

//                             val installSource = when (installer) {
//                                 "com.android.vending" -> "Google Play Store"
//                                 "com.miui.packageinstaller" -> "MIUI Store"
//                                 "com.amazon.venezia" -> "Amazon Appstore"
//                                 "com.xiaomi.discover" -> "Xiaomi Discover"
//                                 null -> "Sideloaded / Unknown"
//                                 else -> installer
//                             }

//                             // 🔹 PERMISSIONS
//                             val permissions =
//                                 pkg.requestedPermissions?.toList() ?: emptyList()

//                             // 🔹 SYSTEM APP CHECK
//                             val isSystemApp =
//                                 (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

//                             // 🔹 DEBUGGABLE CHECK
//                             val isDebuggable =
//                                 (appInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

//                             val appData = mapOf(
//                                 "appName" to pm.getApplicationLabel(appInfo).toString(),
//                                 "packageName" to pkg.packageName,
//                                 "versionName" to pkg.versionName,
//                                 "versionCode" to pkg.versionCode,
//                                 "installer" to installSource,
//                                 "firstInstallTime" to pkg.firstInstallTime,
//                                 "lastUpdateTime" to pkg.lastUpdateTime,
//                                 "isSystemApp" to isSystemApp,
//                                 "isDebuggable" to isDebuggable,
//                                 "uid" to appInfo.uid,
//                                 "apkPath" to appInfo.sourceDir,
//                                 "permissions" to permissions
//                             )

//                             appList.add(appData)
//                         }

//                         result.success(appList)

//                     } catch (e: Exception) {
//                         result.error("ERROR", e.message, null)
//                     }
//                 }

//                 // ✅ GET SINGLE APP PERMISSIONS
//                 "getAppPermissions" -> {

//                     val packageName = call.argument<String>("packageName")

//                     if (packageName == null) {
//                         result.error("ERROR", "Package name missing", null)
//                         return@setMethodCallHandler
//                     }

//                     try {

//                         @Suppress("DEPRECATION")
//                         val packageInfo =
//                             pm.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)

//                         val permissions =
//                             packageInfo.requestedPermissions?.toList()
//                                 ?: emptyList()

//                         result.success(permissions)

//                     } catch (e: Exception) {
//                         result.error("ERROR", e.message, null)
//                     }
//                 }

//                 else -> result.notImplemented()
//             }
//         }
//     }
// }



package com.example.file_care_engine

import android.content.pm.ApplicationInfo
import android.content.pm.InstallSourceInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "app.install.source"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            val pm: PackageManager = applicationContext.packageManager

            when (call.method) {

                "getAllInstalledApps" -> {
                    try {

                        @Suppress("DEPRECATION")
                        val packages: List<PackageInfo> =
                            pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)

                        val appList = mutableListOf<Map<String, Any?>>()

                        for (pkg in packages) {

                            val appInfo = pkg.applicationInfo ?: continue

                            // ✅ FIXED: Correctly detect system apps
                            // FLAG_UPDATED_SYSTEM_APP catches pre-installed apps that were later updated
                            val isSystemApp =
                                (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 ||
                                (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0

                            val isDebuggable =
                                (appInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

                            // ✅ FIXED: Use getInstallSourceInfo() on Android 11+
                            val installSource = getInstallSource(pm, pkg.packageName, isSystemApp)

                            val permissions =
                                pkg.requestedPermissions?.toList() ?: emptyList()

                            val appData = mapOf(
                                "appName" to pm.getApplicationLabel(appInfo).toString(),
                                "packageName" to pkg.packageName,
                                "versionName" to pkg.versionName,
                                "versionCode" to pkg.versionCode,
                                "installer" to installSource,
                                "firstInstallTime" to pkg.firstInstallTime,
                                "lastUpdateTime" to pkg.lastUpdateTime,
                                "isSystemApp" to isSystemApp,
                                "isDebuggable" to isDebuggable,
                                "uid" to appInfo.uid,
                                "apkPath" to appInfo.sourceDir,
                                "permissions" to permissions
                            )

                            appList.add(appData)
                        }

                        result.success(appList)

                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "getAppPermissions" -> {

                    val packageName = call.argument<String>("packageName")

                    if (packageName == null) {
                        result.error("ERROR", "Package name missing", null)
                        return@setMethodCallHandler
                    }

                    try {

                        @Suppress("DEPRECATION")
                        val packageInfo =
                            pm.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)

                        val permissions =
                            packageInfo.requestedPermissions?.toList() ?: emptyList()

                        result.success(permissions)

                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun getInstallSource(pm: PackageManager, packageName: String, isSystemApp: Boolean): String {
        // System apps installed via ROM have no installer — handle them first
        if (isSystemApp) {
            // Try to get installer anyway (some system apps come from Play Store updates)
            val installer = getRawInstaller(pm, packageName)
            if (installer != null) return mapInstaller(installer)
            return "Pre-installed (System)"
        }

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Android 11+ — use the modern API
                val info: InstallSourceInfo = pm.getInstallSourceInfo(packageName)

                // installingPackageName = who triggered the install
                // initiatingPackageName = who initiated the install session
                val installer = info.installingPackageName
                    ?: info.initiatingPackageName

                if (installer != null) mapInstaller(installer)
                else "Sideloaded / Unknown"

            } else {
                // Android < 11 — use legacy API
                @Suppress("DEPRECATION")
                val installer = pm.getInstallerPackageName(packageName)
                if (installer != null) mapInstaller(installer) else "Sideloaded / Unknown"
            }
        } catch (e: Exception) {
            "Sideloaded / Unknown"
        }
    }

    private fun getRawInstaller(pm: PackageManager, packageName: String): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val info = pm.getInstallSourceInfo(packageName)
                info.installingPackageName ?: info.initiatingPackageName
            } else {
                @Suppress("DEPRECATION")
                pm.getInstallerPackageName(packageName)
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun mapInstaller(installer: String): String {
        return when (installer) {
            "com.android.vending"          -> "Google Play Store"
            "com.google.android.packageinstaller" -> "Google Package Installer"
            "com.miui.packageinstaller"    -> "MIUI Package Installer"
            "com.miui.market"              -> "Xiaomi GetApps"
            "com.xiaomi.discover"          -> "Xiaomi Discover"
            "com.amazon.venezia"           -> "Amazon Appstore"
            "com.huawei.appmarket"         -> "Huawei AppGallery"
            "com.samsung.android.app.spage" -> "Samsung Galaxy Store"
            "com.sec.android.app.samsungapps" -> "Samsung Galaxy Store"
            "com.oppo.market"              -> "OPPO App Market"
            "com.vivo.appstore"            -> "Vivo App Store"
            "com.android.packageinstaller" -> "Manual APK Install"
            "com.google.android.apps.nbu.files" -> "Files by Google (Sideloaded)"
            else                           -> installer // show raw package name if unknown
        }
    }
}