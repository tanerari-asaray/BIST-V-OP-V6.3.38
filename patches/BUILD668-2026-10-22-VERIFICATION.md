# Build 668 — 22 Ekim 2026 kaynak/doğrulama kaydı

Referans: Hisseler > Hisse Detayı, Grafik/Teknik/Plan, 6 açıklama kartı.

## Kaynak oturumunda tamamlananlar
- 5/10/60 dakika ve günlük bağımsız grafik/trend özetlerinin korunması.
- 30 dakikalık dönemin yalnız eksiksiz 5 dakikalık OHLCV gruplarından üretilmesi.
- Aylık dönemin gerçek günlük OHLCV verilerinden hesaplanması.
- Son teyitsiz mumun kesinleşmiş yön veya destek/direnç hesaplarına alınmaması.
- Ana hisse detay ekranının altında 6 kart: fiyatın seyri; önemli seviyeler; yorumun hangi koşulda değişeceği; şirketin faaliyet alanı; ilginin nedeni; riskler.
- Doğrulanmamış sektör, şirket haberi veya fiyatların uydurulmaması.
- Kullanıcıya ham istisna/API hata mesajı gösterilmemesi.
- Önceden tamamlanan vektör ikonlar, tipografi, TradingView, sağ oklar ve gösterge satırının korunması.

## Doğrulanmış yerel sonuçlar
- Kaynak etkileşim sözleşmesi 30/30.
- Tipografi/vektör ve kaynak statik kontrolleri 23/23.
- Ek kaynak sözleşmesi 19/19.
- Önceki finansal regresyon testleri 198/198 (çevrimdışı JVM).
- Yeni 30 dakikalık ve aylık model smoke testleri 5/5.
- Değişen altı Kotlin dosyası, PSI sözdizimi hatası 0.
- Android kaynak ZIP: 703 dosya, SHA-256 97cff8419a4b4e48cf7760f11972295c50594860d9e5e1e43016e1116ccd382f.

## Kritik teslim kısıtı
**Bu dalda tam güncellenmiş kaynak ZIP bulunmuyor.** Güncel paket ChatGPT sohbetinde teslim edildi. Bu GitHub kaydı kaynak kod değişikliklerinin depoya tamamen aktarıldığını veya APK üretildiğini kanıtlamaz.

Android Gradle wrapper JAR eski Build668 kaynaklarından onarılmıştır; ama Gradle dağıtımının indirilmesi `UnknownHostException: services.gradle.org` ile engellenmiştir. Android SDK/emülatör bu yerel ortamda yoktur. Gerçek Gradle derleme, JUnit/Android Lint, APK/DEX/imza/kurulum ve emülatör ekran görüntüsü kontrolleri **yapılmadı**.

Android CI ortamında önce güncel kaynak ZIP depoya yüklenmeli, ardından Gradle/Android SDK ile gerçek derleme ve cihaz testleri çalıştırılmalıdır. Eski APK yeni diye yeniden adlandırılamaz.
