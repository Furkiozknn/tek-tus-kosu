# CLAUDE.md — Tek Tuş Koşu

Godot 4.7.2 (GL Compatibility), GDScript, 2D yandan görünüm, sonsuz koşu. Arayüz ve kod dili Türkçe.
Proje sahibi: Furki. İlgili kurallar: `D:\Claude Projeleri\oyun-terminalleri\GELISTIRME-1-ORTAK.md`.

## Kurallar

- Push, GitHub deposu açma, itch.io yükleme **yok** — Furki açıkça onaylamadan yapılmaz. `yayin/` yalnız hazırlık.
- Dosya kalıcı silinmez; eskiyen dosya `_eski/` klasörüne taşınır.
- Higgsfield kullanılmaz.
- Görseller ve sesler **koddan** üretilir (`tools/varlik_uret.gd`, `tools/ses_uret.gd`, `tools/muzik_uret.gd`).
  PNG/WAV'ı elle düzenleme; üreticiyi değiştir, yeniden üret.
- Sahneler (`scenes/*.tscn`, `scenes/parcalar/*.tscn`) `tools/sahne_uret.gd` ile üretilir. Elle düzenleme;
  üretici yeniden çalışınca üzerine yazılır.
- Denge sabitleri yalnız `scripts/ayarlar.gd` içinde.
- GDScript'te `:=` ile tür çıkarımı Variant dönen ifadelerde hata verir (Dictionary/Array elemanları,
  `min/max`, üçlü ifade). Böyle yerlerde türü açık yaz (`var x: float = ...`). Derlenmeyen bir betik
  testlerde "Nonexistent function new" olarak görünür.
- Fizik geri çağrısı içinde çarpışma nesnesini kapatma/ekleme: `set_deferred` kullan.
- **Yeni `class_name` ekledikten sonra `sahne_uret`'ten önce `--import` çalıştır.** Aksi hâlde sınıfı kullanan
  betik (ör. `parca.gd`) derlenmez; eskiden sahneler betiksiz kaydedilip testler "Parca değil" diye
  düşüyordu. `sahne_uret` artık derlenmeyen betikte durur (`_betik()`).
- Godot'nun gömülü yazı tipinde (Open Sans) ★ ☆ ✓ ✗ ← ↑ → ↓ ■ □ yok. Masaüstünde sistem yazı tipi
  örter, **web'de kutu çıkar**. Bu simgeler `assets/fonts/simgeler.ttf` yedeğinden gelir
  (`Simgeler.kur()`, üretici `tools/simge_fontu.py`). Yeni bir simge kullanacaksan önce oraya ekle.
- `JavaScriptBridge.eval` JS `true/false` değerini 1/0 (int) döndürebilir; sonucu `== true` ile
  karşılaştırma (int == bool çalışma zamanı hatası, release yapıda sessizce işlevi keser).

## Komutlar

```
G=godot   # Windows: C:\Users\furki\AppData\Local\Microsoft\WinGet\Links\godot.exe
$G --headless --path . -s res://tools/proje_ayarla.gd
$G --headless --path . -s res://tools/varlik_uret.gd
$G --headless --path . -s res://tools/ses_uret.gd
$G --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_oyun.wav --ruh hizli --tohum 11
$G --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_menu.wav --ruh sakin --tohum 4
$G --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_ritim2.wav --ruh neseli --tohum 7
# (yalnız simge seti değişirse) python3 tools/simge_fontu.py   # fonttools gerekir
$G --headless --path . --import
$G --headless --path . -s res://tools/sahne_uret.gd
$G --headless --path . --import
$G --headless --fixed-fps 60 --path . -s res://tests/testler.gd     # beklenen: "SONUÇ: N geçti, 0 hata"
# itch ekran görüntüleri + kapak (pencere açar; Linux'ta xvfb-run ile):
$G --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 60 --path . -s res://tools/ekran_goruntusu.gd
$G --headless --path . --export-release "Web" build/web/index.html
$G --headless --path . --export-release "Windows Desktop" build/windows/tek-tus-kosu.exe
```

