package live.ditto.pos

import android.app.Application
import android.content.Context
import androidx.test.runner.AndroidJUnitRunner

class OfflineTestRunner : AndroidJUnitRunner() {
    // Keep the demo's Hilt startup, seeding and sync out of native store tests.
    override fun newApplication(cl: ClassLoader, className: String, context: Context): Application =
        super.newApplication(cl, Application::class.java.name, context)
}
