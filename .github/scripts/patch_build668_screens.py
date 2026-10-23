#!/usr/bin/env python3
"""CI-only: export real Android screenshots before Gradle uninstalls test APK."""
from pathlib import Path

stock = Path("source/android-v6323/app/src/androidTest/kotlin/tr/borsatakip/v5/ui/VisualScreenshotTest.kt")
fullscreen = Path("source/android-v6323/app/src/androidTest/java/tr/borsatakip/v5/ui/Build668VisualScreenshotTest.kt")
s=stock.read_text()
assert 'import android.graphics.Bitmap' in s
s=s.replace("import android.graphics.Bitmap","import android.graphics.Bitmap\nimport android.os.ParcelFileDescriptor",1)
original='File(inst.targetContext.getExternalFilesDir(null), "visual-screenshots")'
assert original in s
s=s.replace(original, 'File(inst.targetContext.filesDir, "build668-hisse")',1)
anchor='FileOutputStream(File(dir, "$name.png")).use { out -> bmp.compress(Bitmap.CompressFormat.PNG, 100, out) }'
assert anchor in s
export=r'''val targetPkg = inst.targetContext.packageName
            val streams = inst.uiAutomation.executeShellCommandRw("sh")
            val command = "mkdir -p /data/local/tmp/build668-hisse && " +
                "run-as $targetPkg cat files/build668-hisse/$name.png " +
                "> /data/local/tmp/build668-hisse/$name.png && echo EXPORTED\\n"
            ParcelFileDescriptor.AutoCloseOutputStream(streams[1]).use { it.write(command.toByteArray()) }
            val result = ParcelFileDescriptor.AutoCloseInputStream(streams[0]).bufferedReader().use { it.readText() }
            check(result.contains("EXPORTED")) { "Exporting screenshot $name failed: $result" }'''
# Avoid Python translating the escaped newline into a real source newline.
export=export.replace(r'EXPORTED\\n', r'EXPORTED\n')
s=s.replace(anchor,anchor+"\n            "+export,1)
stock.write_text(s)
t=fullscreen.read_text()
old="scroll.post { scroll.scrollTo(0, scroll.getChildAt(0).height) }"
assert old in t
t=t.replace(old,"scroll.scrollTo(0, scroll.getChildAt(0).height)",1)
fullscreen.write_text(t)
print("CI screenshot capture patch added, with one real Activity scroll and private-to-tmp exports")
