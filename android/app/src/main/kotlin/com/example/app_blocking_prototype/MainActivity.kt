package com.example.app_blocking_prototype

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.app_blocking_prototype/blocking"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                "isAccessibilityEnabled" -> result.success(isAccessibilityServiceEnabled())
                "openAccessibilitySettings" -> {
                    startActivity(
                        Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                    result.success(null)
                }
                "getKnownTags" -> {
                    val prefs = getSharedPreferences("app_blocker_prefs", Context.MODE_PRIVATE)
                    val tags = prefs.getStringSet("knownTags", emptySet()) ?: emptySet()
                    result.success(tags.toList())
                }
                "addKnownTag" -> {
                    val id = call.argument<String>("uuid")?.lowercase()
                    if (id == null || !isValidUuid(id)) {
                        result.error("bad_uuid", "Not a valid UUID", null)
                    } else {
                        val prefs = getSharedPreferences("app_blocker_prefs", Context.MODE_PRIVATE)
                        val tags = HashSet(prefs.getStringSet("knownTags", emptySet()) ?: emptySet())
                        tags.add(id)
                        prefs.edit().putStringSet("knownTags", tags).apply()
                        result.success(null)
                    }
                }
                "removeKnownTag" -> {
                    val id = call.argument<String>("uuid")?.lowercase()
                    val prefs = getSharedPreferences("app_blocker_prefs", Context.MODE_PRIVATE)
                    val tags = HashSet(prefs.getStringSet("knownTags", emptySet()) ?: emptySet())
                    tags.remove(id)
                    prefs.edit().putStringSet("knownTags", tags).apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val enabled = Settings.Secure.getInt(
            contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED, 0
        ) == 1
        if (!enabled) return false
        val services = Settings.Secure.getString(
            contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val ours = ComponentName(this, AppBlockerAccessibilityService::class.java)
        return services.split(':').any {
            ComponentName.unflattenFromString(it) == ours
        }
    }

    private fun isValidUuid(value: String): Boolean = TagLinks.isValidUuid(value)
}
