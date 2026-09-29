# Tasarım — arayüz yenilemesi (29 Eylül 2026)

Hedef: oyuncu tanıtım videosundan (`assets/sosyal/tek-tus-kosu-dikey.mp4`) geldiğinde aynı dünyayı
bulsun. Çekirdek mekanik (tek tuş koşu, ritim modu, desenler, bot ve testler) **aynen** kaldı;
değişen görünüm, arayüz, dil, ilk oyun öğretmesi ve geri bildirim.

## 1. Videodan çıkarılan stil rehberi

Kareler ffmpeg ile çıkarıldı, renkler piksel örneklenerek alındı (kare 2,2 sn ritim sahnesi; 4,6 sn
kâğıt kartı; 3,0 sn histogram; 0,5 sn CTA). Diğer oyunların paleti kopyalanmadı: bu oyunun videosu
pembe / mürekkep / kâğıt / sarı / cam göbeği.

| Rol | Kod | Videoda nerede |
|---|---|---|
| Mürekkep (zemin bloğu, panel) | `#120d1f` | histogram paneli |
| Gece gökyüzü | `#201b2d` | ritim sahnesi zemini |
| Şehir silueti | `#2a2636` (oyunda iki katman `#272238` / `#2d283f`) | basamaklı siluet |
| Kâğıt (metin, zemin çizgisi, kart) | `#f5edfe` | "ZIPLA" kartı, histogram çubukları |
| **Oyuncu, vurgu, seçili** | `#fd2c88` | pembe yuvarlatılmış kare |
| **Tehlike** | `#ffc21a` | sarı üçgenler |
| Altın, kıl payı | `#22e4ff` | histogram çubuğu (cam göbeği) |
| Birincil düğme | `#b399ff` | "Tarayıcıda oyna" düğmesi |
| Koyu şarap tema | `#52001a` (video `#6b0017`) | geçiş kareleri |

- **Yazı tipleri:** Instrument Sans (Regular/Bold) gövde ve başlık; JetBrains Mono (BÜYÜK HARF,
  geniş harf aralığı) etiketler, HUD ve küçük bilgi. Simgeler (★ ✓ ■) yedek `simgeler.ttf`. Lisanslar
  `assets/fonts/LISANS-*.txt`.
- **Şekil dili:** düz renk, gölgesiz, dış çizgisiz; koşucu yuvarlatılmış kare (göz: dikey ince
  çizgi), engeller sarı üçgen / dikdörtgen, zemin koyu blok + ince kâğıt çizgi, siluetler basamaklı
  dikdörtgen bloklar. Videodaki ince pembe dikey vuruş çizgileri oyunda zıplama vuruşu işareti.
- **Rol dağılımı:** pembe = sen, sarı = öldürür, cam göbeği = toplanır, mor = tıkla.
- **Hareket:** giriş 180–260 ms ease-out (`UI.GIRIS` 220 ms), 40 ms arayla sıralı belirme, düğme basışı
  90 ms %96 ölçek; ekran geçişi pembe renk bandı 260 ms örtme + 200 ms açma (`Gecis`); zıplama /
  iniş ezilmesi ve tema rengi geçişi (2 sn) korundu. Yaylanma yok.

## 2. Ekranlar

1. **Başlangıç:** slogan (mono, `TEK TUŞ · TAM RİTİM`), başlık, **büyük OYNA** (mor, odak burada), tek
   satır nasıl oynanır, küçük ikincil düğmeler (Ritim · Günlük koşu / Karakter · Başarımlar · Ayarlar),
   alt solda rekor + altın, alt sağda küçük görev listesi, sağ üstte dil düğmesi (TR/EN), masaüstünde
   Çıkış.
2. **HUD:** solda büyük mesafe + cam göbeği altın sayısı, sağda mono en iyi + duraklat. Rüzgâr etiketi
   yalnız rüzgârda. İpucu tek satır.
3. **Duraklat:** kâğıt kart: Devam (birincil), Baştan, Ayarlar (ses + dil açılır), Menü. Esc/P.
4. **Oyun sonu:** kâğıt kart: KOŞU BİTTİ, büyük skor, şehir ışıkları şeridi, pembe rekor satırı
   (**YENİ REKOR!** damgası), altın/vuruş/sapma, görevler, ritimde histogram; odak birincil
   **Tekrar**'da; dokun/Boşluk ile de yeniden başlar.
5. **Ayarlar:** Müzik, Efektler, **Dil** (Türkçe/English), tam ekran, sarsıntı, titreşim, kontrast, rahat mod.
6. Karakter, Başarımlar, Ritim: aynı kâğıt kart dili.

