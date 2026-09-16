# Tek Tuş Koşu — Yol haritası

## Bitti (prototip, 2026-09-16)

- [x] Tek girdi: klavye / gamepad / dokunma / fare; basılı tut = yüksek, havada 1 ek zıplama
- [x] Kojot süresi + zıplama tamponu + değişken yükseklik
- [x] Zamanla artan hız (220 → 460 px/sn), üst sınır
- [x] 12 hazır parça, zorluk 1-3, hıza göre ağırlıklı rastgele seçim, geride kalan silinir
- [x] Mesafe + altın puanı, rekor ve toplam altın kaydı
- [x] Menü, duraklatma, oyun sonu (tek dokunuşla tekrar)
- [x] Otomatik testler (bot ile her parçanın geçilebilirliği, 3 dk bellek/hız testi)
- [x] Windows + Web dışa aktarma

## Sonraki adımlar

- [ ] Windows'ta (PC) gerçek oynanış kontrolü; zıplama hissi ve hız eğrisi ayarı
- [ ] Pixel art: oyuncu koşu/zıplama animasyonu, zemin karoları, diken, blok, altın (Pixelorama)
- [ ] Parallaks arka plan (2-3 katman)
- [ ] Ses: zıplama, altın, ölüm, rekor (rFXGen) + müzik; ses aç/kapa
- [ ] Parça sayısını 25+'a çıkar; yeni öğeler: hareketli platform, alçak tavan, yükselen diken
- [ ] Görev/başarım (ör. "tek koşuda 50 altın")
- [ ] Toplanan altınla kozmetik karakter kilidi açma
- [ ] Ekran sarsıntısı, toz parçacıkları, ölüm animasyonu (tümleşik GPU için hafif tut)
- [ ] Mobil: dikey/yatay kararı, güvenli alan (çentik) payı, titreşim
- [ ] Android dışa aktarma (JDK + Android SDK kurulumu gerekir)
- [ ] itch.io sayfası + web yayını (Furki'nin onayıyla)
