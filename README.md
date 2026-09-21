# Tek Tuş Koşu

Mobil öncelikli, tek tuşla oynanan sonsuz çatı koşusu. Karakter kendiliğinden koşar;
oyuncu yalnızca zıplar. Hız zamanla artar, amaç en uzağa gitmek.

**Durum:** v1.7 — geliştirme turu 12 (2026-09-21). Ritim koşusu sonuç panelinde vuruş sapması histogramı (çok erken /
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

## Kontroller

| Eylem | Klavye | Gamepad | Dokunmatik / fare |
|---|---|---|---|
| Zıpla | Boşluk / W / ↑ | A (veya B) | Ekrana dokun / sol tık |
| Yüksek zıpla | Basılı tut | Basılı tut | Parmağını basılı tut |
| Kısa sıçrama (alçak tavan altı) | Dokun, hemen bırak | Aynı | Kısa dokunuş |
| Havada ikinci zıplama | Havada tekrar bas | Havada tekrar bas | Havada tekrar dokun |
| Duraklat | Esc / P | Start | Sağ üstteki **II** |
| Oyun bitince tekrar | Boşluk | A | Dokun |

## Oyun içeriği

- **Ritim koşusu (v0.6):** menüde **Ritim**. Hız sabit 300 px/sn, oyun müziği 150 BPM → her vuruş
  120 px. Engeller ölçü ölçü koddan üretilir; her engelin ideal zıplama anı bir vuruşa denk gelir.
  Çatı kenarındaki lambalar müzikle nabız atar, zıplanacak vuruşlar sarı ve oklu. Vuruşun ±70 ms
  içinde zıplamak "Tam vuruş ×N" serisi; dışında "Erken/Geç N ms". Engeller dikenler, çukurlar ve
  alçak tavan (kısa sıçrama); ilk 2 ölçü boş, 10. ölçüden sonra iki olaylı ölçüler (13 desen). Ayrı rekor
  ve ölüm listesi; sonuç panelinde tam vuruş sayısı; 13. başarım "Vuruşu yakala" (tek koşuda 20 tam vuruş).
  Duraklatınca müzik de durur; müzik oyun zamanından 60 ms'den fazla kayarsa (sekme gizlendi,
  uzun takılma) müzik oyuna göre yeniden sarılır.
- **Sapma histogramı ve ritim başarımları (v1.7):** koşu sonunda `SapmaGrafigi` (`%SonSapma`) değerlendirilen
  zıplamaların sapmasını beş kutuya sayar (|x| ≤ 70 ms tam; 70–150 erken/geç; > 150 çok erken/çok geç) ve çubuklarla
  çizer; yalnız ritimde ve zıplama varsa görünür. Başarımlar: "Metronom" (tek koşuda 100 tam vuruş, koşu içinde
  duyurulur), "Üç şarkı" (üç şarkı rekoru da ≥ 300 m), "Ritim müdavimi" (`gunluk_ritim_gecmis` ≥ 5 gün).
- **Şarkı önizleme ve günlük geçmiş (v1.6):** `Ses.onizle()` ayrı oynatıcıyla şarkının ilk 2 saniyesini çalar
  (`Ritim.ONIZLEME_SN`), menü müziği duraklar ve önizleme bitince/panelden çıkınca sürer. Günün ritmi her koşuda
  `gunluk_ritim_gecmis`'e yazılır (tarih, şarkı, rekor; 7 gün); panelde "Son günler: 21.09 Çatı 410 m · …".
- **Şarkı teması (v1.5):** `Ritim.SARKILAR[i].tema` şarkıyı `oyun.TEMALAR` içindeki bir temaya kilitler
  (Fırtına Hattı → "Fırtına": yağış açık, yıldız yok). Normal koşu ilk `TEMA_DONGU` = 4 temada döner, Fırtına oraya
  girmez. Şimşek: `_ritim_ipucu_sesi()` her iki ölçüde bir (`k % 8 == 0`) `SIMSEK_OLASILIK` ile `_simsek()` —
  gökyüzü katmanına çalışma anında eklenen beyaz `ColorRect` 0,45 → 0 alfa, 320 ms cubic ease-out; zamanlama
  `_simsek_rng` (tohumdan) ile parça dizisinden bağımsız; `sarsinti` ayarı kapalıysa hiç çakmaz.
