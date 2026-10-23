package tr.borsatakip.v5.analysis

import org.junit.Assert.*
import org.junit.Test
import tr.borsatakip.v5.model.Candle
import java.io.File

class ChartSupportResistanceLevelsTest {
    private fun bars(lastHigh: Double = 107.0) = (0..66).map { i ->
        val h = if (i == 66) lastHigh else if (i % 6 == 2) 125.0 + i * 0.1 else 107.0
        val l = if (i % 6 == 5) 75.0 - i * 0.1 else 95.0
        Candle(1_786_000_000_000L + i * 300_000L, 101.0, h, l, 101.0, 100.0)
    }

    @Test fun confirmedSwingZonesAreOnBothSidesOfPrice() {
        val x = ChartSupportResistanceLevels.fromCandles(bars())
        assertNotNull(x.support)
        assertNotNull(x.resistance)
        assertTrue(x.support!! < 101.0)
        assertTrue(x.resistance!! > 101.0)
        assertEquals(66, x.confirmedCount)
        assertTrue(x.halfBandWidth > 0)
    }

    @Test fun excludesUnconfirmedFinalBarAndDoesNotInventLevels() {
        val normal = ChartSupportResistanceLevels.fromCandles(bars())
        val extreme = ChartSupportResistanceLevels.fromCandles(bars(100000.0))
        assertEquals(normal.support, extreme.support)
        assertEquals(normal.resistance, extreme.resistance)
        assertNull(ChartSupportResistanceLevels.fromCandles(bars().take(6)).support)
        assertNull(ChartSupportResistanceLevels.fromCandles(bars().take(6)).resistance)
    }

    @Test fun bothStockDetailAndFullscreenRenderConfirmedBands() {
        val view = File("src/main/java/tr/borsatakip/v5/ui/PriceChartView.kt").readText()
        val fullscreen = File("src/main/java/tr/borsatakip/v5/ui/FullscreenChartActivity.kt").readText()
        assertTrue(view.contains("drawConfirmedPivotBand(canvas"))
        assertTrue(view.contains("verifiedSupportResistance.support?.let"))
        assertTrue(view.contains("verifiedSupportResistance.resistance?.let"))
        assertTrue(fullscreen.contains("showSupportResistance = true"))
        assertTrue(fullscreen.contains("LinearTrendAnalyzer.analyze(state.candles.dropLast(1))"))
    }
}
