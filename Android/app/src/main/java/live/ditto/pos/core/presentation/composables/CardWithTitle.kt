package live.ditto.pos.core.presentation.composables

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

@Composable
fun CardWithTitle(
    modifier: Modifier = Modifier,
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(modifier = modifier) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                modifier = Modifier.fillMaxWidth(),
                text = title,
                style = MaterialTheme.typography.headlineLarge,
                textAlign = TextAlign.Center
            )
            content()
        }
    }
}

@Composable
fun InnerCardWithTitle(
    modifier: Modifier = Modifier,
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(
        modifier = modifier,
        elevation = CardDefaults.cardElevation(defaultElevation = 10.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.background)
    ) {
        Column(
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(color = MaterialTheme.colorScheme.primaryContainer)
                    .padding(16.dp)
            ) {
                Text(
                    modifier = Modifier.fillMaxWidth(),
                    text = title,
                    style = MaterialTheme.typography.titleLarge,
                    textAlign = TextAlign.Start
                )
            }
            Column(modifier = Modifier.padding(16.dp)) {
                content()
            }
        }
    }
}
