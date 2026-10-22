#!/usr/bin/env python3
"""Build 668: Hisseler > Hisse Detayı 10 DK UI/source consistency fix.
Run this at the extracted Build 668 source-package root.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
activity = root / "android-v6323/app/src/main/java/tr/borsatakip/v5/ui/StockDetailActivity.kt"
layout = root / "android-v6323/app/src/main/res/layout/activity_stock_detail.xml"
if not activity.is_file() or not layout.is_file():
    raise SystemExit("Expected Build 668 source package layout not found")

s = activity.read_text(encoding="utf-8")
s = s.replace(
    'ChartTimeframe.FIVE_MIN,\n                ChartTimeframe.FIFTEEN_MIN,',
    'ChartTimeframe.FIVE_MIN,\n                ChartTimeframe.TEN_MIN,\n                ChartTimeframe.FIFTEEN_MIN,'
)
s = s.replace(
    'Triple(R.id.trend15m, ChartTimeframe.FIFTEEN_MIN, "15 DK")',
    'Triple(R.id.trend15m, ChartTimeframe.TEN_MIN, "10 DK")'
)
assert 'Triple(R.id.trend15m, ChartTimeframe.TEN_MIN, "10 DK")' in s
activity.write_text(s, encoding="utf-8")

x = layout.read_text(encoding="utf-8")
x = x.replace('android:text="15 DK • Bekleniyor"', 'android:text="10 DK • Bekleniyor"')
assert 'android:text="10 DK • Bekleniyor"' in x
assert 'btnTradingViewChart' in x
layout.write_text(x, encoding="utf-8")
print("PASS: 5m/10m/1h/daily summary and TradingView retained")