## 3. Dil (TR/EN)

`scripts/ceviri.gd`: kaynak dil Türkçe, `tr("Türkçe metin")` anahtardır; EN tablosu 149 anahtar.
Varsayılan `OS.get_locale_language()` (web'de tarayıcı dili): `tr` ise Türkçe, değilse İngilizce.
Menüdeki TR/EN düğmesi, Ayarlar ve duraklat kartı dili değiştirir; tercih kayıtta `ayarlar.dil`
(yeni anahtar, eski kayıtlarda yok = otomatik; hiçbir eski anahtar değişmedi). Görev metinleri kayıtta
biçimlenmiş Türkçe olarak saklı kalır; gösterirken şablondan (`Gorevler.metin_ad`) çevrilir.
Paylaşım metni (tarih biçimi, "Günlük 16.09.2026") Türkçe kaldı. Testler koddaki her `tr()` anahtarını,
sahne metinlerini, veri metinlerini (görev/başarım/şarkı/kostüm/tema) ve biçim belirteçlerini denetler.

## 4. Oynanış hissi

| Konu | Karar | Gerekçe / ölçü |
|---|---|---|
| Girdi gecikmesi | Değişmedi | `tools/his_olc.gd`: olay → zıplama 16,5 ms ort (%95 16,8), olay → hareket 16,9 ms (%95 17,5); ≈ bir kare, oyun ek gecikme eklemiyor. Önce 16,6 / 17,0 ms: aynı. |
| Kojot | 80 ms **korundu** | Ölçülen tam güç penceresi 4 kare (83 ms). 100 ms denendi (6 kare, 117 ms): ritim deseni kapısı (`diken0`, Gece Koşusu) bozuldu, çünkü vuruş penceresi 80 ms kojotla ölçülmüştü. Geri alındı. |
| Tampon | 120 ms korundu | 7 kare (133 ms) penceresi ölçüldü; standart aralıkta. |
| Geri bildirim | Eklendi | Ölümde 140 ms pembe flaş (yalnız sarsıntı ayarı açıkken) + mevcut sarsıntı; cam göbeği altın parçacığı; pembe rekor patlaması; tam vuruş yazısı pembe. Zıplama/iniş tozu, ezilme, ses korundu. |
| Zorluk eğrisi | Değişmedi | 6 tohum × 2 dk normal + 3 tohum × 2 dk ritim: 0 ölüm. |
| İlk oyun | Öğretme dizisi | Koşu sayısı 0 iken: (1) "Zıpla: Boşluk ya da dokun" ilk zıplamaya kadar, (2) "Basılı tut: daha yüksek · havada bir kez daha zıpla" 3,2 sn, (3) alçak tavan 260 px yaklaşınca "Sarı tabelanın altında KISA dokun" 3 sn. Sonraki oyunlarda yalnız 4 sn'lik tek satır (önce her oyunda üç satır). |

Bir uyarı: bot ölçümü insanı temsil etmez. Tepki bandı (`Bot.gecikme_aralik`) yalnız video kaydı için;
oyunun insan hissi ayrıca elle oynanarak (tarayıcıda) doğrulandı, ama gerçek telefonda denenmedi.

## 5. Önce / sonra

| | önce | sonra |
|---|---|---|
| Test | 961 | **1048** |
| `index.pck` | 863 548 B | 1 109 080 B (+245 KB: iki yazı tipi ailesi, PNG'ler koda gitti) |
| `index.wasm` / `index.js` | 39 514 754 / 279 815 B | aynı |
| Kare süresi normal (bot, 900 kare, vsync kapalı) | 2,26 ms · 442 FPS | 1,98 ms · **504 FPS** |
| Kare süresi ritim | 2,23 ms · 448 FPS | 2,05 ms · **488 FPS** |
| Girdi gecikmesi | 16,6 ms | 16,5 ms |

Görseller: `docs/tasarim/once-*.png` (önce) ve `yayin/ekran-*.png`, `yayin/tanitim.gif` (sonra).
Efektler `intel-uhd-2d-tavani` sınırının altında: parçacıklar bedava, glow/bloom yok, gölge yok.

## 6. Araçlar

`tools/tema_uret.gd` (→ `assets/tema.tres`), `tools/varlik_uret.gd` (düz sprite), `tools/sahne_uret.gd`
(arayüz sahneleri), `tools/his_olc.gd`, `tools/fps.gd`, `tools/kayit.gd` + `tools/kayit.ps1` (ham klip),
`tools/ekran_goruntusu.gd` (ekran görüntüleri, kapak). Eski pixel-art PNG'ler `_eski/sprites/` altında.
