package com.example.app_blocking_prototype

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * Receives tag links without showing any UI: toggles blocking and closes
 * straight away, so the app the user was in stays in front.
 */
class TagActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handle(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handle(intent)
    }

    private fun handle(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            TagLinks.handle(applicationContext, intent.data)
        }
        finish()
        overridePendingTransition(0, 0)
    }
}
