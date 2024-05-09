package live.ditto.pos.ditto

import android.content.Context
import android.util.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import live.ditto.Ditto
import live.ditto.DittoIdentity
import live.ditto.DittoLogLevel
import live.ditto.DittoLogger
import live.ditto.android.DefaultAndroidDittoDependencies
import live.ditto.pos.BuildConfig
import java.lang.Exception
import javax.inject.Inject
import javax.inject.Singleton

private val TAG = DittoManager::class.java.name

@Singleton
class DittoManager @Inject constructor(@ApplicationContext context: Context) {
    val ditto: Ditto? by lazy {
        try {
            val androidDependencies = DefaultAndroidDittoDependencies(context)
            val identity = DittoIdentity.OnlinePlayground(
                androidDependencies,
                appId = BuildConfig.DITTO_ONLINE_PLAYGROUND_APP_ID,
                token = BuildConfig.DITTO_ONLINE_PLAYGROUND_TOKEN
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
