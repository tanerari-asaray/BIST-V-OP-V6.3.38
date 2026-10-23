#!/usr/bin/env python3
"""Apply verified Build 668 chart support/resistance display fixes to checked-in baseline ZIP."""
from pathlib import Path
root=Path("source/android-v6323/app/src/main")
price=root/"java/tr/borsatakip/v5/ui/PriceChartView.kt"
full=root/"java/tr/borsatakip/v5/ui/FullscreenChartActivity.kt"

def change(s,old,new):
    n=s.count(old)
    if n != 1:
        raise AssertionError(f"expected one exact source contract, got {n}: {old[:75]}")
    return s.replace(old,new,1)

s=price.read_text()
s=change(s,"import tr.borsatakip.v5.analysis.ChartIndicators",
         "import tr.borsatakip.v5.analysis.ChartIndicators\nimport tr.borsatakip.v5.analysis.ChartSupportResistanceLevels")
s=change(s,"            series = ChartIndicators.calculate(field, intraday)",
         "            verifiedSupportResistance = ChartSupportResistanceLevels.fromCandles(field)\n            series = ChartIndicators.calculate(field, intraday)")
s=change(s,"    private var series = ChartIndicators.calculate(emptyList())",
         "    private var series = ChartIndicators.calculate(emptyList())\n    private var verifiedSupportResistance = ChartSupportResistanceLevels.Levels(null, null, 0.0, 0)")
s=change(s,"    var showTrendLines: Boolean = true",
         "    var showSupportResistance: Boolean = true\n        set(value) { field = value; invalidate() }\n    var showTrendLines: Boolean = true")
s=change(s,'putBoolean("atr", showAtr); putBoolean("trendLines", showTrendLines); putBoolean("channel", showChannel)',
         'putBoolean("atr", showAtr); putBoolean("trendLines", showTrendLines); putBoolean("channel", showChannel)\n        putBoolean("supportResistance", showSupportResistance)')
s=change(s,'        showChannel = saved.getBoolean("channel", showChannel)',
         '        showChannel = saved.getBoolean("channel", showChannel)\n        showSupportResistance = saved.getBoolean("supportResistance", showSupportResistance)')
s=change(s,
  '    private val resistanceTrendPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(255, 82, 82); strokeWidth = 2f; style = Paint.Style.STROKE }',
  '''    private val resistanceTrendPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(255, 82, 82); strokeWidth = 2f; style = Paint.Style.STROKE }
    private val pivotSupportFill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(53, 0, 200, 83); style = Paint.Style.FILL }
    private val pivotResistanceFill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(53, 255, 82, 82); style = Paint.Style.FILL }
    private val pivotSupportLine = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(0, 225, 100); strokeWidth = 2.4f; style = Paint.Style.STROKE }
    private val pivotResistanceLine = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(255, 95, 95); strokeWidth = 2.4f; style = Paint.Style.STROKE }
    private val pivotLabelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; textSize = 11f * fontUnit; textAlign = Paint.Align.RIGHT }''')
s=change(s,
   "            if (markerVisible) add(markerPrice!!)",
   '''            if (showSupportResistance) {
                // Axis expansion is bounded so a remote old pivot cannot flatten visible candles.
                val reference = visible.last().close
                val width = visible.maxOf { it.high } - visible.minOf { it.low }
                val nearby = max(reference * 0.025, width * 1.30)
                listOfNotNull(verifiedSupportResistance.support, verifiedSupportResistance.resistance)
                    .filter { abs(it - reference) <= nearby }.forEach(::add)
            }
            if (markerVisible) add(markerPrice!!)''')
s=change(s,
   '        if (showChannel) drawDynamicChannel(canvas, all, start, visible.size, left, right, ::y)\n        visible.forEachIndexed',
   '''        if (showChannel) drawDynamicChannel(canvas, all, start, visible.size, left, right, ::y)
        // Confirmed horizontal swing zones are not slope-limited regression trend lines.
        if (showSupportResistance) {
            verifiedSupportResistance.support?.let {
                drawConfirmedPivotBand(canvas, it, "DESTEK", verifiedSupportResistance.halfBandWidth,
                    minV, maxV, left, right, top, bottom, ::y, pivotSupportFill, pivotSupportLine)
            }
            verifiedSupportResistance.resistance?.let {
                drawConfirmedPivotBand(canvas, it, "DİRENÇ", verifiedSupportResistance.halfBandWidth,
                    minV, maxV, left, right, top, bottom, ::y, pivotResistanceFill, pivotResistanceLine)
            }
        }
        visible.forEachIndexed''')
s=change(s,
   '    private fun drawDynamicChannel(canvas: Canvas, all: List<Candle>, start: Int, count: Int, left: Float, right: Float, y: (Double) -> Float) {',
   '''    private fun drawConfirmedPivotBand(
        canvas: Canvas, level: Double, caption: String, halfWidth: Double,
        minV: Double, maxV: Double, left: Float, right: Float, top: Float, bottom: Float,
        y: (Double) -> Float, fill: Paint, line: Paint
    ) {
        if (!level.isFinite() || level !in minV..maxV || right <= left) return
        val yy = y(level)
        val bandPx = abs(y(level + halfWidth) - yy).coerceIn(3f, 12f)
        canvas.save()
        canvas.clipRect(left, top, right, bottom)
        canvas.drawRect(left, yy - bandPx, right, yy + bandPx, fill)
        canvas.drawLine(left, yy, right, yy, line)
        pivotLabelPaint.color = line.color
        val label = caption + " " + String.format(java.util.Locale("tr", "TR"), "%.2f", level)
        val labelY = (yy - bandPx - 4f).coerceIn(top + pivotLabelPaint.textSize, bottom - 2f)
        canvas.drawText(label, right - 7f, labelY, pivotLabelPaint)
        canvas.restore()
    }

    private fun drawDynamicChannel(canvas: Canvas, all: List<Candle>, start: Int, count: Int, left: Float, right: Float, y: (Double) -> Float) {''')
price.write_text(s)
s=full.read_text()
if "import tr.borsatakip.v5.analysis.LinearTrendAnalyzer" not in s:
    s=change(s,"import tr.borsatakip.v5.R", "import tr.borsatakip.v5.analysis.LinearTrendAnalyzer\nimport tr.borsatakip.v5.R")
s=change(s,"showTrendLines = false; showChannel = false",
         "showTrendLines = true; showChannel = true; showSupportResistance = true")
s=change(s,"        chart.signalPrice = null; chart.signalTime = null; chart.trendAnalysis = null",
         '''        chart.signalPrice = null; chart.signalTime = null
        // Confirmed historical candles only; an unfinished candle never determines the regression.
        chart.trendAnalysis = if (state.candles.size >= 13)
            LinearTrendAnalyzer.analyze(state.candles.dropLast(1)) else null''')
full.write_text(s)
source=Path("patches/ChartSupportResistanceLevels.kt")
test=Path("patches/ChartSupportResistanceLevelsTest.kt")
assert source.is_file() and test.is_file()
(root/"java/tr/borsatakip/v5/analysis/ChartSupportResistanceLevels.kt").write_text(source.read_text())
unit=Path("source/android-v6323/app/src/test/java/tr/borsatakip/v5/analysis/ChartSupportResistanceLevelsTest.kt")
unit.parent.mkdir(parents=True,exist_ok=True)
unit.write_text(test.read_text())
print("Verified Build668 support/resistance overlays and 3 JVM tests installed")
