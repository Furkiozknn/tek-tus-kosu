class_name Ritim
extends RefCounted
## Ritim koşusu. Hız sabit 300 px/sn; vuruş aralığı şarkının temposundan gelir
## (150 BPM → 120 px, 128 BPM → 140,6 px, 140 BPM → 128,6 px). Engel geometrisi yalnız hıza bağlı, tempoya değil.
## Parçalar ölçü ölçü koddan üretilir: her engelde ideal zıplama anı bir vuruşa denk gelir.
## Vuruş ızgarası: x_k = izgara0 + k × adım (izgara0 ses gecikmesi + oyuncu ayarı kadar kaydırılır).

const BPM := 150.0
const HIZ := 300.0
const VURUS_SN := 60.0 / BPM
const ADIM := HIZ * VURUS_SN     ## ilk şarkının vuruş aralığı (px)

## Şarkılar. bpm, üretilen WAV'ın örnek düzeyindeki gerçek temposu (muzik_uret: 22050 Hz, onaltılık = round(22050·15/bpm)).
## agirlik: desen türüne göre seçim çarpanı (şarkının karakteri): Çatı Neşesi'nde alçak tavan (kısa sıçrama) daha sık,
## çukur daha seyrek — geniş vuruş aralığında (140 px) kısa sıçramalar daha rahat sığar. Fırtına Hattı'nda (140 BPM,
## 128,6 px) diken ×1,5: iki dikenli ölçüler (ikili, arka_vurus) ×2,25 — daha sık çift zıplama, daha az tavan.
const SARKILAR := [
	{"ad": "Gece Koşusu", "muzik": "muzik_oyun", "bpm": 150.0, "rekor": "rekor_ritim", "olumler": "olumler_ritim",
		"agirlik": {}, "aciklama": "150 BPM · dengeli"},
	{"ad": "Çatı Neşesi", "muzik": "muzik_ritim2", "bpm": 22050.0 * 15.0 / 2584.0, "rekor": "rekor_ritim2", "olumler": "olumler_ritim2",
		"agirlik": {"kisa": 2.2, "cukur": 0.7}, "aciklama": "128 BPM · daha çok alçak tavan"},
	{"ad": "Fırtına Hattı", "muzik": "muzik_ritim3", "bpm": 22050.0 * 15.0 / 2363.0, "rekor": "rekor_ritim3", "olumler": "olumler_ritim3",
		"agirlik": {"diken": 1.5, "kisa": 0.6, "cukur": 0.8}, "aciklama": "140 BPM · sık ikili diken", "tema": 4},
]
const GECIKME_ARALIK := Vector2i(-150, 300)   ## oyuncu ses gecikmesi ayarı (ms)
const ONERI_ESIK_MS := 25.0                    ## ortalama sapma bundan büyükse ayar önerilir
const ONERI_EN_AZ := 6                         ## öneri için en az değerlendirilen zıplama
const OLCU := 4                  ## ölçü başına vuruş
const PARCA_OLCU := 4            ## parça başına ölçü
const TAM_VURUS_MS := 70.0       ## bu kadar içinde zıplamak "tam vuruş"
const ISINMA_OLCU := 2           ## koşu başında boş ölçü
const SES_KAYMA_SN := 0.06       ## müzik oyundan bu kadar kayarsa yeniden sarılır

## Menüden seçilen kip ve şarkı.
static var secili := false
static var sarki := 0
static var gunluk_secili := false


# ------------------------------------------------------------------ v0.8: günün ritmi
## Günün ritmi: tarihten tohum ve şarkı; kayıtta "gunluk_ritim" (günlük koşudan ayrı).
static func gunun_tohumu(tarih: String) -> int:
	return absi(("tek-tus-kosu/ritim/" + tarih).hash())


static func gunun_sarkisi(tarih: String) -> int:
	return gunun_tohumu(tarih) % SARKILAR.size()


static func gunluk_durum(d: Dictionary) -> Dictionary:
	var g: Dictionary = d.get("gunluk_ritim", {})
	if str(g.get("tarih", "")) != Gunluk.bugun():
		g = {"tarih": Gunluk.bugun(), "rekor": 0, "deneme": 0, "olumler": []}
		d["gunluk_ritim"] = g
	return g


## Günün ritmi koşusunu işler. Dönüş: günün yeni rekoru mu?
static func gunluk_isle(d: Dictionary, mesafe: int) -> bool:
	var g := gunluk_durum(d)
	g["deneme"] = int(g["deneme"]) + 1
	var olumler: Array = g.get("olumler", [])
	olumler.append(mesafe)
	while olumler.size() > Ayarlar.OLUM_ISARETI_SAYISI:
		olumler.pop_front()
	g["olumler"] = olumler
	var yeni := mesafe > int(g["rekor"])
	if yeni:
		g["rekor"] = mesafe
	return yeni


