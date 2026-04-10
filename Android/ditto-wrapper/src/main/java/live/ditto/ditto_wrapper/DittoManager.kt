package live.ditto.ditto_wrapper

import android.content.Context
import android.util.Log
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
    dittoOnlinePlaygroundToken: String
) {
    private val ditto: Ditto? by lazy {
        try {
            val androidDependencies = DefaultAndroidDittoDependencies(context)
            val identity = DittoIdentity.OnlinePlayground(
                androidDependencies,
                appId = dittoOnlinePlaygroundAppId,
                token = dittoOnlinePlaygroundToken
            )
            DittoLogger.minimumLogLevel = DittoLogLevel.DEBUG
            Ditto(androidDependencies, identity).also { ditto ->
                // Use modern DQL syntax (no COLLECTION keyword, no MAP type hints, dot notation)
                // https://docs.ditto.live/dql/strict-mode
                kotlinx.coroutines.runBlocking {
                    ditto.store.execute("ALTER SYSTEM SET DQL_STRICT_MODE = false")
                }
                ditto.disableSyncWithV3()
                ditto.startSync()
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