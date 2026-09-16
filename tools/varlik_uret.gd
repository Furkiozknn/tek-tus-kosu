extends SceneTree
## Pixel art üretici: tüm sprite'ları koddan üretir (Endesga 32 paleti).
##   godot --headless --path . -s res://tools/varlik_uret.gd
## Çıktı: assets/sprites/*.png. Tekrar çalıştırmak aynı dosyaları üretir (sabit tohum).

const P := {
	"kirmizi_koyu": "a22633", "kirmizi": "e43b44", "turuncu": "f77622", "sari_koyu": "feae34",
	"sari": "fee761", "yesil": "63c74d", "yesil_koyu": "3e8948", "orman": "265c42",
	"deniz": "193c3e", "mavi_koyu": "124e89", "mavi": "0099db", "camgobegi": "2ce8f5",
	"beyaz": "ffffff", "gri_acik": "c0cbdc", "gri": "8b9bb4", "gri_koyu": "5a6988",
	"lacivert": "3a4466", "gece": "262b44", "siyah": "181425", "pembe_parlak": "ff0044",
	"mor": "68386c", "pembe": "b55088", "somon": "f6757a", "ten": "e4a672", "ten_koyu": "b86f50",
	"kahve": "733e39", "kahve_koyu": "3e2731", "bej": "ead4aa", "tugla": "be4a2f", "tugla_acik": "d77643",
}

const KARE_G := 20
const KARE_Y := 26

## Kostümler: kapüşon ana/gölge, atkı ana/gölge, pantolon, şapka türü
const KOSTUMLER := {
	"klasik": {"kap": "mavi", "kap_g": "mavi_koyu", "atki": "kirmizi", "atki_g": "kirmizi_koyu", "pant": "lacivert", "sapka": ""},
	"kizil":  {"kap": "kirmizi", "kap_g": "kirmizi_koyu", "atki": "sari_koyu", "atki_g": "turuncu", "pant": "kahve_koyu", "sapka": "bere"},
	"orman":  {"kap": "yesil", "kap_g": "yesil_koyu", "atki": "bej", "atki_g": "ten_koyu", "pant": "orman", "sapka": "yaprak"},
	"neon":   {"kap": "pembe", "kap_g": "mor", "atki": "camgobegi", "atki_g": "mavi", "pant": "gece", "sapka": "kulaklik"},
	"altin":  {"kap": "turuncu", "kap_g": "tugla", "atki": "beyaz", "atki_g": "gri_acik", "pant": "kahve", "sapka": "tac"},
}

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	rng.seed = 20260916
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites"))
	for ad in KOSTUMLER:
		_kaydet(_oyuncu_seridi(KOSTUMLER[ad]), "oyuncu_%s" % ad)
	_kaydet(_altin_seridi(), "altin")
	_kaydet(_zemin_karolari(), "zemin")
	_kaydet(_diken(), "diken")
	_kaydet(_blok_deseni(), "blok")
	_kaydet(_tavan_engeli(), "tavan_engeli")
	_kaydet(_piston(), "piston")
	_kaydet(_platform(), "platform")
	_kaydet(_yildizlar(), "yildizlar")
	_kaydet(_sehir(640, 150, 90, 150, 26, 60, "lacivert", "gri_koyu", 0.10), "sehir_uzak")
	_kaydet(_sehir(640, 190, 70, 140, 40, 90, "siyah", "gece", 0.16), "sehir_yakin")
	_kaydet(_ay(), "ay")
	_kaydet(_nokta(), "parcacik")
	print("Varlıklar üretildi.")
	quit(0)


func c(ad: String) -> Color:
	return Color(P[ad])


func _kaydet(img: Image, ad: String) -> void:
	var yol := "res://assets/sprites/%s.png" % ad
	var e := img.save_png(ProjectSettings.globalize_path(yol))
	if e != OK:
		push_error("Kaydedilemedi: " + yol)


