package live.ditto.ditto_wrapper

import android.content.Context
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import live.ditto.Ditto
import live.ditto.DittoIdentity
import live.ditto.DittoLogLevel
import live.ditto.DittoLogger
import live.ditto.android.DefaultAndroidDittoDependencies
import live.ditto.transports.DittoSyncPermissions

private val TAG = DittoManager::class.java.name

class DittoManager(
    val context: Context,
    dittoOnlinePlaygroundAppId: String,
    dittoOnlinePlaygroundToken: String,
    dittoWebsocketURL: String
) {
    private val ditto: Ditto? by lazy {
        try {
            val androidDependencies = DefaultAndroidDittoDependencies(context)
            val identity = DittoIdentity.OnlinePlayground(
                dependencies = androidDependencies,
                appId = dittoOnlinePlaygroundAppId,
                token = dittoOnlinePlaygroundToken,
                enableDittoCloudSync = false
            )
            DittoLogger.minimumLogLevel = DittoLogLevel.DEBUG
            Ditto(androidDependencies, identity).apply {
                disableSyncWithV3()

                updateTransportConfig { config ->
                    config.connect.websocketUrls.add(dittoWebsocketURL)
                }

                smallPeerInfo.isEnabled = true
                // Launch the suspend query in a coroutine scope
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        store.execute(query = "ALTER SYSTEM SET DQL_STRICT_MODE = false")
                        startSync()
                    } catch (e: Throwable) {
                        Log.e(TAG, "Failed to execute DQL mode query: ${e.message}")
                    }
                }
            }

        } catch (e: Exception) {
            Log.e(TAG, e.message.orEmpty())
            null
        }
    }

    fun requireDitto(): Ditto {
        return ditto ?: throw DittoNotCreatedException()
    }

    fun missingPermissions(): Array<String> {
        return DittoSyncPermissions(context = context).missingPermissions()
    }
}

class DittoNotCreatedException : Throwable("Ditto cannot be null")