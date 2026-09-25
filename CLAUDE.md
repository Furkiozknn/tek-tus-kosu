# CLAUDE.md — Tek Tuş Koşu

Godot 4.7.2 (GL Compatibility), GDScript, 2D yandan görünüm, sonsuz koşu. Arayüz ve kod dili Türkçe.
Proje sahibi: Furki. Geliştirme makinesinde ayrıca ortak kurallar dosyası var
(`oyun-terminalleri/GELISTIRME-1-ORTAK.md`) — bu depoda değil.

## Kurallar

- GitHub deposu **var** (`Furkiozknn/tek-tus-kosu`, dal `main`, public — Furki 21 Eylül 2026'da
  onayladı); push serbest ve `main`'e her push'ta `.github/workflows/ci.yml` 961 testi koşar.
  **itch.io yüklemesi yapılmadı** — `yayin/` yalnız hazırlık, yükleme kararı Furki'nin.
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
- Web dışa aktarımı özel kabuk kullanır: `yayin/web-kabuk.html` (`export_presets.cfg` → `html/custom_html_shell`).
  Godot'nun yer tutucuları (`$GODOT_URL`, `$GODOT_CONFIG`, `$GODOT_THREADS_ENABLED`, `$GODOT_HEAD_INCLUDE`,
  `$GODOT_PROJECT_NAME`) ve `#status` / `#status-notice` / `Engine.getMissingFeatures` akışı korunmalı; yalnız
  görünüm değişir. Değişiklikten sonra web'i Playwright ile aç: `python3 tools/web_duman.py build/web` (yükleme ekranı → menü →
  Boşluk ile koşu; Yapi iş akışı da aynısını koşar).
- `JavaScriptBridge.eval` JS `true/false` değerini 1/0 (int) döndürebilir; sonucu `== true` ile
  karşılaştırma (int == bool çalışma zamanı hatası, release yapıda sessizce işlevi keser).

## Komutlar

Yeni klonda **önce** `git lfs pull` (PNG/WAV/TTF LFS'te; çekilmezse 128 baytlık işaretçi dosyalar
gelir ve içe aktarma bozuk varlık üretir) ve `mkdir -p build/web build/windows`
(Godot dışa aktarma hedef klasörü yoksa "The given export path doesn't exist" der).

```
G=godot   # Windows'ta winget kurulumu PATH'e ekler; yoksa godot.exe'nin tam yolunu yaz
$G --headless --path . -s res://tools/proje_ayarla.gd
$G --headless --path . -s res://tools/varlik_uret.gd
$G --headless --path . -s res://tools/ses_uret.gd
$G --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_oyun.wav --ruh hizli --tohum 11
$G --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_menu.wav --ruh sakin --tohum 4
$G --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_ritim2.wav --ruh neseli --tohum 7
$G --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_ritim3.wav --ruh gergin --tohum 5
# (yalnız simge seti değişirse) python3 tools/simge_fontu.py   # fonttools gerekir
$G --headless --path . --import
$G --headless --path . -s res://tools/sahne_uret.gd
$G --headless --path . --import
$G --headless --fixed-fps 60 --path . -s res://tests/testler.gd     # beklenen: "SONUÇ: N geçti, 0 hata"
# CI aynı komutun günlüğünü tests/kapi.sh'a verir (taban: ci.yml → TEST_TABANI). Test ekleyince tabanı yükselt.
$G --headless --fixed-fps 60 --path . -s res://tools/panel_olc.gd   # sonuç paneli 5 kalabalık seviyesinde sığıyor mu
# itch ekran görüntüleri + kapak (pencere açar; Linux'ta xvfb-run ile):
$G --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 60 --path . -s res://tools/ekran_goruntusu.gd
$G --headless --path . --export-release "Web" build/web/index.html
$G --headless --path . --export-release "Windows Desktop" build/windows/tek-tus-kosu.exe
```

Geliştirme makinesinde aynı anda tek Godot çalışsın: depoların ortak üst klasöründeki
`.godot-kilit` dosyasını kullan (`oyun-terminalleri/tek-tus-kosu-dogrula.ps1` bunu yapar;
ikisi de bu deponun dışında). CI'da gerekmez.

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
  Şarkılar `Ritim.SARKILAR` (müzik, gerçek BPM, rekor/ölüm anahtarları, `agirlik` desen türü çarpanları, `aciklama`);
  oyun `ritim_sarki` ve `_adim` tutar. `desen_sec(..., sarki_no)` ağırlığı `desen_agirligi()` ile çarpar; yeni çarpan
  eklerken o şarkı için `bot_stres --ritim --sarki N` ve `--vurus` ölçümünü yinele.
  Hız bütün şarkılarda 300 px/sn — engel geometrisi hıza bağlı. Yeni şarkının BPM'i 2 vuruşta ≥ 223 px
  (tam zıplama boyu) bırakmalı: 300 px/sn'de en fazla ~160 BPM. BPM'i WAV'ın gerçek temposundan yaz
  (`22050·15 / round(22050·15/bpm)`). Ses gecikmesi ayarı `ayarlar.ritim_gecikme` (ms) ızgarayı kaydırır;
  `_ritim_sapmalar` → `Ritim.gecikme_onerisi()` → sonuçta `%GecikmeDugme`. Vuruş ipucu sesi: `_ritim_ipucu_sesi()`
  her vuruş geçişinde bir sonraki vuruş olaysa `tik` çalar (ayar `ritim_ipucu`, botta kapalı, sayaç `_ritim_ipucu_sayisi`).
  Günün ritmi: `Ritim.gunluk_secili` → `oyun.ritim_gunluk`; şarkı `Ritim.gunun_sarkisi(tarih)`, tohum
  `Ritim.gunun_tohumu(tarih)` (günlük koşudan ayrı), kayıt `gunluk_ritim` (`Ritim.gunluk_durum/gunluk_isle`).
  `oyun.gunluk` bu kipte false kalır (günlük seri ve `gunluk300` başarımı çalışmaz). Hayalet var: dosya
  `Hayalet.dosya_yolu("ritim")`, konumlar `_hayalet_taban()` = `_izgara0`'a göre (günlük koşuda `baslangic_x`).
  Desen eklerken: ardışık olaylar arası ≥ 2 vuruş (tam zıplama 1,86 vuruş), alçak tavana ≥ 3 (`desen_sec`
  ölçüler arasında da uygular); 3. vuruşta yalnız diken (çukur/tavan geometrisi parça sonunu aşar). Sonra
  `bot_stres --ritim [--sarki 1]` ve `--vurus -175 / 150` ile pencereyi yeniden ölç.
