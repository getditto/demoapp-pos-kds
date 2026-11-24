package live.ditto.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

internal class AppTicketViewModel(title: String, private val isPaid: Boolean, private val isReady: Boolean) {
    val paymentTitle = if (isPaid) "Paid" else "Unpaid"
    val stageTitle = if (isReady) "Ready" else "Preparing"
    val actionTitle = if (isReady) "Complete order" else "Mark ready"
    val buttonTitle = actionTitle.uppercase()
    val actionLabel = "$actionTitle, $title"
    val secondaryAction = isReady
    val paymentColor: Color
        @Composable get() = if (isPaid) AppColors.success else MaterialTheme.colorScheme.onSurfaceVariant
    val stageColor: Color
        @Composable get() = if (isReady) AppColors.success else AppColors.brandText
}
