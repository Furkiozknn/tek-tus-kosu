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

## Sonraki tur (v0.4)

- [ ] Çatı ritmi: müzik vuruşuna hizalı parça dizileri (isteğe bağlı mod)
- [ ] Yeni öğeler: çöken bina (üstündeyken alçalır), rüzgâr; bot desteğiyle
- [ ] Kostüm başına küçük görsel iz (parçacık rengi)
- [ ] Günlük koşu için paylaşılabilir sonuç metni (ör. "Tek Tuş Koşu 16.09 — 812 m, 3. deneme")
- [ ] Mobil: dikey yerleşim denemesi, gerçek cihazda dokunma testi
- [ ] Android dışa aktarma (JDK + Android SDK kurulumu gerekir)
- [ ] itch.io web yayını (Furki'nin onayıyla)
