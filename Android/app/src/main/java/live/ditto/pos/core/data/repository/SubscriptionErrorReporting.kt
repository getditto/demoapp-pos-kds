package live.ditto.pos.core.data.repository

import android.util.Log

// A sync-registration failure must not disable independent local UI queries.
fun reportSubscriptionFailure(context: String, error: Throwable): Nothing? {
    Log.e("DittoSubscription", "$context: ${error.message}", error)
    return null
}
