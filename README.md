# Tek Tuş Koşu

Mobil öncelikli, tek tuşla oynanan sonsuz çatı koşusu. Karakter kendiliğinden koşar;
oyuncu yalnızca zıplar. Hız zamanla artar, amaç en uzağa gitmek.

**Durum:** v0.3 — geliştirme turu 2 (2026-09-16). Günlük koşu + hayalet rakip, rekor/ölüm
işaretleri, koşu sonu şehir haritası, 11 başarım, 36 parça. (v0.2: pixel art, ses/müzik, görevler,
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

- **Günlük koşu (v0.3):** tarihten türeyen tohumla o gün herkes aynı çatı dizisini koşar. Günün
  rekoru ve deneme sayısı ayrı tutulur; günün en iyi denemesi **hayalet rakip** olarak sonraki
  denemelerde yanında koşar, bittiği yere "HAYALET" işareti konur. Günlük koşuda rahat mod kapalıdır.
- **İşaretler ve harita (v0.3):** koşu sırasında rekorun ("REKOR") ve son ölümün ("SON") yerinde
  bayrak; koşu sonunda geçilen yolu ışıklı pencerelerle, önceki ölüm yerlerini kırmızı çentikle
  gösteren şehir şeridi.
- **Başarımlar (v0.3):** 11 başarım (her biri +25 altın), menüde liste, koşu sırasında duyuru.
- **36 parça:** zorluk 0 "nefes" parçaları (3–8 tehlikeli parçada bir), zorluk 1–3 parçalar;
  öğeler: çukur, diken, blok, alçak tavan (yalnız kısa sıçramayla geçilir), piston (yükselip inen
  diken), hareketli platform, riskli altın rotaları.
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
scripts/isaret.gd        dünyadaki rekor / son ölüm / hayalet bayrakları
scripts/mini_harita.gd   koşu sonu şehir ışıkları şeridi
scripts/bot.gd           test/demodaki otomatik oyuncu (kısa sıçrama dahil)
scenes/parcalar/*.tscn   36 hazır parça (koddan üretilir)
tools/varlik_uret.gd     tüm sprite'ları (PNG) koddan üretir
tools/ses_uret.gd        ses efektlerini (WAV) koddan üretir
tools/muzik_uret.gd      menü ve oyun müziğini (WAV döngü) üretir
tools/sahne_uret.gd      parça, oyun ve menü sahnelerini koddan üretir
tools/proje_ayarla.gd    project.godot ayarlarını + girdi haritasını yazar
tools/ekran_goruntusu.gd itch ekran görüntüleri + kapak (pencere açar)
tools/bot_stres.gd       farklı tohumlarla uzun bot koşuları (ölümleri parça adıyla raporlar)
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
- **Hayalet yalnız günlük koşuda:** rastgele koşuda çatılar farklı olduğundan hayalet yanıltıcı olurdu.
- **Tek girdinin derinliği:** kısa dokunuş / basılı tutma / havada ikinci zıplama; alçak tavan
  kısa sıçramayı zorunlu kılar.
- **Satın alma yalnız kozmetik:** kostümler oynanışı değiştirmez; reklam ve gerçek para yok.
- **Erişilebilirlik:** rahat mod (ayrı rekor), yüksek kontrast, sarsıntı kapatma.
- **Android dışa aktarma yok** (SDK kurulu değil). Web + Windows var.

## Doğrulama

Ayrıntılar: `CLAUDE.md` → Doğrulama. Özet (v0.3, bulut, Godot 4.7.2 Linux headless):
otomatik testler **558 geçti, 0 hata**; bot stres testi 24 tohum × 3 dk, 0 ölüm; web sürümünde
günlük koşu başlatıldı. v0.2: web sürümü Chromium'da menü, karakter, ayarlar, oyun, ölüm tekrarı
ve sonuç paneliyle denendi.

Windows 11 (Godot 4.7.2, 2026-09-16): varlık/ses/müzik/sahne üretimi, içe aktarma, testler
(v0.3: **558 geçti, 0 hata**; v0.2: 388), bot stresi (8 tohum, 0 ölüm), ekran görüntüsü aracı ve iki
dışa aktarma çalıştı (`tek-tus-kosu.exe` 105 MB, web pck 523 KB). Üretilen PNG ve WAV dosyaları bulutta üretilenlerle
bayt bayt aynı.

`build/.gdignore` var: Godot'un dışa aktarma çıktısındaki PNG'leri proje kaynağı sanıp
içeri aktarmasını engeller. Silme.
