package com.example.app_blocking_prototype

import android.content.Context
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
}