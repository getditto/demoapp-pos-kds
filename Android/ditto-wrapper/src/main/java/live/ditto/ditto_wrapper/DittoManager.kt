package live.ditto.ditto_wrapper

import android.content.Context
import android.util.Log
import live.ditto.Ditto
import live.ditto.DittoIdentity
import live.ditto.DittoLogLevel
import live.ditto.DittoLogger
import live.ditto.android.DefaultAndroidDittoDependencies

private val TAG = DittoManager::class.java.name

class DittoManager(
    context: Context,
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
            Ditto(androidDependencies, identity).apply {
                startSync()
            }
        } catch (e: Exception) {
            Log.e(TAG, e.message.orEmpty())
            null
        }
    }

    fun requireDitto(): Ditto {
        return ditto ?: throw DittoNotCreatedException()
    }
}

class DittoNotCreatedException : Throwable("Ditto cannot be null")