PC'de aynı anda tek Godot çalışsın: `D:\Repolar\.godot-kilit` kilidini kullan
(`D:\Claude Projeleri\oyun-terminalleri\tek-tus-kosu-dogrula.ps1` bunu yapar).

## Mimari özeti

- `oyun.gd` ana döngü: parça üret/sil, hız, puan, görev sayaçları (`ist`), tema, efekt, ölüm tekrarı.
  `yeniden_baslat()` sahneyi yüklemeden sıfırlar. Test değişkenleri: `bot_modu`, `sabit_hiz`,
  `parca_sirasi`, `tohum`, `sira_bitince_duz`, `kayit_yap`, `olum_tekrari_acik`.
- Olaylar grup çağrısıyla gelir: `call_group("oyun", "altin_toplandi" | "yakin_kacis", ...)`.
- `parca.gd` her parçanın tehlike ve tavan aralıklarını verir; `bot.gd` bunlara bakarak zıplar
  (tavan altında kısa sıçrama, ikinci zıplama yok).
- Parça seçimi `parca_rng` ile ve `Ayarlar.hiz_mesafede(parça başlangıcı)` hızına göre yapılır; parça
  dizisi yalnız tohuma bağlı (kare hızına, oyuncunun davranışına bağlı değil). Görevler ayrı `rng`.
  Parça seçimine yeni rastgelelik eklerken `parca_rng` kullan, yoksa günlük koşu bozulur.
- Günlük koşu: `Gunluk.secili` (menü) → `oyun.gunluk`. Tohum `Gunluk.tohum(tarih)`. Kayıtta
  `gunluk` sözlüğü; hayalet ayrı dosyada (`Hayalet.dosya_yolu()`), yalnız günün rekorunda yazılır.
  Testler tarihi `Gunluk.tarih_ezme` ile sabitler.
- İşaretler (`Isaret`) ve hayalet sprite'ı oyun kök düğümünün çocuğu; `yeniden_baslat` yeniden kurar.
- `Ses` statik; ilk çağrıda kök düğüme havuz ekler. Web'de ses ilk kullanıcı girdisinden sonra başlar
  (tarayıcı kuralı; konsoldaki AudioContext uyarısı normal).
- Kayıt `[oyuncu]` bölümünde; `Kayit.yukle()` bozuk dosyada yedeğe döner.
- Çürük iskele (`Coken`, `Zemin` alt sınıfı): `Oyuncu._zemine_bildir()` ayağın altını yoklar,
  `basildi()` → `ISKELE_COKME` sn sonra çarpışma kapanır. Olaylar `call_group("oyun",
  "iskele_catirdadi" | "iskele_coktu")`. Bot için tehlike aralığı iskelenin ilk `ISKELE_GUVENLI` px'inden sonra başlar.
- Rüzgâr (`Ruzgar`, parça çocuğu): `oyun.ruzgar_gucu(x)` her kare `oyuncu.ruzgar`'a yazılır; yalnız
  havadayken yatay hıza eklenir. Bot `ruzgar` Callable'ı ile menzil ve iniş hesabına katar. HUD: `%RuzgarEtiketi`.
- Dikey telefon: `DikeyUyari` (CanvasLayer) menü ve oyuna eklenir; dikeyde perde açılır, oyunda koşu
  duraklar. Web'de dokunmatik cihazda Başla'ya basınca tam ekran + yatay kilit denenir (`menu._telefonda_tam_ekran`).
  Testler `DikeyUyari.zorla` ile yönü sabitler.