- Tema: `_tema_secimi()` — ritimde şarkının `tema` anahtarı varsa kilit, yoksa mesafeyle `TEMA_DONGU` (4) tema döner;
  `TEMALAR[4]` "Fırtına" yalnız kilitle gelir (`simsek: true` → `_simsek()` perdesi, `_simsek_rng` tohumdan,
  `sarsinti` kapalıyken yok, sayaç `_simsek_sayisi`). Yeni temayı listenin sonuna ekle, `TEMA_DONGU`'yu değiştirme.
- v1.6: `Ses.onizle(ad, sn)` ayrı `_onizleme` oynatıcısıyla şarkının başını çalar, menü müziğini duraklatır
  (`onizle_durdur()` sürdürür; `onizleme_adi()` test için). Menü: şarkı düğmesi `focus_entered`/`mouse_entered` →
  `_onizle(i)` (yalnız ritim paneli açıkken); Geri ve `basla()` durdurur. Günün ritmi geçmişi `gunluk_ritim_gecmis`
  (`Ritim.gecmis_yaz`, en çok `GECMIS_GUN` = 7 kayıt, aynı gün en iyi kalır); `Ritim.gecmis_metni()` panel açıklama
  satırının yerine geçer (yer kaplamaz; geçmiş yoksa `RITIM_ACIKLAMA`).
- v1.7: `SapmaGrafigi` (`scripts/sapma_grafigi.gd`, sonuç panelinde `%SonSapma`) `son_sonuc["ritim_sapmalar"]`'ı
  `kutula()` ile beş kutuya sayar (sınırlar `Ritim.TAM_VURUS_MS` = 70 ms ve `SapmaGrafigi.UZAK_MS` = 150 ms).
  Listeye yalnız **|sapma| < 250 ms** olan zıplamalar girer (`_ritim_degerlendir`), yani dış iki kutu fiilen
  150-250 ms aralığıdır. `_son_paneli_goster`
  yalnız ritimde ve liste boş değilse gösterir, o zaman `%SonIpucu` gizlenir (panel 360 px'e sığsın). Başarım paneli
  `%BasarimListesi` artık 2 sütunlu `GridContainer` (16 başarım tek sütunda sığmıyordu); ritim başarımları
  `ritim100` (ist["ritim"], anlık), `uc_sarki300` (`SARKILAR[*].rekor` anahtarları — koşu sonunda rekor denetimden
  önce yazılır), `gunluk_ritim5` (`gunluk_ritim_gecmis` uzunluğu). Yeni başarım eklerken panelin sığdığı test var.
- **Sonuç paneli 360 px'e sığmak zorunda.** Satır sayısı değişken (en çok 8: 3 tamamlanan görev + 3 yeni görev +
  başarım satırı + seviye) ve panel `reset_size()` ile içeriğine göre büyür. `_son_paneli_goster` içinde,
  `reset_size()` çağrısından **hemen önce**, `get_combined_minimum_size().y > ekran` ise histogram gizlenir
  (ortalama sapma üstteki satırda kalır); 2+ görev tamamlanan ritim koşusunda gerçekten devreye girer.
  `%SonIpucu` iki koşulla gizlenir: satır sayısı > 6 **ya da** histogram görünür. Panele yeni satır/denetim eklersen
  `tools/panel_olc.gd` ile beş kalabalık seviyesini ölç (dışa aktarmaya girmez).
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

Kapılar (hepsi geçmeden tur bitmez):

- `-s res://tests/testler.gd` → **961 test, 0 hata**. GitHub Actions `main`'e her push'ta ve
  her PR'da aynı komutu koşar (taze checkout + Git LFS + Godot 4.7.2); rozet README'de.
- `tools/bot_stres.gd` uzun koşu: 24 tohum × 3 dk **0 ölüm**, 43 parçanın hepsi görülmeli.
  Ritim için `--ritim --sarki N`, zamanlama penceresi için `--vurus <ms>` (pencere −175…+150 ms).
- `tools/panel_olc.gd`: sonuç paneli beş kalabalık seviyesinde de 360 px'e sığmalı.
- Web yapısı Chromium'da masaüstü + telefon emülasyonunda açılmalı, **konsol hatası 0**.
- Temiz klon: `git lfs pull` → `mkdir -p build/web build/windows` → `--import` 0 hata → testler.

Beklenen gürültü (hata değil): Godot çıkışta "N ObjectDB instances were leaked" (test
paketinde 25) ve "N resources still in use at exit" (7) yazar — statik önbelleklerden gelir,
çıkış kodunu etkilemez. Chromium'un AudioContext otomatik oynatma uyarısı da normaldir.
Sahne `uid` değerleri makineye göre değişir; düğüm `unique_id`'leri düğüm yolundan türetilir.

Sürüm sürüm ne yapıldığı ve ölçüm geçmişi: `YOL-HARITASI.md` ve README'nin tur bölümleri.