package tr.borsatakip.v5.analysis

import tr.borsatakip.v5.model.Candle
import kotlin.math.max

/** Computes visual support and resistance from confirmed OHLCV pivots only. */
object ChartSupportResistanceLevels {
    data class Levels(val support: Double?, val resistance: Double?, val halfBandWidth: Double, val confirmedCount: Int)

    fun fromCandles(input: List<Candle>): Levels {
        val rows = OhlcvResampler.sanitize(input)
        if (rows.size < 8) return Levels(null, null, 0.0, 0)
        // Last candle may be open: never use it as level evidence.
        val confirmed = rows.dropLast(1)
        val reference = confirmed.last().close
        if (!reference.isFinite() || reference <= 0.0) return Levels(null, null, 0.0, confirmed.size)
        val ladder = ExtendedStockEvidence.ladder(confirmed, reference)
        val ranges = confirmed.takeLast(20).map { it.high - it.low }.filter { it.isFinite() && it > 0.0 }
        val typical = ranges.average().takeIf { it.isFinite() } ?: 0.0
        // Visual width only, never a manufactured price or trading signal.
        val band = max(reference * 0.0008, typical * 0.15).coerceAtMost(reference * 0.004)
        return Levels(ladder.supports.firstOrNull(), ladder.resistances.firstOrNull(), band, confirmed.size)
    }
}