- **Web kabuğu (v1.4):** Godot'nun varsayılan beyaz-siyah yükleme sayfası yerine `yayin/web-kabuk.html`
  (`html/custom_html_shell`): "TEK TUŞ KOŞU" başlığı, tek vurgu rengi (menüdeki cam göbeği), sistem yazı tipi,
  `transform`/`opacity` ile ilerleme (sabit hız → `linear`), 260 ms güçlü ease-out giriş ve 220 ms solma çıkışı,
  `prefers-reduced-motion` desteği, Türkçe hata kutusu. Tasarım kararları Emil Kowalski'nin animasyon kuralları ve
  taste-skill "anti-slop" ilkeleriyle (saf siyah yok, tek vurgu, ışıma yok) verildi.
- **Üçüncü şarkı (v1.3):** "Fırtına Hattı · 140 BPM" (`muzik_ritim3.wav`, `muzik_uret --ruh gergin --tohum 5`, 13,7 sn
  döngü; gerçek tempo 22050·15/2363 = 139,97 BPM → vuruş 128,6 px). `agirlik: {diken 1,5, kisa 0,6, cukur 0,8}`;
  ayrı rekor/ölüm anahtarları (`rekor_ritim3`, `olumler_ritim3`); günün ritmi artık üç şarkıdan seçer.
- **Şarkı karakteri (v1.2):** `Ritim.SARKILAR[i].agirlik` desen türlerine seçim çarpanı verir (Çatı Neşesi: kısa ×2,2,
  çukur ×0,7 — geniş vuruş aralığında kısa sıçramalar daha rahat sığar). Zorluk ve boşluk kuralları aynı; bot 16 tohum × 3 dk
  ve zamanlama penceresi −175/+150 ms yeniden ölçüldü, 0 ölüm.
- **Vuruş ipucu sesi (v1.0):** ritim koşusunda zıplanacak vuruştan bir vuruş önce kısa bir tık çalar (müziğin
  vuruşuyla çakışır, sayım gibi). Ritim panelinde "Zıplama vuruşundan önce tık sesi" ile kapatılır; botta çalmaz.
- **Günün ritmi hayaleti ve arka vuruş (v0.9):** günün ritminde en iyi denemen hayalet olarak yanında koşar
  (ayrı dosya `kayit.hayalet_ritim.cfg`; konumlar vuruş ızgarasına göre kaydedilir, başka ses gecikmesiyle
  oynayanda da engelin üstünde zıplar). Desenlere 1. ve 3. vuruştaki dikenler eklendi (davulun zayıf vuruşu):
  `diken1`, `diken3`, `arka_vurus`; ardışık olaylar arası en az 2 vuruş, alçak tavana en az 3 kuralı genelleştirildi.
- **Günün ritmi (v0.8):** ritim panelinde üçüncü düğme. Şarkı ve çatı dizisi tarihten gelir (günlük koşudan
  ayrı tohum); herkes o gün aynı ritimde koşar. Günün rekoru, deneme sayısı ve ölüm işaretleri ayrı
  (`gunluk_ritim`); sonuçta Paylaş ("Tek Tuş Koşu · Günün ritmi (şarkı) tarih"). Ritim koşularında ilk
  saniyelerde lambaları anlatan ipucu.
- **Ritim şarkıları ve gecikme (v0.7):** Ritim düğmesi şarkı panelini açar: "Gece Koşusu · 150 BPM"
  ve "Çatı Neşesi · 128 BPM" (vuruş 140,6 px — aynı engeller, daha geniş aralık). Her şarkının rekoru ve
  ölüm işaretleri ayrı. Panelde **Ses gecikmesi** kaydırıcısı (−150…+300 ms): vuruş ızgarasını (engelleri)
  duyulan müziğe göre kaydırır. Koşu sonunda zıplamaların vuruştan ortalama sapması yazılır; en az 6
  zıplamada ortalama 25 ms'yi aşarsa "Gecikme +N ms" düğmesi çıkar, basınca ayar yazılır.
