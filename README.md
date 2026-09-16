# Tek Tuş Koşu

Mobil öncelikli, tek tuşla oynanan sonsuz koşu oyunu. Karakter kendiliğinden koşar;
oyuncu yalnızca zıplar. Hız zamanla artar, amaç en uzağa gitmek.

**Durum:** oynanabilir prototip (2026-09-16). Görseller yer tutucu şekiller, ses yok.

## Kontroller

| Eylem | Klavye | Gamepad | Dokunmatik / fare |
|---|---|---|---|
| Zıpla | Boşluk / W / ↑ | A (veya B) | Ekrana dokun / sol tık |
| Yüksek zıpla | Basılı tut | Basılı tut | Parmağını basılı tut |
| Havada ikinci zıplama | Havada tekrar bas | Havada tekrar bas | Havada tekrar dokun |
| Duraklat | Esc / P | Start | Sağ üstteki **II** |
| Oyun bitince tekrar | Boşluk | A | Dokun |

## Çalıştırma

- Godot 4.7.2 ile `project.godot` dosyasını aç, F5.
- Dışa aktarılmış sürüm: `build/windows/tek-tus-kosu.exe`, web: `build/web/index.html`
  (web sürümünü bir yerel sunucuyla aç, dosyayı çift tıklayarak değil).

## Yapı

```
scripts/ayarlar.gd       tüm denge sabitleri (hız, zıplama, zorluk eşikleri)
scripts/oyuncu.gd        koşu + zıplama (kojot süresi, zıplama tamponu, değişken yükseklik, 2. zıplama)
scripts/oyun.gd          parça üretimi/silme, hız artışı, puan, duraklatma, oyun sonu, girdi
scripts/parca.gd         parça tabanı + tehlike aralıklarının hesabı
scripts/bot.gd           test/demodaki otomatik oyuncu
scripts/kayit.gd         rekor + toplam altın (user://kayit.cfg)
scenes/parcalar/*.tscn   12 hazır parça (zorluk 1-3)
tools/sahne_uret.gd      parça ve arayüz sahnelerini koddan üretir
tools/proje_ayarla.gd    project.godot ayarlarını + girdi haritasını yazar
tests/testler.gd         otomatik testler
```

## Parça eklemek / değiştirmek

`tools/sahne_uret.gd` içindeki `PARCALAR` listesini düzenle, sonra:

```
godot --headless --path . -s res://tools/sahne_uret.gd
godot --headless --path . --import
godot --headless --fixed-fps 60 --path . -s res://tests/testler.gd
```

Test, her parçayı kendi en düşük hızında ve en yüksek hızda (460 px/sn) bot ile koşturur;
geçilemeyen parça testi düşürür. Tasarım kuralları: parça uçlarında 60 px güvenli zemin,
yüksek bloklar parça başından en az 360 px içeride.

## Tasarım kararları

- **Oyuncu ilerler, dünya kaymaz.** Fizik (CharacterBody2D) doğal çalışsın, kamera takip etsin
  diye. 3 dakikalık koşuda ~75.000 px; float hassasiyeti için sorun değil.
- **Zorluk hıza bağlı:** zorluk 2 parçalar 280, zorluk 3 parçalar 360 px/sn'den sonra gelir;
  hız arttıkça zor parçaların ağırlığı artar. Aynı parça art arda gelmez.
- **Duvara çarpmak ölüm:** basamağa zıplamadan girersen biter (koşu oyunlarının alışılmış kuralı).
  Zemin parçalarının eklem yerleri duvar sayılmaz.
- **Dokunma:** kısa dokunuş ≈ 35 px sıçrama, basılı tutma ≈ 96 px. Menüde boş yere dokunmak da başlatır.
- **Android dışa aktarma bu turda yok** (SDK kurulu değil). Web + Windows var.

## Doğrulama (2026-09-16, bulut ortamı, Godot 4.7.2 Linux headless)

- `--import`: hata yok · otomatik testler: **171 geçti, 0 hata**
- 3 dk hızlandırılmış bot koşusu: 2362 m, 0 ölüm, hız 460'a ulaştı, aynı anda en çok 3 parça
- Windows + Web dışa aktarma başarılı; web sürümü Chromium'da açıldı: menü, klavye ve
  dokunmatik zıplama, oyun sonu paneli çalışıyor, konsolda hata yok.

## Doğrulama (2026-09-16, Windows 11, Godot 4.7.2 headless)

Aynı proje bu depo yolunda yeniden koşuldu:

- `godot --headless --path . --import` → çıkış 0, hata yok
- `godot --headless --fixed-fps 60 --path . -s res://tests/testler.gd` → **171 geçti, 0 hata**
- Windows dışa aktarma → `build/windows/tek-tus-kosu.exe` (106.768 KB)
- Web dışa aktarma → `build/web/index.html` (pck 61 KB, wasm 38.589 KB)

`build/.gdignore` var: Godot'un dışa aktarma çıktısındaki PNG'leri proje kaynağı sanıp
içeri aktarmasını (ve pck'yi şişirmesini) engeller. Silme.
