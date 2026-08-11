package live.ditto.ditto_wrapper

import android.content.Context
import android.util.Log
import com.ditto.kotlin.Ditto
import com.ditto.kotlin.DittoAuthenticationProvider
import com.ditto.kotlin.DittoConfig
import com.ditto.kotlin.DittoFactory
import com.ditto.kotlin.DittoLogLevel
import com.ditto.kotlin.DittoLogger
import com.ditto.kotlin.transports.DittoSyncPermissions
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

private val TAG = DittoManager::class.java.name

class DittoManager(
    val context: Context,
    private val dittoDatabaseId: String,
    private val dittoDevelopmentToken: String,
    private val dittoServerUrl: String
) {
    private val ditto: Ditto? by lazy {
        // Defensive backstop only: build-time credential validation lives in
        // build.gradle.kts (dittoEnv), which fails the build with a clear
        // message when a credential is missing or blank. These guards catch
        // anything that slips through blank; runtime SDK errors below are
        // caught and logged.
        require(dittoDatabaseId.isNotBlank()) { "DITTO_DATABASE_ID is missing — set it in the repo-root .env before building." }
        require(dittoDevelopmentToken.isNotBlank()) { "DITTO_DEVELOPMENT_TOKEN is missing — set it in the repo-root .env before building." }
        require(dittoServerUrl.isNotBlank()) {
            "DITTO_SERVER_URL is missing — set it in the repo-root .env before building."
        }
        require(dittoServerUrl.startsWith("https://")) {
            "DITTO_SERVER_URL must be an https:// URL (the v5 portal \"Connect via SDK\" URL): \"$dittoServerUrl\""
        }
        try {
            DittoLogger.minimumLogLevel = DittoLogLevel.Debug

            // Configure → Initialize → Authenticate → Sync. The server URL is
            // the portal's "Connect via SDK" URL. Strict mode defaults to off,
            // giving DQL map/object CRDT semantics.
            // https://docs.ditto.live/sdk/latest/ditto-config
            val config = DittoConfig(
                databaseId = dittoDatabaseId,
                connect = DittoConfig.Connect.Server(dittoServerUrl)
            )

            DittoFactory.create(config).apply {
                // Authenticate before sync starts: provide a fresh token
                // whenever the current one is missing or near expiry.
                auth?.expirationHandler = { authDitto, _ ->
                    try {
                        authDitto.auth?.login(
                            token = dittoDevelopmentToken,
                            provider = DittoAuthenticationProvider.development()
                        )
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Throwable) {
                        Log.e(TAG, "Authentication failed: ${e.message}")
                    }
                }

                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        sync.start()
                    } catch (e: Throwable) {
                        Log.e(TAG, "Failed to start sync: ${e.message}")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, e.message.orEmpty())
            null
        }
    }

    /// Sets the sync group from the numeric location ID so that only devices
    /// at the same location form a peer-to-peer mesh.
    fun setSyncGroup(locationId: String) {
        val value = locationId.toUIntOrNull() ?: run {
            // Non-numeric ids (e.g. legacy custom-location "$company-$location"
            // installs) can't map to a sync group. Log so this isn't silent —
            // callers should force a location re-pick for stale ids.
            Log.w(TAG, "Ignoring non-numeric location id for sync group: \"$locationId\"")
            return
        }
        val ditto = requireDitto()

        // Best-effort: sync.stop()/start() are @Throws and this runs from
        // setActiveLocation on a coroutine scope, so a failure here must not
        // take the app down in release.
        try {
            ditto.sync.stop()
            ditto.updateTransportConfig { config ->
                // Isolate the peer-to-peer mesh to devices at this location.
                // https://docs.ditto.live/sdk/latest/sync/creating-sync-groups
                config.global.syncGroup = value
            }
            ditto.sync.start()
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to apply sync group $value: ${e.message}")
        }
    }

    /// Resets the sync group back to the default (0) when no location is
    /// active, so the device leaves its per-location mesh.
    fun resetSyncGroup() {
        val ditto = requireDitto()

        // Best-effort for the same reason as setSyncGroup above.
        try {
            ditto.sync.stop()
            ditto.updateTransportConfig { config ->
                config.global.syncGroup = 0u
            }
            ditto.sync.start()
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to reset sync group: ${e.message}")
        }
    }

    fun requireDitto(): Ditto {
        return ditto ?: throw DittoNotCreatedException()
    }

    fun missingPermissions(): Array<String> {
        return DittoSyncPermissions(context = context).missingPermissions()
    }

    fun refreshPermissions() {
        requireDitto().refreshPermissions()
    }
}

class DittoNotCreatedException : Throwable("Ditto cannot be null")