- Ritim koşusu (`Ritim`, `Ritim.secili` → `oyun.ritim`): hız `Ritim.HIZ` sabit; `parca_sirasi` boşsa
  parçalar `Ritim.parca_uret()` ile koddan kurulur (sahne yok, `set_meta("desenler")`). Vuruş ızgarası
  `oyun._izgara0` (başlangıç + ses gecikmesi). Olay vuruşları `_ritim_olaylar`; zıplamada
  `_ritim_degerlendir()`. Müzik `Ses.muzik(..., true)` ile baştan; `_ritim_ses_hizala()` kaymada müziği
  sarar (oyun zamanı yetkili). Headless'ta müzik çalmaz (`Ses.muzik_konumu() == -1`), hizalama atlanır.
  Şarkılar `Ritim.SARKILAR` (müzik, gerçek BPM, rekor/ölüm anahtarları); oyun `ritim_sarki` ve `_adim` tutar.
  Hız bütün şarkılarda 300 px/sn — engel geometrisi hıza bağlı. Yeni şarkının BPM'i 2 vuruşta ≥ 223 px
  (tam zıplama boyu) bırakmalı: 300 px/sn'de en fazla ~160 BPM. BPM'i WAV'ın gerçek temposundan yaz
  (`22050·15 / round(22050·15/bpm)`). Ses gecikmesi ayarı `ayarlar.ritim_gecikme` (ms) ızgarayı kaydırır;
  `_ritim_sapmalar` → `Ritim.gecikme_onerisi()` → sonuçta `%GecikmeDugme`.
  Günün ritmi: `Ritim.gunluk_secili` → `oyun.ritim_gunluk`; şarkı `Ritim.gunun_sarkisi(tarih)`, tohum
  `Ritim.gunun_tohumu(tarih)` (günlük koşudan ayrı), kayıt `gunluk_ritim` (`Ritim.gunluk_durum/gunluk_isle`).
  `oyun.gunluk` bu kipte false kalır (hayalet, günlük seri ve `gunluk300` başarımı çalışmaz).
  Desen eklerken: olaylar yalnız 0/2. vuruşta (tam zıplama 1,86 vuruş sürer), sonra
  `bot_stres --ritim` ve `--vurus -175 / 150` ile pencereyi yeniden ölç.
- Günlük seri kayıtta `gunluk_seri`; paylaşım metni `Gunluk.paylasim_metni()`. Web'de dokunmatik
  cihazda `navigator.share`, diğerlerinde panoya kopyalama (`oyun._paylas`).

## Parça tasarım kuralları

- Uçlarda 60 px güvenli zemin; yüksek bloklar parça başından ≥ 360 px içeride.
- Alçak tavan alt kenarı y=212: kısa sıçrama (≈35 px) sığar, tam zıplama (≈96 px) sığmaz.
- Zorluk 0 = nefes parçası (tehlikesiz). Zorluk eşikleri: 2 → 280 px/sn, 3 → 360 px/sn.
- Her yeni parça testte en düşük ve en yüksek hızda bot ile geçilmeli; ayrıca
  `--fixed-fps 60 ... tools/bot_stres.gd -- --tohumlar 1,...,24` ile uzun koşularda ölüm olmamalı
  (`--fixed-fps` olmadan gerçek zamanda koşar: 24 tohum 72 dk sürer).
- Botun iniş noktası (hız × 0,743 sn / 2) bir sonraki tehlikenin üstüne düşmemeli: art arda
  tehlikeler arasında en az ~260 px ya da birleşik tek tehlike bırak. Bu kılavuzdur; çok parça bilerek
  daha sıkı. Asıl ölçüt uzun bot stresidir (v0.5'te 35'te tabancadan hemen sonraki çukur ancak
  yeni parça dizileriyle ortaya çıktı: bot pistondan kaçarken ikinci zıplamayla çukura iniyordu).
- Rüzgâr bölgesi parçanın başından en az 120 px içeride başlamalı; karşı rüzgâr altındaki çukur, en düşük
  hızda (280 − 80) × 0,743 ≈ 150 px'ten dar olmalı.
- Hareketli ve tek yönlü kirişlerin yan yüzü öldürmez (`Oyuncu._duvara_carpti`).
- Çatı hizasının altında duvara çarpmak "çukur" ölümü sayılır (boşluğa düşülmüştür).
- Çürük iskele parçaları 150 px'lik dilimlerdir (her dilim ayrı tetiklenir). Dilimin ilk 60 px'i
  en düşük hızda bile çökmeden koşulur; dilim sonrası katı zemin ya da başka dilim olmalı.