- **Günlük koşu (v0.3):** tarihten türeyen tohumla o gün herkes aynı çatı dizisini koşar. Günün
  rekoru ve deneme sayısı ayrı tutulur; günün en iyi denemesi **hayalet rakip** olarak sonraki
  denemelerde yanında koşar, bittiği yere "HAYALET" işareti konur. Günlük koşuda rahat mod kapalıdır.
- **İşaretler ve harita (v0.3):** koşu sırasında rekorun ("REKOR") ve son ölümün ("SON") yerinde
  bayrak; koşu sonunda geçilen yolu ışıklı pencerelerle, önceki ölüm yerlerini kırmızı çentikle
  gösteren şehir şeridi.
- **Günlük seri ve paylaşım (v0.4):** art arda günlük koşu yapılan gün sayısı (menüde
  "Günlük · X m · N gün"). Günlük sonuç panelinde **Paylaş**: telefonda tarayıcının paylaşım menüsü,
  diğer cihazlarda panoya kopyalama. Metin: tarih, mesafe, deneme, günün rekoruna oranı gösteren
  10 hücrelik şerit (■□), seri.
- **Çürük iskele (v0.4):** iki çatı arasındaki tahta köprü. Üstüne basınca sallanıp çatırdar,
  0,5 sn sonra çöker. Koşucu yavaşlayamadığı için iş, iskelenin başında zıplamak ya da dilimler
  arasında sekmek. 4 parça: 37–40.
- **Rüzgâr (v0.5):** bayrakla işaretli bölgede, havadayken yatay hıza eklenir. Karşı rüzgâr zıplamayı
  kısaltır (çukuru geçmek için basılı tut ya da ikinci zıplama), arka rüzgâr uzatır (dikene inme).
  Üstte "← karşı rüzgâr / arka rüzgâr →" yazısı. 3 parça: 41–43.
- **Telefonda (v0.5):** dikey tutulunca "Telefonu yan çevir" perdesi ve koşu duraklar; web'de dokunmatik
  cihazda Başla'ya basınca tam ekran + yatay kilit denenir.
- **Kostüm izleri (v0.4):** zıplama/iniş tozu kostüm renginde; Neon ve Altın Taç koşarken iz bırakır.
- **Başarımlar (v0.3, v1.7):** 16 başarım (her biri +25 altın), menüde iki sütunlu liste, koşu sırasında duyuru.
- **43 parça:** zorluk 0 "nefes" parçaları (3–8 tehlikeli parçada bir), zorluk 1–3 parçalar;
  öğeler: çukur, diken, blok, alçak tavan (yalnız kısa sıçramayla geçilir), piston (yükselip inen
  diken), hareketli platform, çürük iskele, rüzgâr, riskli altın rotaları.
- **Kıl payı kaçış:** engelin 14 px yakınından geçmek +1 altın, sesli/yazılı geri bildirim.
- **Görevler:** her zaman 3 görev (kısa/orta/uzun); ödül 20/50/120 altın; her 3 görevde seviye artar,
  hedefler büyür.
- **Kostümler:** Klasik, Kızıl, Orman, Neon, Altın (60–600 altın). Menü → Karakter.
- **Ölüm tekrarı:** son 1,5 sn yavaş çekimde, çarpılan engel vurgulu; ardından sonuç paneli
  (mesafe, rekor, altın, görev ilerlemesi). Sahne yeniden yüklenmeden < 1 sn'de yeniden başlar.
- **Tema döngüsü:** her 500 m'de Akşam → Gece → Yağış → Neon (gökyüzü geçişi, yağış parçacıkları).
- **Ayarlar:** müzik/efekt ses düzeyi, tam ekran (masaüstü), ekran sarsıntısı, titreşim (telefon),
  yüksek kontrast tehlikeler, **Rahat mod** (hız ×0,8, ayrı rekor).