static func adim(sarki_no: int) -> float:
	return HIZ * 60.0 / float(SARKILAR[clampi(sarki_no, 0, SARKILAR.size() - 1)]["bpm"])


## Ortalama sapmaya (ms, + geç) göre önerilen yeni gecikme ayarı; öneri yoksa null.
static func gecikme_onerisi(simdiki_ms: int, sapmalar: Array) -> Variant:
	if sapmalar.size() < ONERI_EN_AZ:
		return null
	var toplam := 0.0
	for m in sapmalar:
		toplam += float(m)
	var ort := toplam / sapmalar.size()
	if absf(ort) < ONERI_ESIK_MS:
		return null
	var yeni := int(round((simdiki_ms + ort) / 10.0)) * 10
	return clampi(yeni, GECIKME_ARALIK.x, GECIKME_ARALIK.y)

## Ölçü desenleri: [vuruş, tür]. Türler: diken, cukur, kisa (alçak tavan + kısa sıçrama).
## Ardışık olaylar arası en az 2 vuruş (tam zıplama 1,86 vuruş sürer), alçak tavana en az 3 (`desen_sec`).
## 3. vuruşta yalnız diken: çukur ve tavan geometrisi ölçü sınırını (parça sonunu) aşar.
const DESENLER := [
	{"ad": "bos", "zorluk": 0, "olaylar": []},
	{"ad": "diken0", "zorluk": 1, "olaylar": [[0, "diken"]]},
	{"ad": "diken2", "zorluk": 1, "olaylar": [[2, "diken"]]},
	{"ad": "cukur0", "zorluk": 1, "olaylar": [[0, "cukur"]]},
	{"ad": "cukur2", "zorluk": 1, "olaylar": [[2, "cukur"]]},
	{"ad": "kisa0", "zorluk": 1, "olaylar": [[0, "kisa"]]},
	{"ad": "ikili", "zorluk": 2, "olaylar": [[0, "diken"], [2, "diken"]]},
	{"ad": "karma", "zorluk": 2, "olaylar": [[0, "cukur"], [2, "diken"]]},
	{"ad": "kisa_diken", "zorluk": 2, "olaylar": [[0, "kisa"], [2, "diken"]]},
	{"ad": "cift_cukur", "zorluk": 2, "olaylar": [[0, "cukur"], [2, "cukur"]]},
	{"ad": "diken1", "zorluk": 1, "olaylar": [[1, "diken"]]},
	{"ad": "diken3", "zorluk": 1, "olaylar": [[3, "diken"]]},
	{"ad": "arka_vurus", "zorluk": 2, "olaylar": [[1, "diken"], [3, "diken"]]},
]


## x noktası kaçıncı vuruşa ne kadar uzak: [en yakın vuruş, sapma ms (+ geç, − erken)].
static func vurus_konumu(x: float, izgara0: float, adim_px := ADIM) -> Array:
	var k := (x - izgara0) / adim_px
	var n := int(round(k))
	return [n, (k - n) * adim_px / HIZ * 1000.0]


## Desenin türlerine göre şarkı ağırlığı çarpanı (desendeki her olay türü için çarpım).
static func desen_agirligi(d: Dictionary, sarki_no: int) -> float:
	var carpanlar: Dictionary = SARKILAR[clampi(sarki_no, 0, SARKILAR.size() - 1)].get("agirlik", {})
	var a := 1.0
	for olay in d["olaylar"]:
		a *= float(carpanlar.get(str(olay[1]), 1.0))
	return a


## Bir sonraki ölçü deseni. `olcu_no` koşunun kaçıncı ölçüsü; `onceki_son` önceki ölçünün son olay vuruşu (-1 yok).
static func desen_sec(rng: RandomNumberGenerator, olcu_no: int, onceki_son: int, sarki_no := 0) -> Dictionary:
	if olcu_no < ISINMA_OLCU:
		return DESENLER[0]
	var zor := 1 if olcu_no < 10 else 2
	var adaylar: Array = []
	var agirlik := PackedFloat32Array()
	for d in DESENLER:
		if int(d["zorluk"]) > zor:
			continue
		var olaylar: Array = d["olaylar"]
		# Önceki ölçünün son olayıyla bu ölçünün ilk olayı arası: zıplama 1,86 vuruş sürer → en az 2;
		# alçak tavan olay vuruşundan 0,5 vuruş önce başlar → iniş çarpmasın diye en az 3.
		if not olaylar.is_empty() and onceki_son >= 0:
			var ilk: Array = olaylar[0]
			var bosluk := OLCU - onceki_son + int(ilk[0])
			if bosluk < 2 or (str(ilk[1]) == "kisa" and bosluk < 3):
				continue
		adaylar.append(d)
		agirlik.append(0.6 if olaylar.is_empty() else (1.4 if int(d["zorluk"]) == zor else 1.0) * desen_agirligi(d, sarki_no))
	return adaylar[rng.rand_weighted(agirlik)]


