package com.example.app_blocking_prototype

import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class BlockActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context) =
        FlutterEngineCache.getInstance().get("block_engine")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.app_blocking_prototype/blocking"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // "Open Rest For More": zet de geblokkeerde app klaar en open de
                // app, waar de gebruiker bewust kan kiezen hem vrij te geven.
                "openUnblock" -> {
                    val prefs = getSharedPreferences("app_blocker_prefs", Context.MODE_PRIVATE)
                    val pkg = prefs.getString("lastBlockedPackage", "") ?: ""
                    prefs.edit().putString("pendingUnblock", pkg).apply()
                    startActivity(
                        Intent(this, MainActivity::class.java).addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                Intent.FLAG_ACTIVITY_SINGLE_TOP
                        )
                    )
                    finish()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