## Doğrulama

- v0.8 (bulut): 782 test geçti; web'de (Chromium) ritim paneli → Günün ritmi → koşu → sonuç → Paylaş
  (pano: "Tek Tuş Koşu · Günün ritmi (Gece Koşusu) 16.09.2026 …"); dört düğmeli sonuç paneli testte sığıyor.
- v0.7 (Windows 11): 765 test; bot stresi 8 tohum, iki şarkıda ritim stresi 4'er tohum, 0 ölüm; web pck 707 KB.
- v0.7 (bulut): 765 test geçti. 128 BPM: bot 12 tohum × 3 dk 0 ölüm (10 desen); kaydırmalı oyuncu
  −175 / 0 / +150 ms 0 ölüm, −200 ve +175 ms'de ölüm (150 BPM ile aynı pencere).
- v0.6 (bulut): 740 test geçti. Ritim: bot 12 tohum × 3 dk 0 ölüm (10 desenin hepsi); vuruşa göre
  kaydırarak zıplayan oyuncu 8 tohum × 3 dk: −175…+150 ms 0 ölüm, −200 ms ve +175 ms'de alçak tavan
  dikeninde ölüm (pencerenin sınırı). Çukur 140 → 120 px daraltılarak erken sınır −125'ten −175 ms'ye genişledi.
- v0.6 (Windows 11): 742 test geçti; bot stresi 8 tohum ve ritim stresi 4 tohum, 0 ölüm; dışa aktarmalar tamam
  (exe 107 MB, web pck 570 KB).
- v0.1 (bulut + Windows): 171 test geçti; Windows ve Web dışa aktarma çalıştı.
- v0.2 (bulut, Linux headless): 388 test geçti, 0 hata. Web sürümü Playwright/Chromium ile:
  menü, karakter paneli, ayarlar paneli, fareyle başlatma, oyun, ölüm tekrarı, sonuç paneli.
- v0.3 (bulut): 558 test geçti; bot stresi 24 tohum × 3 dk, 0 ölüm; web'de günlük koşu açıldı.
- v0.2 (Windows 11): aynı akış + `tools/ekran_goruntusu.gd`; 388 test geçti, dışa aktarmalar tamam.
- v0.5 (bulut): 714 test geçti; bot stresi 32 tohum × 3 dk, 0 ölüm, 43 parçanın hepsi görüldü. Web'de
  (Chromium, telefon emülasyonu) dikey → perde + duraklama, yatay → Devam; dokunuşla tam ekran açıldı.
- v0.5 (Windows 11): 714 test geçti; bot stresi 8 tohum, 0 ölüm; dışa aktarmalar tamam (pck 560 KB).
- v0.4 (Windows 11): 660 test geçti; bot stresi 8 tohum, 0 ölüm; dışa aktarmalar tamam (pck 546 KB).
- v0.4 (bulut): 660 test geçti; bot stresi 24 tohum × 3 dk, 0 ölüm, 40 parçanın hepsi görüldü
  (`bot_stres` artık parça kullanımını yazar). Web'de (Chromium) günlük sonuç → Paylaş → pano
  metni doğrulandı; ★ ve ✓ simgeleri web'de görünüyor.
- v0.3 (Windows 11): 558 test geçti; bot stresi 8 tohum × 3 dk, 0 ölüm; ekran görüntüleri ve iki dışa
  aktarma tamam. Ekran görüntüleri buluttakinden yalnız GPU gürültüsü kadar farklı (kanal farkı ≤ 30).
  PNG/WAV üreticileri deterministik (bulut ve Windows çıktıları aynı hash). Sahne dosyalarındaki
  `uid` değerleri makineye göre değişir; bu normal. Düğüm `unique_id` değerleri v0.4'ten beri
  `sahne_uret` tarafından düğüm yolundan türetilir (yeniden üretim gereksiz fark yaratmaz).
- Web testinde bilinen durum: Chromium'un AudioContext otomatik oynatma uyarısı (zararsız).