func _bos(g: int, y: int) -> Image:
	var img := Image.create(g, y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


func _nokta_koy(img: Image, x: int, y: int, renk: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, renk)


func _dikdortgen(img: Image, x: int, y: int, g: int, h: int, renk: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + g):
			_nokta_koy(img, xx, yy, renk)


## Kalın çizgi (kare fırça)
func _cizgi(img: Image, a: Vector2, b: Vector2, kalinlik: int, renk: Color) -> void:
	var adim := int(ceil(a.distance_to(b))) + 1
	for i in adim + 1:
		var p := a.lerp(b, float(i) / max(adim, 1))
		for oy in kalinlik:
			for ox in kalinlik:
				_nokta_koy(img, int(round(p.x)) + ox - kalinlik / 2, int(round(p.y)) + oy - kalinlik / 2, renk)


## Opak piksellerin çevresine dış çizgi ekler (ayrı bir kare bölgesi içinde).
func _dis_cizgi(img: Image, bolge: Rect2i, renk: Color) -> void:
	var kopya := img.duplicate() as Image
	for y in range(bolge.position.y, bolge.end.y):
		for x in range(bolge.position.x, bolge.end.x):
			if kopya.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if bolge.has_point(q) and kopya.get_pixel(q.x, q.y).a > 0.0:
					img.set_pixel(x, y, renk)
					break


# ---------------------------------------------------------------- oyuncu
## Kareler: 0-7 koşu, 8 zıplama, 9 düşüş, 10-11 ikinci zıplama (takla), 12-13 bekleme, 14 ölüm
func _oyuncu_seridi(k: Dictionary) -> Image:
	var n := 15
	var img := _bos(KARE_G * n, KARE_Y)
	for i in 8:
		var t := float(i) / 8.0 * TAU
		_oyuncu_kare(img, i, k, {"bacak": sin(t), "diz": cos(t), "sallan": -sin(t), "sek": absf(sin(t)) * 1.0, "atki": i % 2})
	_oyuncu_kare(img, 8, k, {"poz": "zipla", "atki": 0})
	_oyuncu_kare(img, 9, k, {"poz": "dus", "atki": 1})
	_oyuncu_kare(img, 10, k, {"poz": "takla", "atki": 0})
	_oyuncu_kare(img, 11, k, {"poz": "takla2", "atki": 1})
	_oyuncu_kare(img, 12, k, {"poz": "bekle", "sek": 0.0, "atki": 0})
	_oyuncu_kare(img, 13, k, {"poz": "bekle", "sek": 1.0, "atki": 1})
	_oyuncu_kare(img, 14, k, {"poz": "olum", "atki": 0})
	for i in n:
		_dis_cizgi(img, Rect2i(i * KARE_G, 0, KARE_G, KARE_Y), c("siyah"))
	return img


func _oyuncu_kare(img: Image, i: int, k: Dictionary, o: Dictionary) -> void:
	var ox := i * KARE_G
	var poz: String = o.get("poz", "kos")
	var sek := int(round(float(o.get("sek", 0.0))))
	var kap := c(k["kap"])
	var kap_g := c(k["kap_g"])
	var pant := c(k["pant"])
	var pant_g := pant.darkened(0.3)
	var ayak := c("siyah").lightened(0.15)
	var olum := poz == "olum"
	if olum:
		kap = c("gri")
		kap_g = c("gri_koyu")
	var kalca := Vector2(ox + 9, 16 - sek)
	var omuz := Vector2(ox + 9, 10 - sek)
	var bas := Vector2(ox + 10, 6 - sek)

	# Bacaklar: [uzak, yakın]
	var bacaklar := []
	match poz:
		"kos":
			var b: float = o["bacak"]
			bacaklar = [_bacak(kalca, -b * 0.8, maxf(0.0, -float(o["diz"])) * 1.2),
				_bacak(kalca, b * 0.8, maxf(0.0, float(o["diz"])) * 1.2)]
		"zipla":
			bacaklar = [_bacak(kalca, -0.5, 1.4), _bacak(kalca, 0.9, 1.2)]
		"dus":
			bacaklar = [_bacak(kalca, -0.35, 0.3), _bacak(kalca, 0.45, 0.5)]
		"takla", "takla2":
			bacaklar = [_bacak(kalca, 0.3, 2.2), _bacak(kalca, 1.0, 2.0)]
		"bekle":
			bacaklar = [_bacak(kalca, -0.15, 0.0), _bacak(kalca, 0.15, 0.0)]
		"olum":
			bacaklar = [_bacak(kalca, -0.6, 0.2), _bacak(kalca, 0.6, 0.2)]
	# Uzak bacak
	_cizgi(img, bacaklar[0][0], bacaklar[0][1], 3, pant_g)
	_cizgi(img, bacaklar[0][1], bacaklar[0][2], 2, pant_g)
	_nokta_koy(img, int(bacaklar[0][2].x) + 1, int(bacaklar[0][2].y), ayak)
	# Uzak kol
	var kol_a := 0.0
	match poz:
		"kos": kol_a = float(o["sallan"]) * 1.1
		"zipla": kol_a = -2.4
		"dus": kol_a = -2.0
		"takla", "takla2": kol_a = 1.2
		"bekle": kol_a = 0.15
		"olum": kol_a = -2.6
	_kol(img, omuz, -kol_a, kap_g)
	# Gövde
	_dikdortgen(img, int(omuz.x) - 3, int(omuz.y), 6, int(kalca.y - omuz.y) + 1, kap)
	_dikdortgen(img, int(omuz.x) - 3, int(omuz.y), 2, int(kalca.y - omuz.y) + 1, kap_g)
	_dikdortgen(img, int(kalca.x) - 3, int(kalca.y) - 1, 6, 2, pant)
	# Yakın bacak
	_cizgi(img, bacaklar[1][0], bacaklar[1][1], 3, pant)
	_cizgi(img, bacaklar[1][1], bacaklar[1][2], 2, pant)
	_dikdortgen(img, int(bacaklar[1][2].x), int(bacaklar[1][2].y), 3, 1, ayak)
	# Baş (kapüşon + yüz)
	for yy in range(-4, 5):
		for xx in range(-4, 5):
			if xx * xx + yy * yy <= 17:
				_nokta_koy(img, int(bas.x) + xx, int(bas.y) + yy, kap)
	for yy in range(-4, 5):
		_nokta_koy(img, int(bas.x) - 4, int(bas.y) + yy, kap_g)
	var ten := c("ten") if not olum else c("gri_acik")
	_dikdortgen(img, int(bas.x) + 0, int(bas.y) - 1, 4, 4, ten)
	_dikdortgen(img, int(bas.x) + 0, int(bas.y) + 2, 4, 1, c("ten_koyu") if not olum else c("gri"))
	if olum:
		_nokta_koy(img, int(bas.x) + 2, int(bas.y), c("siyah"))
		_nokta_koy(img, int(bas.x) + 3, int(bas.y) + 1, c("siyah"))
		_nokta_koy(img, int(bas.x) + 3, int(bas.y) - 1, c("siyah"))
	else:
		_dikdortgen(img, int(bas.x) + 2, int(bas.y) - 1, 1, 2, c("siyah"))
	# Atkı + uçuşan kuyruk
	var atki := c(k["atki"])
	var atki_g := c(k["atki_g"])
	_dikdortgen(img, int(omuz.x) - 3, int(omuz.y) - 1, 7, 2, atki)
	var dalga: int = o.get("atki", 0)
	_cizgi(img, Vector2(omuz.x - 3, omuz.y - 1), Vector2(omuz.x - 7, omuz.y - 1 + dalga), 2, atki_g)
	_nokta_koy(img, int(omuz.x) - 8, int(omuz.y) + dalga * 2, atki_g)
	# Yakın kol
	_kol(img, omuz, kol_a, kap)
	# Şapka
	_sapka(img, bas, str(k["sapka"]))
	# Takla ikinci karesi: yatay ayna değil, bir piksel yukarı kaydır (dönme hissi)
	if poz == "takla2":
		var parca := img.get_region(Rect2i(ox, 1, KARE_G, KARE_Y - 1))
		_dikdortgen(img, ox, 0, KARE_G, KARE_Y, Color(0, 0, 0, 0))
		img.blit_rect(parca, Rect2i(0, 0, KARE_G, KARE_Y - 1), Vector2i(ox, 0))


func _bacak(kalca: Vector2, aci: float, bukum: float) -> Array:
	var diz := kalca + Vector2(sin(aci), cos(aci)) * 5.0
	var ayak_aci := aci - bukum
	var ayak := diz + Vector2(sin(ayak_aci), cos(ayak_aci)) * 4.5
	ayak.y = minf(ayak.y, 24.0)
	return [kalca, diz, ayak]


func _kol(img: Image, omuz: Vector2, aci: float, renk: Color) -> void:
	var dirsek := omuz + Vector2(sin(aci), cos(aci)) * 3.5
	var el := dirsek + Vector2(sin(aci + 0.6), cos(aci + 0.6)) * 3.0
	_cizgi(img, omuz + Vector2(0, 1), dirsek, 2, renk)
	_cizgi(img, dirsek, el, 2, renk)
	_nokta_koy(img, int(round(el.x)), int(round(el.y)), c("ten"))


func _sapka(img: Image, bas: Vector2, tur: String) -> void:
	var x := int(bas.x)
	var y := int(bas.y)
	match tur:
		"bere":
			_dikdortgen(img, x - 4, y - 5, 8, 2, c("sari_koyu"))
			_dikdortgen(img, x - 2, y - 7, 4, 2, c("sari_koyu"))
			_nokta_koy(img, x, y - 8, c("beyaz"))
		"yaprak":
			_cizgi(img, Vector2(x, y - 4), Vector2(x + 2, y - 8), 1, c("yesil_koyu"))
			_dikdortgen(img, x + 1, y - 9, 3, 2, c("yesil"))
		"kulaklik":
			_dikdortgen(img, x - 4, y - 5, 9, 1, c("gece"))
			_dikdortgen(img, x - 5, y - 1, 2, 3, c("camgobegi"))
			_dikdortgen(img, x + 4, y - 1, 2, 3, c("camgobegi"))
		"tac":
			_dikdortgen(img, x - 3, y - 6, 7, 2, c("sari"))
			for dx in [-3, 0, 3]:
				_nokta_koy(img, x + dx, y - 7, c("sari"))
			_nokta_koy(img, x, y - 6, c("kirmizi"))


# ---------------------------------------------------------------- nesneler
## 4 kareli dönen altın, 12x12
func _altin_seridi() -> Image:
	var img := _bos(48, 12)
	var genislikler := [5, 3, 1, 3]
	for i in 4:
		var w: int = genislikler[i]
		var cx := i * 12 + 6
		for yy in range(-5, 5):
			for xx in range(-w, w + 1):
				var nx := float(xx) / (w + 0.5)
				var ny := (yy + 0.5) / 5.0
				if nx * nx + ny * ny <= 1.0:
					var renk := c("sari") if xx < w / 2.0 else c("sari_koyu")
					if w > 1 and absf(float(xx)) < 1.0 and absf(float(yy)) < 3.0:
						renk = c("turuncu")
					_nokta_koy(img, cx + xx, 6 + yy, renk)
		_nokta_koy(img, cx - w + 1, 3, c("beyaz"))
	for i in 4:
		_dis_cizgi(img, Rect2i(i * 12, 0, 12, 12), c("kahve_koyu"))
	return img


## Zemin karoları 16x16: 0 çatı kenarı, 1 tuğla, 2 tuğla+ışıklı pencere, 3 tuğla+sönük pencere, 4 platform kirişi
func _zemin_karolari() -> Image:
	var img := _bos(80, 16)
	# 0: çatı kenarı (beton saçak) + tuğla alt
	_tugla(img, 0, 0)
	_dikdortgen(img, 0, 0, 16, 5, c("gri"))
	_dikdortgen(img, 0, 0, 16, 1, c("gri_acik"))
	_dikdortgen(img, 0, 4, 16, 1, c("gri_koyu"))
	_dikdortgen(img, 0, 5, 16, 1, c("kahve_koyu"))
	for x in [3, 11]:
		_nokta_koy(img, x, 2, c("gri_koyu"))
	# 1-3: tuğla
	_tugla(img, 16, 0)
	_tugla(img, 32, 0)
	_pencere(img, 32, true)
	_tugla(img, 48, 0)
	_pencere(img, 48, false)
	# 4: kiriş
	_dikdortgen(img, 64, 0, 16, 6, c("turuncu"))
	_dikdortgen(img, 64, 0, 16, 1, c("sari_koyu"))
	_dikdortgen(img, 64, 5, 16, 1, c("kahve"))
	for i in 3:
		_cizgi(img, Vector2(64 + i * 6, 1), Vector2(64 + i * 6 + 4, 4), 1, c("kahve"))
	return img


func _tugla(img: Image, ox: int, oy: int) -> void:
	_dikdortgen(img, ox, oy, 16, 16, c("kahve_koyu"))
	for sira in 4:
		var y := oy + sira * 4
		var kay := 0 if sira % 2 == 0 else 4
		for k in 3:
			var x := ox + kay + k * 8 - 4
			for xx in range(maxi(x, ox), mini(x + 7, ox + 16)):
				for yy in range(y, y + 3):
					var r := c("kahve") if (xx + yy) % 5 != 0 else c("tugla")
					_nokta_koy(img, xx, yy, r)


func _pencere(img: Image, ox: int, isikli: bool) -> void:
	_dikdortgen(img, ox + 4, 5, 8, 8, c("siyah"))
	var cam := c("sari") if isikli else c("gece")
	_dikdortgen(img, ox + 5, 6, 6, 6, cam)
	_dikdortgen(img, ox + 5, 9, 6, 1, c("siyah"))
	_dikdortgen(img, ox + 8, 6, 1, 6, c("siyah"))
	if isikli:
		_nokta_koy(img, ox + 5, 6, c("beyaz"))


## Diken 12x12: metal gövde, kırmızı uç, koyu dış çizgi
func _diken() -> Image:
	var img := _bos(12, 12)
	for y in range(1, 12):
		var yari := int(float(y) / 11.0 * 5.5)
		for x in range(6 - yari, 6 + yari):
			var renk := c("gri_acik") if x < 6 else c("gri")
			if y < 5:
				renk = c("kirmizi") if x < 6 else c("kirmizi_koyu")
			_nokta_koy(img, x, y, renk)
	_dikdortgen(img, 0, 10, 12, 2, c("gri_koyu"))
	_dis_cizgi(img, Rect2i(0, 0, 12, 12), c("siyah"))
	return img


## Blok (öldüren elektrik kutusu) için 8x8 uyarı şeridi deseni
func _blok_deseni() -> Image:
	var img := _bos(8, 8)
	for y in 8:
		for x in 8:
			var serit := int(floor((x + y) / 4.0)) % 2 == 0
			img.set_pixel(x, y, c("sari_koyu") if serit else c("siyah"))
	return img


## Tavandan sarkan tabela 32x20 (üstte zincir)
func _tavan_engeli() -> Image:
	var img := _bos(32, 20)
	_dikdortgen(img, 6, 0, 1, 6, c("gri"))
	_dikdortgen(img, 25, 0, 1, 6, c("gri"))
	_dikdortgen(img, 1, 6, 30, 13, c("kirmizi_koyu"))
	_dikdortgen(img, 2, 7, 28, 11, c("kirmizi"))
	for i in 3:
		_dikdortgen(img, 6 + i * 8, 10, 4, 5, c("beyaz"))
	_dikdortgen(img, 2, 17, 28, 1, c("kirmizi_koyu"))
	_dis_cizgi(img, Rect2i(0, 0, 32, 20), c("siyah"))
	return img


## Piston dikeni 24x24: üstte diken sırası, altta metal gövde
func _piston() -> Image:
	var img := _bos(24, 24)
	_dikdortgen(img, 2, 8, 20, 16, c("gri_koyu"))
	_dikdortgen(img, 3, 9, 18, 14, c("gri"))
	for i in 3:
		_dikdortgen(img, 5 + i * 6, 12, 2, 9, c("gri_koyu"))
	for k in 4:
		var bx := 1 + k * 6
		for y in range(0, 8):
			var yari := int(float(y) / 7.0 * 3.0)
			for x in range(bx + 3 - yari, bx + 3 + yari):
				_nokta_koy(img, x, y, c("kirmizi") if y < 4 else c("gri_acik"))
	_dis_cizgi(img, Rect2i(0, 0, 24, 24), c("siyah"))
	return img


## Hareketli platform 16x8 (kiriş + ışık)
func _platform() -> Image:
	var img := _bos(16, 8)
	_dikdortgen(img, 0, 1, 16, 6, c("mavi_koyu"))
	_dikdortgen(img, 0, 1, 16, 1, c("mavi"))
	_dikdortgen(img, 0, 6, 16, 1, c("gece"))
	_nokta_koy(img, 3, 3, c("camgobegi"))
	_nokta_koy(img, 12, 3, c("camgobegi"))
	return img


# ---------------------------------------------------------------- arka plan
func _yildizlar() -> Image:
	var img := _bos(320, 180)
	for i in 70:
		var x := rng.randi_range(0, 319)
		var y := rng.randi_range(0, 179)
		var parlak := rng.randf() < 0.2
		_nokta_koy(img, x, y, c("beyaz") if parlak else c("gri"))
		if parlak and rng.randf() < 0.5:
			_nokta_koy(img, x + 1, y, c("gri_koyu"))
			_nokta_koy(img, x - 1, y, c("gri_koyu"))
			_nokta_koy(img, x, y + 1, c("gri_koyu"))
			_nokta_koy(img, x, y - 1, c("gri_koyu"))
	return img


## Döşenebilir şehir silüeti (soldan sağa kesintisiz)
func _sehir(g: int, h: int, min_h: int, max_h: int, min_w: int, max_w: int, govde: String, kenar: String, pencere_orani: float) -> Image:
	var img := _bos(g, h)
	var x := 0
	while x < g:
		var w := rng.randi_range(min_w, max_w)
		if x + w > g:
			w = g - x
		var bh := rng.randi_range(min_h, max_h)
		var ust := h - bh
		_dikdortgen(img, x, ust, w, bh, c(govde))
		_dikdortgen(img, x, ust, w, 1, c(kenar))
		# çatı ayrıntısı
		var ayr := rng.randi_range(0, 3)
		if ayr == 0 and w > 12:
			_dikdortgen(img, x + w / 2, ust - 8, 1, 8, c(kenar))
			_nokta_koy(img, x + w / 2, ust - 9, c("kirmizi"))
		elif ayr == 1 and w > 16:
			_dikdortgen(img, x + 3, ust - 5, 8, 5, c(govde))
		# pencereler
		for py in range(ust + 4, h - 2, 6):
			for px in range(x + 3, x + w - 3, 5):
				if rng.randf() < pencere_orani:
					var renk := c("sari") if rng.randf() < 0.7 else c("camgobegi")
					_dikdortgen(img, px, py, 2, 2, renk)
		x += w + rng.randi_range(0, 3)
	return img


func _ay() -> Image:
	var img := _bos(28, 28)
	for y in 28:
		for x in 28:
			var d := Vector2(x - 13.5, y - 13.5).length()
			var golge := Vector2(x - 18.0, y - 10.0).length()
			if d < 12.5 and golge > 10.5:
				img.set_pixel(x, y, c("bej") if d < 11.0 else c("gri_acik"))
	return img


func _nokta() -> Image:
	var img := _bos(2, 2)
	img.fill(Color.WHITE)
	return img
