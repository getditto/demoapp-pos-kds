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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

private val TAG = DittoManager::class.java.name

class DittoManager(
    val context: Context,
    private val dittoDatabaseId: String,
    private val dittoDevelopmentToken: String,
    private val dittoUrl: String
) {
    private val ditto: Ditto? by lazy {
        try {
            DittoLogger.minimumLogLevel = DittoLogLevel.Debug

            // Configure → Initialize → Authenticate → Sync. The server URL is
            // the portal's "Connect via SDK" URL. Strict mode defaults to off,
            // giving DQL map/object CRDT semantics.
            // https://docs.ditto.live/sdk/latest/ditto-config
            val config = DittoConfig(
                databaseId = dittoDatabaseId,
                connect = DittoConfig.Connect.Server(dittoUrl)
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
        val value = locationId.toUIntOrNull() ?: return
        val ditto = requireDitto()

        ditto.sync.stop()
        ditto.updateTransportConfig { config ->
            // Isolate the peer-to-peer mesh to devices at this location.
            // https://docs.ditto.live/sdk/latest/sync/creating-sync-groups
            config.global.syncGroup = value
        }
        ditto.sync.start()
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