- **Kayıt:** `user://kayit.cfg` + yedek `kayit.yedek.cfg`; bozuk kayıtta yedekten döner, eski
  prototip kaydını taşır.

## Çalıştırma

- Depoyu klonladıktan sonra **`git lfs pull`** çalıştır: görseller, sesler ve yazı tipi Git LFS'te tutulur;
  çekilmezse yerlerine 128 baytlık işaretçi dosyalar gelir ve proje bozuk varlıklarla açılır.
- Godot 4.7.2 ile `project.godot` dosyasını aç, F5.
- Dışa aktarılmış sürüm: `build/windows/tek-tus-kosu.exe`, web: `build/web/index.html`
  (web sürümünü bir yerel sunucuyla aç, dosyayı çift tıklayarak değil).

## Yapı

```
scripts/ayarlar.gd       tüm denge sabitleri (hız, zıplama, zorluk eşikleri, piston, kıl payı, tema)
scripts/oyuncu.gd        koşu + zıplama (kojot, tampon, değişken yükseklik, 2. zıplama), animasyon, geçmiş
scripts/oyun.gd          parça üretimi, hız, puan, görev takibi, tema, efektler, ölüm tekrarı, sonuç paneli
scripts/menu.gd          ana menü, karakter (kostüm satın alma), ayarlar
scripts/parca.gd         parça tabanı + tehlike/tavan aralıkları
scripts/tehlike.gd       diken / blok / tavan / piston + kıl payı algılayıcı
scripts/hareketli.gd     hareketli platform (AnimatableBody2D)
scripts/zemin.gd         dokulu çatı/tuğla çizimi
scripts/altin.gd         toplanabilir altın
scripts/gorevler.gd      görev şablonları, ilerleme, ödül
scripts/kostumler.gd     kostüm listesi, SpriteFrames üretimi, satın alma
scripts/ses.gd           ses efekti havuzu + müzik, Muzik/Efekt veri yolları
scripts/kayit.gd         kayıt + yedek + ayarlar
scripts/gunluk.gd        günlük koşu: tarih, tohum, günün rekoru/denemeleri
scripts/hayalet.gd       günlük koşu hayaleti: örnekleme, kaydet/yükle, geri oynatma
scripts/basarimlar.gd    başarım listesi ve denetimi
scripts/sapma_grafigi.gd ritim sonucunda vuruş sapması histogramı (v1.7)
scripts/isaret.gd        dünyadaki rekor / son ölüm / hayalet bayrakları
scripts/mini_harita.gd   koşu sonu şehir ışıkları şeridi
scripts/coken.gd         çürük iskele (basınca çöken tahta köprü)
scripts/ruzgar.gd        rüzgâr bölgesi (havadayken yatay hıza eklenir)
scripts/dikey_uyari.gd   telefon dikeyken "yan çevir" perdesi
scripts/ritim.gd         ritim koşusu: şarkılar, vuruş ızgarası, ölçü desenleri, parçayı koddan üretme, gecikme önerisi
scripts/ritim_isaret.gd  ritim parçasındaki vuruş lambaları
scripts/simgeler.gd      web'de eksik simgeler (★ ✓ ←…) için yedek yazı tipini bağlar
scripts/bot.gd           test/demodaki otomatik oyuncu (kısa sıçrama dahil)
scenes/parcalar/*.tscn   43 hazır parça (koddan üretilir)
assets/fonts/simgeler.ttf  DejaVu Sans Bold'dan 10 simgelik alt küme ("TTK Simgeler", lisans yanında)
tools/varlik_uret.gd     tüm sprite'ları (PNG) koddan üretir
tools/ses_uret.gd        ses efektlerini (WAV) koddan üretir
tools/muzik_uret.gd      menü ve oyun müziğini (WAV döngü) üretir
tools/sahne_uret.gd      parça, oyun ve menü sahnelerini koddan üretir
tools/proje_ayarla.gd    project.godot ayarlarını + girdi haritasını yazar
tools/ekran_goruntusu.gd itch ekran görüntüleri + kapak (pencere açar)
tools/bot_stres.gd       farklı tohumlarla uzun bot koşuları (ölümleri parça adıyla, parça kullanımını yazar);
                         --ritim [--sarki 1]: ritim koşusu, --vurus <ms>: vuruştan kaydırarak zıplayan oyuncu (zamanlama penceresi)
tools/simge_fontu.py     simge yazı tipini üretir (Python + fonttools; yalnız simge seti değişince)
tests/testler.gd         otomatik testler
yayin/                   itch.io sayfa metni, ekran görüntüleri, kapak, butler komutları
```

