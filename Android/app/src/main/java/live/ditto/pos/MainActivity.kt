package live.ditto.pos

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import dagger.hilt.android.AndroidEntryPoint
import live.ditto.pos.data.demoMenuData
import live.ditto.pos.pos.composables.SaleItemsGrid
import live.ditto.pos.ui.theme.DittoPoSKDSDemoTheme

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            DittoPoSKDSDemoTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxHeight().width(600.dp),
                    color = MaterialTheme.colorScheme.background
                ) {
                    SaleItemsGrid(saleItems = demoMenuData)
                }
            }
        }
    }
}