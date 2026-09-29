extends SceneTree
## Duz renkli sprite uretici (tanitim videosundaki dunya: geometrik, golgesiz,
## dis cizgisiz). Kenarlar 4x4 alt ornekleme ile yumusatilir.
##   godot --headless --path . -s res://tools/varlik_uret.gd
## Cikti: assets/sprites/*.png. Tekrar calistirmak ayni dosyalari uretir (sabit tohum).
## Dikenler, bloklar, zemin, platform ve piston sprite degil: scripts/*.gd icinde
## _draw ile cizilir (eski pixel-art PNG'ler _eski/sprites/ altinda).

const MUREKKEP := Color("120d1f")
const KAGIT := Color("f5edfe")
const PEMBE := Color("fd2c88")
const SARI := Color("ffc21a")
const CAM := Color("22e4ff")

const KARE_G := 20
const KARE_Y := 26

## Kostumler: govde rengi, tac (yalniz altin)
const KOSTUMLER := {
	"klasik": {"govde": "fd2c88", "tac": false},
	"kizil": {"govde": "ff5a36", "tac": false},
	"orman": {"govde": "3ddc97", "tac": false},
	"neon": {"govde": "b399ff", "tac": false},
	"altin": {"govde": "f5edfe", "tac": true},
}

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	rng.seed = 20260929
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites"))
	for ad in KOSTUMLER:
		_kaydet(_oyuncu_seridi(KOSTUMLER[ad]), "oyuncu_%s" % ad)
	_kaydet(_altin_seridi(), "altin")
	_kaydet(_yildizlar(), "yildizlar")
	# Beyaz siluet: oyun.gd temaya gore renklendirir (modulate).
	_kaydet(_sehir(640, 150, 70, 130, 44, 110), "sehir_uzak")
	_kaydet(_sehir(640, 190, 60, 150, 56, 140), "sehir_yakin")
	_kaydet(_nokta(), "parcacik")
	print("Varlıklar üretildi.")
	quit(0)


func _kaydet(img: Image, ad: String) -> void:
	var yol := "res://assets/sprites/%s.png" % ad
	var e := img.save_png(ProjectSettings.globalize_path(yol))
	if e != OK:
		push_error("Kaydedilemedi: " + yol)


