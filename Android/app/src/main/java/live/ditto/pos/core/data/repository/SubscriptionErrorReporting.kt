package live.ditto.pos.core.data.repository

import android.util.Log
import live.ditto.pos.BuildConfig

/**
 * Consistent handling for a failed sync-subscription registration: logs in
 * every build (never silent) and rethrows in debug. Mirrors iOS
 * `reportSubscriptionFailure`.
 */
fun reportSubscriptionFailure(context: String, error: Throwable): Nothing? {
    Log.e("DittoSubscription", "$context: ${error.message}", error)
    if (BuildConfig.DEBUG) throw error
    return null
}
