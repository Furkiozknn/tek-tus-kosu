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

## Komutlar

```
G=godot   # Windows: C:\Users\furki\AppData\Local\Microsoft\WinGet\Links\godot.exe
$G --headless --path . -s res://tools/proje_ayarla.gd
$G --headless --path . -s res://tools/varlik_uret.gd
$G --headless --path . -s res://tools/ses_uret.gd
$G --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_oyun.wav --ruh hizli --tohum 11
$G --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_menu.wav --ruh sakin --tohum 4
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

## Parça tasarım kuralları

- Uçlarda 60 px güvenli zemin; yüksek bloklar parça başından ≥ 360 px içeride.
- Alçak tavan alt kenarı y=212: kısa sıçrama (≈35 px) sığar, tam zıplama (≈96 px) sığmaz.
- Zorluk 0 = nefes parçası (tehlikesiz). Zorluk eşikleri: 2 → 280 px/sn, 3 → 360 px/sn.
- Her yeni parça testte en düşük ve en yüksek hızda bot ile geçilmeli; ayrıca
  `tools/bot_stres.gd -- --tohumlar 1,...,24` ile uzun koşularda ölüm olmamalı.
- Botun iniş noktası (hız × 0,743 sn / 2) bir sonraki tehlikenin üstüne düşmemeli: art arda
  tehlikeler arasında en az ~260 px ya da birleşik tek tehlike bırak.
- Hareketli ve tek yönlü kirişlerin yan yüzü öldürmez (`Oyuncu._duvara_carpti`).

## Doğrulama

- v0.1 (bulut + Windows): 171 test geçti; Windows ve Web dışa aktarma çalıştı.
- v0.2 (bulut, Linux headless): 388 test geçti, 0 hata. Web sürümü Playwright/Chromium ile:
  menü, karakter paneli, ayarlar paneli, fareyle başlatma, oyun, ölüm tekrarı, sonuç paneli.
- v0.3 (bulut): 558 test geçti; bot stresi 24 tohum × 3 dk, 0 ölüm; web'de günlük koşu açıldı.
- v0.2 (Windows 11): aynı akış + `tools/ekran_goruntusu.gd`; 388 test geçti, dışa aktarmalar tamam.
- v0.3 (Windows 11): 558 test geçti; bot stresi 8 tohum × 3 dk, 0 ölüm; ekran görüntüleri ve iki dışa
  aktarma tamam. Ekran görüntüleri buluttakinden yalnız GPU gürültüsü kadar farklı (kanal farkı ≤ 30).
  PNG/WAV üreticileri deterministik (bulut ve Windows çıktıları aynı hash). Sahne dosyalarındaki
  `uid` değerleri makineye göre değişir; bu normal.
- Web testinde bilinen durum: Chromium'un AudioContext otomatik oynatma uyarısı (zararsız).