## Ritim parçası üretir. bas_x: parçanın dünya x'i. Dönüş: [Parca, son olay vuruşu, olay vuruşları (dünya indeksleri)].
static func parca_uret(bas_x: float, izgara0: float, rng: RandomNumberGenerator, olcu_no: int, onceki_son: int, adim_px := ADIM, sarki_no := 0) -> Array:
	var k0 := int(ceil((bas_x - izgara0) / adim_px - 0.001))
	var giris := izgara0 + k0 * adim_px - bas_x          # parça başından ilk vuruşa (0..adım)
	var uzunluk := giris + PARCA_OLCU * OLCU * adim_px
	var p := Parca.new()
	p.name = "RitimParca"
	p.zorluk = 1
	p.uzunluk = uzunluk
	for ad in ["Giris", "Cikis"]:
		var m := Marker2D.new()
		m.name = ad
		m.position = Vector2(0.0 if ad == "Giris" else uzunluk, Ayarlar.ZEMIN_Y)
		p.add_child(m)
	var cukurlar: Array = []
	var olay_vuruslari: Array[int] = []
	var vuruslar := PackedFloat32Array()
	var zipla := PackedByteArray()
	var son := onceki_son
	var adlar: Array[String] = []
	for o in PARCA_OLCU:
		var d := desen_sec(rng, olcu_no + o, son, sarki_no)
		adlar.append(str(d["ad"]))
		var ozel := {}
		for olay in d["olaylar"]:
			ozel[int(olay[0])] = str(olay[1])
		son = -1 if ozel.is_empty() else int((d["olaylar"] as Array)[-1][0])
		for v in OLCU:
			var xb := giris + (o * OLCU + v) * adim_px
			vuruslar.append(xb)
			zipla.append(1 if ozel.has(v) else 0)
			if not ozel.has(v):
				continue
			olay_vuruslari.append(k0 + o * OLCU + v)
			match ozel[v]:
				"diken":
					_tehlike(p, Tehlike.Tur.DIKEN, xb + 99.0, 24.0, 12.0, Ayarlar.ZEMIN_Y)
					_altin(p, xb + 111.0, 196.0)
				"cukur":
					# 120 px: yürüyerek geçilmez; erken zıplamada (≈180 ms'ye kadar) iniş çukurun ötesine düşer.
					cukurlar.append(Vector2(xb + 40.0, xb + 160.0))
					_altin(p, xb + 100.0, 196.0)
				"kisa":
					_tehlike(p, Tehlike.Tur.TAVAN, xb - 60.0, 260.0, 20.0, 212.0)
					_tehlike(p, Tehlike.Tur.DIKEN, xb + 55.0, 24.0, 12.0, Ayarlar.ZEMIN_Y)
	# Zemin: çukurlar dışında her yer
	var x := 0.0
	for c in cukurlar:
		_zemin(p, x, c.x)
		x = c.y
	_zemin(p, x, uzunluk)
	var isaret := RitimIsaret.new()
	isaret.name = "RitimIsaret"
	isaret.vuruslar = vuruslar
	isaret.zipla = zipla
	isaret.cukurlar = cukurlar
	p.add_child(isaret)
	p.set_meta("desenler", adlar)
	return [p, son, olay_vuruslari]


static func _zemin(p: Parca, x0: float, x1: float) -> void:
	if x1 - x0 < 1.0:
		return
	var z := Zemin.new()
	z.name = "Zemin%d" % p.get_child_count()
	z.position = Vector2(x0, Ayarlar.ZEMIN_Y)
	z.genislik = x1 - x0
	z.yukseklik = Ayarlar.ZEMIN_ALT_Y - Ayarlar.ZEMIN_Y
	p.add_child(z)


static func _tehlike(p: Parca, tur: int, x: float, w: float, h: float, y: float) -> void:
	var t := Tehlike.new()
	t.name = "Tehlike%d" % p.get_child_count()
	t.tur = tur
	t.genislik = w
	t.yukseklik = h
	t.position = Vector2(x, y)
	p.add_child(t)


static func _altin(p: Parca, x: float, y: float) -> void:
	var a := Altin.new()
	a.name = "Altin%d" % p.get_child_count()
	a.position = Vector2(x, y)
	p.add_child(a)