## Varlıkları ve sahneleri yeniden üretmek

```
godot --headless --path . -s res://tools/proje_ayarla.gd
godot --headless --path . -s res://tools/varlik_uret.gd
godot --headless --path . -s res://tools/ses_uret.gd
godot --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_oyun.wav --ruh hizli --tohum 11
godot --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_menu.wav --ruh sakin --tohum 4
godot --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_ritim2.wav --ruh neseli --tohum 7
godot --headless --path . --import
godot --headless --path . -s res://tools/sahne_uret.gd
godot --headless --path . --import
godot --headless --fixed-fps 60 --path . -s res://tests/testler.gd
```

Parça eklemek için `tools/sahne_uret.gd` içindeki `PARCALAR` listesini düzenle. Test, her parçayı
kendi en düşük hızında ve en yüksek hızda (460 px/sn) bot ile koşturur; geçilemeyen parça testi
düşürür. Tasarım kuralları: parça uçlarında 60 px güvenli zemin, yüksek bloklar parça başından en
az 360 px içeride, alçak tavanın alt kenarı y=212 (kısa sıçrama sığar, tam zıplama sığmaz).

## Tasarım kararları

- **Oyuncu ilerler, dünya kaymaz.** Fizik (CharacterBody2D) doğal çalışsın, kamera takip etsin diye.
- **Zorluk hıza bağlı:** zorluk 2 parçalar 280, zorluk 3 parçalar 360 px/sn'den sonra gelir.
  Parça seçimi o anki kare hızına değil, parçanın başladığı mesafedeki hıza bakar (v0.3); parça
  dizisi yalnız tohuma bağlıdır — günlük koşu her makinede aynıdır.
  Aynı parça art arda gelmez; 3–8 tehlikeli parçada bir nefes parçası gelir (rakip analizinde
  "hiç durmayan yoğunluk" en sık şikâyetti).
- **Ölüm adil görünmeli:** ölüm tekrarı ve vurgulu engel, "neden öldüm?" sorusunu yanıtlar.
- **Hızlı tekrar:** sahne yeniden yüklenmez; ölümden yeni koşuya < 1 sn.
- **Çöken değil çürük:** yol haritasındaki "üstündeyken alçalan bina" denendi ve bırakıldı.
  Koşucu yavaşlayamadığından alçalan zemin ya zemine yapışma sorununa ya da belirsiz bir
  duvar ölümüne dönüşüyordu. Basınca belli bir sürede çöken iskele aynı gerilimi okunur bir
  zamanlamayla veriyor (sallanma + çatırtı uyarısı).
- **Dikeyde oynatmak yerine uyarı:** 640×360 yatay tasarımı dikeye sığdırmak ya oyun alanını
  küçültüyor ya da önünü görme mesafesini 0,4 sn'nin altına indiriyor. Koşu oyunu yatay kalıyor.
- **Ritim parçaları elle değil koddan:** bir parçanın vuruşa hizalı olması için başlangıcının ızgaraya
  oturması gerekir; hazır sahne yerine ölçü desenlerinden parça üretmek bunu kendiliğinden sağlıyor.
  Hız sabit, çünkü değişen hızda vuruş aralığı (px) da değişir ve engeller müzikten kopar.
  Zamanlama penceresi ölçüldü: vuruştan 175 ms erken ile 150 ms geç arasındaki zıplamalar tüm
  desenlerde yaşatıyor (dar bir "ya tam ya ölüm" yerine: tam vuruş ödül, ceza değil).
