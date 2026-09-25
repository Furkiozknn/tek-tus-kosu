# Sürüm geçmişi — Tek Tuş Koşu

README'nin ilk ekranı bir sürüm dökümüyle doluydu; okumaya gelen kişi oyunun ne
olduğunu görmeden önce on dokuz satırlık bir değişiklik listesiyle karşılaşıyordu.
Liste silinmedi, buraya taşındı.

Güncel sürümün notları GitHub'da da duruyor:
<https://github.com/Furkiozknn/tek-tus-kosu/releases>

## Yayımlanmamış (`main`, v1.7.3'ten sonra)

Oynanış değişmedi; yeni bir sürüm etiketi yok.

- **Test takımı 853 → 961.** Ritimdeki on iki olaylı desenin her biri, üç
  şarkının her birinin vuruş aralığında (120 / 140,6 / 128,6 px) vuruşta zıplayan
  bir botla ayrı ayrı koşuluyor. Bunun için ritim üreticisinde *seçmek* ile
  *kurmak* ayrıldı (`Ritim.desenleri_sec` / `Ritim.parca_kur`); rastgele akış
  aynı kaldı.
- **CI test kapısı** (`tests/kapi.sh`): çıkış koduna ek olarak günlükte `SONUÇ`
  satırı, en az `TEST_TABANI` geçen doğrulama ve `SCRIPT ERROR` yokluğu aranıyor.
- **Kırık kaynak referansı kapısı** (godot-refcheck, SARIF).
- **Yapı iş akışı:** Windows + Web paketleri artifact olarak; web paketi
  headless Chromium'da duman testinden geçiyor (`tools/web_duman.py`); isteğe
  bağlı Pages yayını (Pages önce bir kez elle açılmalı).

## v1.7.3 — belge/lisans/CI turu (22 Eylül 2026)

Oyun kodu v1.7.1 ile aynı; yayımlanmış derlemeler değişmedi. MIT lisansı,
`main`'e her push'ta ve her pull request'te **853 testin** koştuğu CI (Godot
4.7.2, Linux headless, Git LFS çekilerek), README ve CLAUDE.md'nin kodla
hizalanması, makineye özel yolların kaldırılması.

## Önceki sürümler

Aşağıdaki döküm README'den olduğu gibi taşındı.

**Durum:** v1.7.2 — belge/lisans/CI turu (2026-09-21); oyun kodu v1.7.1 ile aynı.
v1.7.1 — geliştirme turu 12. Ritim koşusu sonuç panelinde vuruş sapması histogramı (çok erken /
erken / tam / geç / çok geç) ve ritim koşusuna özel üç başarım: Metronom (100 tam vuruş), Üç şarkı (her şarkıda 300 m),
Ritim müdavimi (günün ritmini 5 ayrı gün); başarım paneli 16 başarımla iki sütun. v1.6: Ritim panelinde şarkı önizlemesi (düğmeye odaklanınca/üzerine gelince
şarkının başından 2 sn; menü müziği o sırada duraklar) ve günün ritmi için son 7 günün rekor geçmişi (panelin
açıklama satırında). v1.5: Fırtına Hattı'nda şarkıya kilitli "Fırtına" teması (yağmur,
yıldızsız gök) ve ölçü başlarında şimşek perdesi (yalnız görsel; sarsıntı ayarı kapalıyken yok). v1.4: Özel web kabuğu (`yayin/web-kabuk.html`): oyunun gece paletinde
yükleme ekranı, yüzdeli ilerleme çubuğu, kontrol ipucu, azaltılmış hareket desteği. v1.3: Üçüncü şarkı **Fırtına Hattı** (140 BPM, "gergin" ruh): diken ağırlığı
×1,5 ile çift dikenli ölçüler (ikili, arka vuruş) ×2,25 sıklıkta, alçak tavan daha seyrek; ritim paneli üç şarkıyla temel
çözünürlüğe sığacak biçimde sıkılaştırıldı. (v1.2: şarkıya özel desen ağırlığı: Çatı Neşesi'nde alçak tavan daha
sık, çukur daha seyrek; şarkı düğmelerinde karakter ipucu; paylaşım metni için `Ayarlar.ITCH_ADRESI`. v1.0: ritimde
**vuruş ipucu sesi**: zıplama vuruşundan bir vuruş
önce tık (sayım gibi; ritim panelinden kapatılır). (v0.9: Günün ritminde **hayalet rakip** (günün en iyi denemesi,
vuruş ızgarasına hizalı) ve **arka vuruş desenleri** (1. ve 3. vuruşta diken; 13 desen). (v0.8: günün ritmi —
her gün tarihten seçilen şarkı ve çatı dizisi, ayrı günlük rekor ve paylaşım; ritim koşusunda başlangıç ipucu. v0.7: ikinci şarkı
(128 BPM), şarkı başına rekor, ses gecikmesi ayarı ve öneri. v0.6: **ritim koşusu** —
engelleri müziğin vuruşlarına hizalı, koddan üretilen ayrı kip. v0.5: rüzgâr, telefonda dikey uyarısı + tam ekran. v0.4: çürük iskele, günlük seri ve paylaşım, kostüm izleri, web simge düzeltmesi.
v0.3: günlük koşu + hayalet, işaretler, şehir haritası. v0.2: pixel art, ses/müzik, görevler,
kostümler, ölüm tekrarı, ayarlar.)
