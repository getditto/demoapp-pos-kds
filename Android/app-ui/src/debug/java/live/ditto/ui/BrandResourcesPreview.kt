package live.ditto.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import live.ditto.ui.R

@Composable
internal fun BrandResourcesPreview(darkTheme: Boolean = false) {
    val icons = listOf(
        R.drawable.phosphor_cash_register, R.drawable.phosphor_cooking_pot,
        R.drawable.phosphor_receipt, R.drawable.phosphor_package,
        R.drawable.phosphor_gear, R.drawable.phosphor_map_pin,
        R.drawable.phosphor_plus, R.drawable.phosphor_minus,
        R.drawable.phosphor_dots_three_vertical, R.drawable.phosphor_pencil_simple,
        R.drawable.phosphor_trash, R.drawable.phosphor_camera,
        R.drawable.phosphor_image, R.drawable.phosphor_folder_open,
        R.drawable.phosphor_arrow_left, R.drawable.phosphor_caret_right,
        R.drawable.phosphor_check, R.drawable.phosphor_x,
        R.drawable.phosphor_warning, R.drawable.phosphor_sun,
        R.drawable.phosphor_moon, R.drawable.phosphor_circle_half
    )
    MaterialTheme(colorScheme = if (darkTheme) darkColorScheme() else lightColorScheme()) {
        Surface {
            Column(
                modifier = Modifier.width(390.dp).padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                Text("Chakra Petch · Regular 400", style = MaterialTheme.typography.labelSmall)
                Text("Inventory", fontFamily = FontFamily(Font(R.font.chakra_petch_regular)), fontSize = 28.sp)
                Text("Geist · Regular 400", style = MaterialTheme.typography.labelSmall)
                Text(
                    "Burger, coffee and café au lait.\nÀé ñ · $0.00 · $19.95",
                    fontFamily = FontFamily(Font(R.font.geist)),
                    fontSize = 17.sp
                )
                Text("Geist Mono · Regular 400", style = MaterialTheme.typography.labelSmall)
                Text("NEW ITEM   0123456789   + −", fontFamily = FontFamily(Font(R.font.geist_mono)), fontSize = 15.sp)
                Text("Phosphor · Regular", style = MaterialTheme.typography.labelSmall)
                icons.chunked(6).forEach { row ->
                    Row(horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                        row.forEach { resource ->
                            Icon(painterResource(resource), contentDescription = null, modifier = Modifier.size(24.dp))
                        }
                    }
                }
            }
        }
    }
}

@Preview(name = "Resources · Light")
@Composable
private fun BrandResourcesLightPreview() = BrandResourcesPreview()

@Preview(name = "Resources · Dark")
@Composable
private fun BrandResourcesDarkPreview() = BrandResourcesPreview(darkTheme = true)