func _bos(g: int, y: int) -> Image:
	var img := Image.create(g, y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


## Yuvarlatilmis dikdortgenin isaretli mesafesi (negatif = icerde). Merkez c, yari boyut h, aci a (rad).
func _sdf_kutu(p: Vector2, c: Vector2, h: Vector2, r: float, a: float) -> float:
	var q := (p - c).rotated(-a)
	var d := Vector2(absf(q.x), absf(q.y)) - h + Vector2(r, r)
	return Vector2(maxf(d.x, 0.0), maxf(d.y, 0.0)).length() + minf(maxf(d.x, d.y), 0.0) - r


## Sekli bir kareye boyar; sekil(p) -> Color (alfa 0 = bos). 4x4 ornekleme.
func _boya(img: Image, ox: int, oy: int, g: int, y: int, sekil: Callable) -> void:
	for py in y:
		for px in g:
			var r := 0.0
			var gr := 0.0
			var b := 0.0
			var a := 0.0
			for sy in 4:
				for sx in 4:
					var c: Color = sekil.call(Vector2(px + (sx + 0.5) / 4.0, py + (sy + 0.5) / 4.0))
					if c.a > 0.0:
						r += c.r * c.a
						gr += c.g * c.a
						b += c.b * c.a
						a += c.a
			if a > 0.0:
				var mevcut := img.get_pixel(ox + px, oy + py)
				var yeni := Color(r / a, gr / a, b / a, a / 16.0)
				if mevcut.a > 0.0:
					yeni = mevcut.blend(yeni)
				img.set_pixel(ox + px, oy + py, yeni)


# ---------------------------------------------------------------- oyuncu
## Kareler: 0-7 kosu, 8 ziplama, 9 dusus, 10-11 ikinci ziplama (takla), 12-13 bekleme, 14 olum
func _oyuncu_seridi(k: Dictionary) -> Image:
	var n := 15
	var img := _bos(KARE_G * n, KARE_Y)
	var govde := Color(str(k["govde"]))
	for i in 8:
		var t := float(i) / 8.0 * TAU
		_kare(img, i, govde, k["tac"], {"sek": absf(sin(t)), "egim": 0.07})
	_kare(img, 8, govde, k["tac"], {"gen": 12.0, "boy": 22.0, "egim": 0.0})
	_kare(img, 9, govde, k["tac"], {"gen": 15.0, "boy": 19.0, "egim": 0.0})
	_kare(img, 10, govde, k["tac"], {"aci": 0.6, "gen": 14.0, "boy": 14.0})
	_kare(img, 11, govde, k["tac"], {"aci": 1.9, "gen": 14.0, "boy": 14.0})
	_kare(img, 12, govde, k["tac"], {"boy": 20.0})
	_kare(img, 13, govde, k["tac"], {"boy": 19.0, "gen": 15.0})
	_kare(img, 14, govde.lerp(Color("8d84a6"), 0.75), false, {"olum": true, "gen": 15.0, "boy": 18.0})
	return img


func _kare(img: Image, i: int, govde: Color, tac: bool, o: Dictionary) -> void:
	var gen: float = o.get("gen", 14.0)
	var boy: float = o.get("boy", 20.0)
	var sek: float = o.get("sek", 0.0)
	var aci: float = o.get("aci", o.get("egim", 0.0))
	var olum: bool = o.get("olum", false)
	var dip := 24.6 - sek * 1.2            # ayak yuzeyi (koşuda hafif sekme)
	var c := Vector2(10.0, dip - boy * 0.5)
	if o.has("aci"):
		c.y = 14.0
	var h := Vector2(gen * 0.5, boy * 0.5)
	var yaricap := 4.6
	var goz_c := c + Vector2(gen * 0.18, -boy * 0.16).rotated(aci)
	_boya(img, i * KARE_G, 0, KARE_G, KARE_Y, func(p: Vector2) -> Color:
		if _sdf_kutu(p, c, h, yaricap, aci) <= 0.0:
			if not olum and _sdf_kutu(p, goz_c, Vector2(1.3, 2.4), 0.6, aci) <= 0.0:
				return MUREKKEP
			if olum:
				# Carpi goz: iki kisa capraz cizgi
				var q := (p - goz_c).rotated(-aci)
				if absf(q.x) < 2.6 and absf(q.y) < 2.6 and (absf(q.x - q.y) < 0.7 or absf(q.x + q.y) < 0.7):
					return MUREKKEP
			return govde
		if tac and not o.has("aci"):
			# Tac: govdenin ustunde uc kucuk ucgen
			var ty := c.y - h.y
			for dx in [-4.5, 0.0, 4.5]:
				var tx: float = c.x + dx
				var dy := ty - p.y
				if dy > -0.5 and dy < 4.2 and absf(p.x - tx) < (4.2 - dy) * 0.62 + 0.0:
					return SARI
		return Color(0, 0, 0, 0))


# ---------------------------------------------------------------- nesneler
## 4 kareli donen altin (camgobegi disk, 12x12): yatay olcek 1, 0.6, 0.15, 0.6
func _altin_seridi() -> Image:
	var img := _bos(48, 12)
	var olcekler := [1.0, 0.62, 0.16, 0.62]
	for i in 4:
		var w: float = 5.2 * olcekler[i]
		_boya(img, i * 12, 0, 12, 12, func(p: Vector2) -> Color:
			var q := (p - Vector2(6.0, 6.0)) / Vector2(maxf(w, 0.4), 5.2)
			return CAM if q.length() <= 1.0 else Color(0, 0, 0, 0))
	return img


# ---------------------------------------------------------------- arka plan
func _yildizlar() -> Image:
	var img := _bos(320, 180)
	for i in 34:
		var x := rng.randi_range(0, 319)
		var y := rng.randi_range(0, 150)
		img.set_pixel(x, y, KAGIT if rng.randf() < 0.25 else Color(KAGIT, 0.55))
	return img


## Dosenebilir, video gibi basamakli beyaz siluet (soldan saga kesintisiz): dikdortgen bloklar,
## bazilarinin yaninda bir basamak. Ilk ve son blok ayni yukseklikte (dikis gorunmez).
func _sehir(g: int, h: int, min_h: int, max_h: int, min_w: int, max_w: int) -> Image:
	var img := _bos(g, h)
	var x := 0
	var ilk_h := -1
	while x < g:
		var w := rng.randi_range(min_w, max_w)
		if g - (x + w) < min_w:
			w = g - x
		var bh := rng.randi_range(min_h, max_h)
		if ilk_h < 0:
			ilk_h = bh
		if x + w >= g:
			bh = ilk_h
		for yy in range(h - bh, h):
			for xx in range(x, mini(x + w, g)):
				img.set_pixel(xx, yy, Color.WHITE)
		# basamak: blogun sag kenarina alcak bir omuz
		if x + w < g and rng.randf() < 0.6:
			var sw := mini(rng.randi_range(14, 30), g - (x + w))
			var sh := int(bh * rng.randf_range(0.55, 0.85))
			for yy in range(h - sh, h):
				for xx in range(x + w, x + w + sw):
					img.set_pixel(xx, yy, Color.WHITE)
			w += sw
		x += w
	return img


func _nokta() -> Image:
	var img := _bos(2, 2)
	img.fill(Color.WHITE)
	return img
