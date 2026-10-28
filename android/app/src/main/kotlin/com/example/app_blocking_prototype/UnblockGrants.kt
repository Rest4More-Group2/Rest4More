package com.example.app_blocking_prototype

import android.content.SharedPreferences

/**
 * Apps die de gebruiker bewust tijdelijk heeft vrijgegeven. Elke regel is
 * "pakket|eindtijd in ms". De blokkade kijkt bij elke gebeurtenis naar de
 * klok, dus een verlopen vrijgave vergt geen timer: de volgende keer dat het
 * scherm van de app verandert, gaat hij weer dicht.
 */
object UnblockGrants {
    private const val KEY = "unblockGrants"

    private fun read(prefs: SharedPreferences): Map<String, Long> {
        val result = HashMap<String, Long>()
        for (entry in prefs.getStringSet(KEY, emptySet()) ?: emptySet()) {
            val parts = entry.split('|')
            val until = parts.getOrNull(1)?.toLongOrNull() ?: continue
            result[parts[0]] = until
        }
        return result
    }

    private fun write(prefs: SharedPreferences, grants: Map<String, Long>) {
        prefs.edit()
            .putStringSet(KEY, grants.map { "${it.key}|${it.value}" }.toSet())
            .apply()
    }

    fun isGranted(prefs: SharedPreferences, pkg: String, now: Long): Boolean =
        (read(prefs)[pkg] ?: 0L) > now

    /** Geeft [pkg] vrij tot [until]. Een kortere vrijgave verkort een langere niet. */
    fun grant(prefs: SharedPreferences, pkg: String, until: Long) {
        val grants = read(prefs).toMutableMap()
        grants[pkg] = until
        write(prefs, grants)
    }

    /** Alleen de vrijgaven die nog lopen. */
    fun active(prefs: SharedPreferences, now: Long): Map<String, Long> =
        read(prefs).filterValues { it > now }

    /** Een nieuwe blokkade begint schoon: oude vrijgaven gelden daar niet. */
    fun clear(prefs: SharedPreferences) {
        prefs.edit().remove(KEY).apply()
    }
}
