# Tek Tuş Koşu — Yol haritası

## Bitti — prototip (v0.1, 2026-09-16)

- [x] Tek girdi: klavye / gamepad / dokunma / fare; basılı tut = yüksek, havada 1 ek zıplama
- [x] Kojot süresi + zıplama tamponu + değişken yükseklik
- [x] Zamanla artan hız (220 → 460 px/sn), üst sınır
- [x] 12 hazır parça, zorluk 1-3, hıza göre ağırlıklı rastgele seçim, geride kalan silinir
- [x] Mesafe + altın puanı, rekor ve toplam altın kaydı
- [x] Menü, duraklatma, oyun sonu (tek dokunuşla tekrar)
- [x] Otomatik testler (bot ile her parçanın geçilebilirliği, 3 dk bellek/hız testi)
- [x] Windows + Web dışa aktarma

## Bitti — geliştirme turu 1 (v0.2, 2026-09-16)

- [x] Kodla üretilmiş pixel art: 5 kostümlü koşu/zıplama/düşüş/takla/bekleme/ölüm animasyonu,
      çatı ve tuğla karoları, diken, blok, tavan, piston, platform, altın
- [x] 4 katmanlı parallaks (gökyüzü gradyanı, yıldızlar, ay, uzak/yakın şehir)
- [x] Ses efektleri + menü/oyun müziği (koddan), Muzik/Efekt veri yolları, ses ayarı
- [x] 26 parça; yeni öğeler: alçak tavan, piston, hareketli platform, nefes parçaları, riskli rotalar
- [x] Kıl payı kaçış ödülü
- [x] Görev sistemi (3 eşzamanlı görev, seviye), altın ödülleri
- [x] Kostüm dükkânı (yalnız kozmetik)
- [x] Ölüm tekrarı + vurgu, sahne yüklemeden hızlı yeniden başlama
- [x] Tema döngüsü (500 m), yağış
- [x] Ayarlar: ses, tam ekran, sarsıntı, yüksek kontrast, rahat mod (ayrı rekor)
- [x] Kayıt yedeği ve eski kayıt taşıma
- [x] Juice: ezilme/uzama, toz, altın serisi perde yükselişi, sarsıntı, rekor efekti
- [x] itch.io paket taslağı (`yayin/`) — yükleme yapılmadı

## Bitti — geliştirme turu 2 (v0.3, 2026-09-16)

- [x] Günlük tohum koşusu (tarihten tohum), günün rekoru ve deneme sayısı
- [x] Hayalet rakip: günün en iyi denemesi sonraki denemelerde yanında koşar
- [x] Parça seçimi mesafeye bağlı hızla → parça dizisi kare hızından bağımsız, belirlenimci
- [x] Rekor / son ölüm / hayalet bayrakları; koşu sonu şehir ışıkları haritası (önceki ölümler)
- [x] 11 başarım (+25 altın), menü paneli, koşu içi duyuru; tavan/piston geçiş sayacı
- [x] 36 parça (zincirleme kiriş, tavan+piston, kiriş merdiveni, asansör çukuru…)
- [x] Titreşim ayarı (ölümde); tek yönlü kirişlerin yanına çarpmak artık öldürmüyor
- [x] Bot stres aracı (`tools/bot_stres.gd`)

## Bitti — geliştirme turu 3 (v0.4, 2026-09-16)

- [x] Yeni öğe: çürük iskele (basınca 0,5 sn sonra çöker), 4 parça (37–40), bot desteği
      ("alçalan bina" yerine — gerekçe README'de)
- [x] Kostüm izi: toz rengi kostüme göre, Neon/Altın Taç'ta sürekli iz
- [x] Günlük koşu paylaşım metni (telefonda paylaşım menüsü, diğerlerinde pano) + günlük seri
- [x] 12. başarım (Hafif adımlar: tek koşuda 8 çürük iskele); iskele geçiş sayacı
- [x] Web düzeltmesi: ★ ☆ ✓ simgeleri web'de kutu çıkıyordu → yedek simge yazı tipi
- [x] Boşluğa düşüp karşı duvara çarpmak artık "çukur" ölümü (tekrar yazısı doğru)
- [x] `bot_stres` parça kullanım özeti

## Bitti — geliştirme turu 4 (v0.5, 2026-09-16)

- [x] Rüzgâr öğesi (havadayken yatay hıza eklenir), 3 parça (41–43), bot desteği, HUD yazısı, yön bayrakları
- [x] Telefon: dikeyde "yan çevir" perdesi + duraklama; web'de dokunuşla tam ekran + yatay kilit
- [x] 35_cift_piston_cukur: çukur pistondan uzağa alındı (uzun streste bot ölümü)
- [x] `sahne_uret` derlenmeyen betikte durur (yeni class_name + import sırası tuzağı)

## Bitti — geliştirme turu 5 (v0.6, 2026-09-16)

- [x] Ritim koşusu: 150 BPM / 300 px/sn vuruş ızgarası, koddan üretilen ölçü desenleri (10 desen, 2 zorluk)
- [x] Vuruş lambaları, "Tam vuruş ×N" / "Erken-Geç N ms" geri bildirimi, ayrı rekor ve ölümler
- [x] Müzik döngüsü örnek düzeyinde kesintisiz; duraklatınca müzik durur; kayınca müzik yeniden hizalanır
- [x] 13. başarım (Vuruşu yakala); menüde Ritim düğmesi, Çıkış sol üste taşındı
- [x] `bot_stres --ritim --vurus <ms>`: zamanlama penceresi ölçümü (−175…+150 ms yaşanır)

## Bitti — geliştirme turu 6 (v0.7, 2026-09-16)

- [x] Ritim: ikinci şarkı "Çatı Neşesi" (128 BPM, vuruş 140,6 px), şarkı paneli, şarkı başına rekor ve ölümler
- [x] Ritim: ses gecikmesi ayarı (−150…+300 ms) + koşu sonunda ölçülen sapmadan öneri düğmesi
      (ayrı kalibrasyon ekranı yerine)
- [x] `bot_stres --sarki`

## Bitti — geliştirme turu 7 (v0.8, 2026-09-16)

- [x] Günün ritmi: tarihten şarkı + tohum, ayrı günlük rekor/deneme/ölümler, paylaşım metni
- [x] Ritim koşusunda başlangıç ipucu (lambalar, kısa dokunuş)
- [x] Sonuç paneli dört düğmeye kadar (Tekrar | Paylaş | Gecikme | Menü)

## Sonraki tur (v0.9)

- [ ] Günün ritmi hayaleti (günlük koşudaki gibi)
- [ ] Ritim: şarkıya özel desen (ör. 128 BPM'de senkoplu çift diken) — yeni desen yalnız ölçülmüş pencereyle
- [ ] Paylaşım metnine itch adresi (yayından sonra)
- [ ] Gerçek telefonda dokunma, tam ekran ve paylaşım menüsü denemesi
- [ ] Android dışa aktarma (JDK + Android SDK kurulumu gerekir)
- [ ] itch.io web yayını (Furki'nin onayıyla)
