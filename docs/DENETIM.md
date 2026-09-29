# Denetim — arayüz yenilemesi öncesi durum (29 Eylül 2026)

Kapsam: `main` dalının `2ab7d47` hâli (v1.7.3 + CI duman testi). Oyun bu makinede (Windows 11,
Intel UHD, Godot 4.7.2) gerçekten açılıp oynandı; yalnızca kod okunmadı. "Önce" kareleri
`docs/tasarim/once-*.png`.

## Nasıl denetlendi

| Yol | Ne yapıldı |
|---|---|
| Masaüstü (Godot) | `tools/ekran_goruntusu.gd` ile menü, oynanış, ritim, oyun sonu 1280×720 karelere alındı; `tools/fps.gd` ile kare süresi ölçüldü. |
| Web, yerel | `main`'den `--export-release "Web"`, `build/web` içinde `python -m http.server`; Claude Browser ile açıldı, Oyna'ya tıklanıp Boşluk ile oynandı, konsol okundu. |
| Web, canlı | `https://furkiozknn.github.io/tek-tus-kosu/` HTTP 200; açıldı, menü geldi, koşuldu, konsolda hata yok. |
| Testler | `tests/testler.gd`: **961 geçti, 0 hata**. |
| Girdi | `tools/his_olc.gd` (pencereli, gerçek zamanlı): tuş olayından zıplama sinyaline ve ilk hareketli kareye süre; kojot ve tampon pencereleri. Eski kod için `main`'in ayrı çalışma ağacı (git worktree) kullanıldı. |
| Gerçek telefon | **Denenmedi.** Yalnızca tarayıcıda 812×375 yatay emülasyon. |

## Bulgular

### İlk 30 saniye anlaşılıyor mu?

Kısmen.

- Menüde altı düğme, görev paneli, rekor, altın, başlık ve alt ipucu aynı ağırlıkta. Asıl eylem
  ("Başla") diğer düğmelerden yalnız kalın kenarlığıyla ayrılıyor; **büyük tek bir OYNA yok**.
- Nasıl oynanır bilgisi yalnız oyun başlayınca çıkıyor: üç satırlık, ortalanmış, dört saniye
  görünen bir blok ("Zıplamak için dokun / Boşluk · Basılı tut · Kırmızı tabelanın altında KISA
  zıpla"). **İlk oyun ile onuncu oyunda aynı**, yani öğretme yok: yeni oyuncu üç kuralı aynı anda
  okumak zorunda, tabelayı henüz görmeden.
- Görünüm tanıtım videosuyla **hiç örtüşmüyor**: video düz renk, geometrik (pembe yuvarlatılmış kare
  koşucu, sarı üçgenler, cam göbeği histogram, kâğıt kartlar); oyun pixel-art şehir, tuğla çatı, mavi
  kapüşonlu karakter, Open Sans. Videodan gelen oyuncu farklı bir oyun bulur.
- Menü sol sütunu çatının üstüne dar sığdırılmış (test bunu bekliyor); görevler büyük bir mor kartta
  ana düğmelerin yanında duruyor.

![önce: menü](tasarim/once-ekran-1.png)
![önce: ritim](tasarim/once-ekran-7-ritim.png)

### Kontroller hemen cevap veriyor mu?

Evet, ve bu değişmedi. Ölçüm (`tools/his_olc.gd`, pencereli, vsync açık, 80 deneme, her basış fizik
adımına göre rastgele fazda):

| | ortalama | %95 | en yüksek |
|---|---|---|---|
| tuş olayı → zıplama sinyali (önce) | 16,6 ms | 16,9 | 19,4 |
| tuş olayı → oyuncunun ilk hareketli karesi (önce) | 17,0 ms | 17,6 | 19,8 |

Bu ≈ bir kare: motor olayı sonraki karede dağıtıyor, oyun hemen zıplama hızını yazıyor ve aynı
karenin fizik adımı oyuncuyu oynatıyor. Oyunun kendi eklediği gecikme yok. Affetme değerleri
(kare kare tarama): **kojot** kenardan sonra 4 kare (≈83 ms) tam güçte zıplama, sonrası havadaki
zayıf ikinci zıplama; **tampon** iki hak bitmişken yere değmeden 7 kare (≈133 ms). İkisi de
standart aralıkta (80–130 ms).

### Zorluk eğrisi adil mi?

Evet. Hız 220 → 460 px/sn (60 sn'de tavan), ilk iki parça engelsiz, 3–8 tehlikeli parçada bir
nefes parçası, parça zorluğu hıza bağlı. Bot stresi (`bot_stres.gd`, 6 tohum × 2 dk normal, 3 tohum
× 2 dk ritim) **0 ölüm**; 43 parçanın hepsi görüldü. Eğriye dokunulmadı.

### Oyun bitince ne oluyor?

Ölüm tekrarı (1,5 sn, yavaş) → sonuç paneli. Panel bilgi açısından iyi (skor, rekor, şehir ışıkları
şeridi, sapma histogramı, görevler) ama: mavi-mor kutu, altı farklı boyutta beyaz/sarı yazı, dört
düğme aynı boyda. "Tekrar" odakta ama ayırt edilmiyor (bkz. `once-ekran-9-sonuc.png`).

### Dokunmatik ve mobil

Dokunma zıplatıyor, dikey telefonda perde var, web'de dokunmatik cihazda tam ekran + yatay kilit
deneniyor (`menu._telefonda_tam_ekran`). Kalan sorun: düğmeler 30 px yüksekliğinde (640×360 tabanda),
parmak için küçük.

### Dil

Yalnız Türkçe. Videolar X ve YouTube'da İngilizce yayınlanıyor; İngilizce oyuncu hiçbir şey okuyamıyor.
Dil ayarı ya da otomatik algılama yok.

### Konsol

Yerel ve canlı web sürümünde hata yok; yalnızca Godot ve WebGL bilgi satırları.

### Ölçümler (önce)

| | önce |
|---|---|
| Testler | 961 geçti |
| Web paketi | `index.pck` 863 548 B · `index.wasm` 39 514 754 B · `index.js` 279 815 B |
| Kare süresi (bot, 900 kare, vsync kapalı, Intel UHD, 1280×720) | normal 2,26 ms ort / 4,07 ms %99 (**442 FPS**); ritim 2,23 / 4,02 (**448 FPS**) |
