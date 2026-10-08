package com.example.app_blocking_prototype

import android.content.Context
import android.net.Uri
import android.widget.Toast
import java.util.UUID

object TagLinks {
    private const val TAG_HOST = "tap.bartvangestel.nl"

    fun isValidUuid(value: String): Boolean =
        try { UUID.fromString(value).toString() == value } catch (e: IllegalArgumentException) { false }

    fun parseTagUuid(uri: Uri?): String? {
        if (uri == null) return null
        if (uri.scheme != "https" || uri.host != TAG_HOST) return null
        val segments = uri.pathSegments
        if (segments.size != 2 || segments[0] != "t") return null
        val id = segments[1].lowercase()
        return if (isValidUuid(id)) id else null
    }

    /** Toggles blocking if [uri] is a link of a paired tag. */
    fun handle(context: Context, uri: Uri?) {
        val uuid = parseTagUuid(uri) ?: return
        val prefs = context.getSharedPreferences("app_blocker_prefs", Context.MODE_PRIVATE)
        val known = prefs.getStringSet("knownTags", emptySet()) ?: emptySet()

        if (uuid !in known) {
            Toast.makeText(context, "Unknown tag. Pair it in the app first.", Toast.LENGTH_LONG).show()
            return
        }

        val newState = !prefs.getBoolean("isBlocking", false)
        prefs.edit().putBoolean("isBlocking", newState).apply()
        Toast.makeText(
            context,
            if (newState) "Blocking on" else "Blocking off",
            Toast.LENGTH_SHORT
        ).show()
    }
}
