package com.example.app_blocking_prototype

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.app_blocking_prototype/blocking"
    private val NOTIFICATION_CHANNEL = "rest4more/notifications"
    private val NOTIFICATION_REQUEST_CODE = 4101

    /// Wacht op het antwoord van het systeemvenster voor meldingen.
    private var pendingNotificationResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> result.success(notificationStatus())
                "request" -> requestNotificationPermission(result)
                "openSettings" -> result.success(openNotificationSettings())
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setBlocking" -> {
                    val isBlocking = call.argument<Boolean>("isBlocking") ?: false
                    val prefs = getSharedPreferences("app_blocker_prefs", Context.MODE_PRIVATE)
                    prefs.edit().putBoolean("isBlocking", isBlocking).apply()
                    result.success(null)
                }
                "getBlocking" -> {
                    val prefs = getSharedPreferences("app_blocker_prefs", Context.MODE_PRIVATE)
                    result.success(prefs.getBoolean("isBlocking", false))
                }
                "setBlockedPackages" -> {
                    val blockedPackages = call.argument<List<String>>("blockedPackages") ?: emptyList()
                    val prefs = getSharedPreferences("app_blocker_prefs", Context.MODE_PRIVATE)
                    prefs.edit().putStringSet("blockedPackages", blockedPackages.toSet()).apply()
                    result.success(null)
                }
                "getBlockedPackages" -> {
                    val prefs = getSharedPreferences("app_blocker_prefs", Context.MODE_PRIVATE)
                    val blockedPackages = prefs.getStringSet("blockedPackages", emptySet()) ?: emptySet()
                    result.success(blockedPackages.toList())
                }
                else -> result.notImplemented()
            }
        }
    }

    // Toestemming voor meldingen (zie notification_permission.dart). Vanaf
    // Android 13 is het een runtime-toestemming. Na twee weigeringen laat het
    // systeem het venster niet meer zien; dat herkennen we doordat we al eens
    // gevraagd hebben en het systeem geen uitleg meer verwacht.

    private fun notificationStatus(): String {
        val enabled = getSystemService(NotificationManager::class.java)
            .areNotificationsEnabled()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return if (enabled) "granted" else "blocked"
        }
        val permitted = checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        return when {
            permitted && enabled -> "granted"
            // Toegestaan, maar in de instellingen uitgezet.
            permitted -> "blocked"
            !hasAskedForNotifications() -> "notDetermined"
            shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS) -> "denied"
            else -> "blocked"
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        val status = notificationStatus()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            status == "granted" || status == "blocked" ||
            pendingNotificationResult != null
        ) {
            result.success(status)
            return
        }
        pendingNotificationResult = result
        markAskedForNotifications()
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != NOTIFICATION_REQUEST_CODE) return
        pendingNotificationResult?.success(notificationStatus())
        pendingNotificationResult = null
    }

    private fun openNotificationSettings(): Boolean {
        val notificationSettings = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        val appDetails = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null)
        )
        for (intent in listOf(notificationSettings, appDetails)) {
            try {
                startActivity(intent)
                return true
            } catch (e: Exception) {
                // Probeer de volgende.
            }
        }
        return false
    }

    private fun notificationPrefs() =
        getSharedPreferences("notification_permission_prefs", Context.MODE_PRIVATE)

    private fun hasAskedForNotifications() =
        notificationPrefs().getBoolean("asked", false)

    private fun markAskedForNotifications() =
        notificationPrefs().edit().putBoolean("asked", true).apply()
}