- **İkinci şarkıda hız değil vuruş aralığı değişir:** engel geometrisi (zıplama boyu) hıza bağlı; hızı
  sabit tutup yalnız vuruş aralığını açmak, bütün desenleri ve ölçülmüş zamanlama penceresini aynen korur.
- **Gecikme ayarı ayrı ekran değil, oyunun kendi ölçümü:** kalibrasyon ekranı oyuncunun atlayacağı bir adım;
  koşu zaten her zıplamanın sapmasını ölçüyor, tutarlı bir kayma varsa sonuçta tek dokunuşla düzeltiliyor.
- **Oyun zamanı yetkili, müzik ona uyar:** fizik ve dünya belirlenimci kalsın diye kayma olunca oyun
  değil müzik sarılır.
- **Paylaşımda bağlantı yok (şimdilik):** `Ayarlar.ITCH_ADRESI` boş; yayından sonra doldurulunca paylaşım metninin
  son satırına eklenir.
- **Günün ritmi ayrı tohum ve ayrı kayıt:** günlük koşuyla aynı tohumu paylaşsaydı iki kip aynı günü
  "tüketirdi"; ayrı tutunca iki günlük meydan okuma birbirini bozmadan yan yana duruyor. Hayalet henüz yok
  (yol haritasında).
- **Hayalet yalnız günlük koşuda:** rastgele koşuda çatılar farklı olduğundan hayalet yanıltıcı olurdu.
- **Tek girdinin derinliği:** kısa dokunuş / basılı tutma / havada ikinci zıplama; alçak tavan
  kısa sıçramayı zorunlu kılar.
- **Satın alma yalnız kozmetik:** kostümler oynanışı değiştirmez; reklam ve gerçek para yok.
- **Erişilebilirlik:** rahat mod (ayrı rekor), yüksek kontrast, sarsıntı kapatma.
- **Android dışa aktarma yok** (SDK kurulu değil). Web + Windows var.

## Doğrulama

Ayrıntılar: `CLAUDE.md` → Doğrulama.

**v1.7.1 (yayın adayı).** Bulut (Godot 4.7.2, Linux headless) **853 test geçti, 0 hata**;
Windows 11'de v1.7 ile 849 test (panel düzeltmesi öncesi). Bot stresi 8 tohum × 3 dk 0 ölüm; ritim stresi üç şarkıda
4'er tohum × 3 dk 0 ölüm; vuruş penceresi −175…+150 ms (v1.3'ten beri değişmedi).
Windows + Web dışa aktarma temiz (exe 107 MB, web pck 839 KB); dokuz yayın ekran görüntüsü üretildi.

Temiz klon denemesi (v1.7): `git lfs pull` → `.godot` önbelleği olmadan içe aktarma 0 hata →
853 test → iki dışa aktarma → web yapısı Chromium'da açıldı (menü, 16 başarımlı iki sütunlu panel,
koşu; konsolda hata yok).

Tarayıcı (Chromium, Playwright; masaüstü 1280×720 ve telefon emülasyonu 915×412): özel yükleme ekranı,
menü, ritim paneli (üç şarkı + önizleme), ritim koşusu ve **sonuç panelinde vuruş sapması histogramı**
(canlı koşuda "Tam vuruş 1 · Ort. sapma −5 ms" ile beş kutu), başarım paneli, ayarlar paneli, günlük koşu
ve paylaşım; konsolda hata yok. Önceki sürümlerin test sayıları: v1.7 849, v1.6 821, v1.5 809, v1.3 804, v1.2 793,
v1.0 791, v0.9 788, v0.8 782, v0.7 765, v0.6 740, v0.5 714, v0.4 660, v0.3 558, v0.2 388, v0.1 171.

Üretilen PNG ve WAV dosyaları bulutta ve Windows'ta bayt bayt aynı (üreticiler deterministik).

`build/.gdignore` var: Godot'un dışa aktarma çıktısındaki PNG'leri proje kaynağı sanıp
içeri aktarmasını engeller. Silme.
