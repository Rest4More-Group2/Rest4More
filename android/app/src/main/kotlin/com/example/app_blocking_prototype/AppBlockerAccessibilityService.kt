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

        val pkg = event?.packageName?.toString()
        // Een bewust tijdelijk vrijgegeven app blijft open tot de tijd om is.
        val granted = pkg != null && UnblockGrants.isGranted(prefs, pkg, System.currentTimeMillis())

        if (isBlocking && pkg != null && pkg in blockedPackages && !granted) {
            Log.e(appBlocker, "Blocking App: $pkg")
            // Het blokkeerscherm weet zo welke app het vrij kan laten geven.
            prefs.edit().putString("lastBlockedPackage", pkg).apply()
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