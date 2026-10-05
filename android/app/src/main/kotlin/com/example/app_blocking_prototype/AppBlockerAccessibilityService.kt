package com.example.app_blocking_prototype

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.DONUT)
class AppBlockerAccessibilityService : AccessibilityService() {
    val appBlocker = "AppBlocker"

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val prefs = getSharedPreferences("app_blocker_prefs", Context.MODE_PRIVATE)
        val isBlocking = prefs.getBoolean("isBlocking", false)
        val blockedPackages = prefs.getStringSet("blockedPackages", emptySet()) ?: emptySet()

        if (isBlocking && event?.packageName in blockedPackages) {
            Log.e(appBlocker, "Blocking App: ${event?.packageName}")
            val intent = Intent(this, BlockActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
            }
            startActivity(intent)
        }
    }

    override fun onInterrupt() {
        // required override, can be left empty for now
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.e("AppBlocker", "SERVICE CONNECTED")
    }
}