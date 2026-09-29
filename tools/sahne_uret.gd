extends SceneTree
## Sahne üretici. Parça ve arayüz sahnelerini koddan üretir, böylece .tscn
## dosyaları her zaman geçerli olur. Parça eklemek/değiştirmek için
## PARCALAR listesini düzenle ve çalıştır:
##   godot --headless --path . -s res://tools/sahne_uret.gd

const ZY := 280.0  # Ayarlar.ZEMIN_Y (araç bağımsız çalışsın diye kopya)

## Öğe türleri:
##  ["zemin", x0, x1, (ust_y)]            katı zemin
##  ["platform", x0, x1, y]               tek yönlü sabit kiriş (6 px)
##  ["hareketli", x, y, genislik, dx, dy, periyot]  gidip gelen tek yönlü platform
##  ["diken", x, genislik, (taban_y)]      yüzey üstünde diken (12 px)
##  ["blok", x, genislik, yukseklik]       zemin üstünde öldüren blok
##  ["tavan", x0, x1, (alt_y)]             tavandan sarkan tabela (altından koşulur, tam zıplama öldürür)
##  ["piston", x, genislik, yukseklik, faz] yükselip inen diken
##  ["altin", x, y]
##  ["altin_dizi", x, y, adet, aralik]
##  ["altin_kavis", orta_x, tepe_y, adet, genislik]
## zorluk 0 = "nefes" parçası (3-8 tehlikeli parçada bir gelir)
const TAVAN_ALT := 212.0
const PARCALAR := [
	{"ad": "01_duz", "zorluk": 1, "uzunluk": 640, "ogeler": [
		["zemin", 0, 640], ["altin_dizi", 240, 250, 5, 36]]},
	{"ad": "02_tek_diken", "zorluk": 1, "uzunluk": 640, "ogeler": [
		["zemin", 0, 640], ["diken", 300, 36], ["altin_kavis", 318, 196, 5, 120]]},
	{"ad": "03_kucuk_cukur", "zorluk": 1, "uzunluk": 640, "ogeler": [
		["zemin", 0, 280], ["zemin", 370, 640], ["altin_kavis", 325, 200, 3, 80]]},
	{"ad": "04_iki_diken", "zorluk": 1, "uzunluk": 800, "ogeler": [
		["zemin", 0, 800], ["diken", 250, 36], ["diken", 540, 48], ["altin_dizi", 380, 250, 3, 30]]},
	{"ad": "05_basamak", "zorluk": 1, "uzunluk": 760, "ogeler": [
		["zemin", 0, 300], ["zemin", 300, 560, 240], ["zemin", 560, 760],
		["altin_dizi", 360, 210, 5, 36]]},
	{"ad": "06_blok", "zorluk": 2, "uzunluk": 760, "ogeler": [
		["zemin", 0, 760], ["blok", 380, 28, 48], ["altin_kavis", 394, 180, 5, 110]]},
	{"ad": "07_genis_cukur", "zorluk": 2, "uzunluk": 800, "ogeler": [
		["zemin", 0, 300], ["zemin", 460, 800], ["altin_kavis", 380, 190, 5, 140]]},
	{"ad": "08_platform", "zorluk": 2, "uzunluk": 960, "ogeler": [
		["zemin", 0, 300], ["platform", 380, 540, 250], ["zemin", 640, 960],
		["altin_dizi", 404, 225, 4, 36]]},
	{"ad": "09_merdiven", "zorluk": 2, "uzunluk": 960, "ogeler": [
		["zemin", 0, 300], ["zemin", 300, 520, 240], ["zemin", 520, 740, 200], ["zemin", 740, 960],
		["altin_dizi", 360, 210, 3, 40], ["altin_dizi", 580, 170, 3, 40]]},
	{"ad": "10_diken_blok", "zorluk": 3, "uzunluk": 1300, "ogeler": [
		["zemin", 0, 1300], ["diken", 200, 60], ["blok", 660, 30, 60], ["diken", 1090, 40],
		["altin_kavis", 675, 170, 5, 140]]},
	{"ad": "11_buyuk_cukur", "zorluk": 3, "uzunluk": 900, "ogeler": [
		["zemin", 0, 300], ["zemin", 520, 900], ["altin_kavis", 410, 170, 5, 180]]},
	{"ad": "12_cukur_diken", "zorluk": 3, "uzunluk": 1100, "ogeler": [
		["zemin", 0, 280], ["zemin", 400, 1100], ["diken", 720, 48],
		["altin_kavis", 340, 190, 3, 100], ["altin_kavis", 744, 196, 3, 90]]},
	# --- v0.2: nefes parçaları ---
	{"ad": "13_nefes_altin", "zorluk": 0, "uzunluk": 800, "ogeler": [
		["zemin", 0, 800], ["altin_kavis", 250, 220, 5, 140], ["altin_kavis", 520, 220, 5, 140]]},
	{"ad": "14_nefes_asansor", "zorluk": 0, "uzunluk": 900, "ogeler": [
		["zemin", 0, 900], ["hareketli", 380, 225, 64, 70, 0, 2.6],
		["altin_dizi", 360, 200, 5, 26]]},
	{"ad": "15_nefes_kiris", "zorluk": 0, "uzunluk": 900, "ogeler": [
		["zemin", 0, 900], ["platform", 300, 460, 236], ["platform", 520, 680, 200],
		["altin_dizi", 320, 222, 4, 36], ["altin_dizi", 540, 186, 4, 36]]},
	# --- v0.2: yeni öğeler (önce kolay parçada tanıtılır) ---
	{"ad": "16_alcak_gecit", "zorluk": 1, "uzunluk": 900, "ogeler": [
		["zemin", 0, 900], ["tavan", 300, 620], ["altin_dizi", 330, 262, 8, 36]]},
	{"ad": "17_piston", "zorluk": 1, "uzunluk": 760, "ogeler": [
		["zemin", 0, 760], ["piston", 360, 24, 24, 0.0], ["altin_kavis", 372, 190, 5, 110]]},
	{"ad": "18_alcak_diken", "zorluk": 2, "uzunluk": 1000, "ogeler": [
		["zemin", 0, 1000], ["tavan", 300, 660], ["diken", 470, 24],
		["altin_dizi", 330, 262, 3, 36], ["altin_dizi", 560, 262, 3, 30]]},
	{"ad": "19_iki_piston", "zorluk": 2, "uzunluk": 1000, "ogeler": [
		["zemin", 0, 1000], ["piston", 300, 24, 24, 0.0], ["piston", 640, 24, 24, 0.5],
		["altin_kavis", 312, 190, 3, 90], ["altin_kavis", 652, 190, 3, 90]]},
	{"ad": "20_hareketli_kopru", "zorluk": 2, "uzunluk": 1000, "ogeler": [
		["zemin", 0, 300], ["zemin", 460, 1000], ["hareketli", 330, 232, 64, 30, 0, 2.0],
		["altin_dizi", 340, 214, 3, 20]]},
	{"ad": "21_riskli_rota", "zorluk": 2, "uzunluk": 900, "ogeler": [
		["zemin", 0, 900], ["blok", 380, 28, 48],
		["altin_kavis", 394, 120, 5, 90]]},
	{"ad": "22_basamak_diken", "zorluk": 2, "uzunluk": 1000, "ogeler": [
		["zemin", 0, 300], ["zemin", 300, 620, 240], ["zemin", 620, 1000], ["diken", 450, 30, 240],
		["altin_kavis", 465, 150, 3, 90]]},
	{"ad": "23_cift_cukur", "zorluk": 3, "uzunluk": 1100, "ogeler": [
		["zemin", 0, 300], ["zemin", 420, 620], ["zemin", 760, 1100],
		["altin_kavis", 360, 190, 3, 90], ["altin_kavis", 690, 190, 3, 100]]},
	{"ad": "24_piston_cukur", "zorluk": 3, "uzunluk": 1200, "ogeler": [
		["zemin", 0, 600], ["zemin", 780, 1200], ["piston", 320, 24, 24, 0.25],
		["altin_kavis", 690, 180, 5, 150]]},
	{"ad": "25_uzun_gecit", "zorluk": 3, "uzunluk": 1300, "ogeler": [
		["zemin", 0, 1300], ["tavan", 280, 900], ["diken", 420, 24], ["diken", 700, 24],
		["altin_dizi", 520, 262, 4, 30], ["altin_dizi", 780, 262, 3, 30]]},
	{"ad": "26_merdiven_blok", "zorluk": 3, "uzunluk": 1200, "ogeler": [
		["zemin", 0, 300], ["zemin", 300, 600, 240], ["zemin", 600, 1200], ["blok", 820, 30, 48],
		["altin_dizi", 340, 210, 5, 40], ["altin_kavis", 835, 170, 3, 90]]},
	# --- v0.3 ---
	{"ad": "27_zincir_kiris", "zorluk": 2, "uzunluk": 1100, "ogeler": [
		["zemin", 0, 280], ["zemin", 440, 620], ["zemin", 780, 1100],
		["hareketli", 300, 232, 64, 40, 0, 2.0], ["hareketli", 640, 232, 64, -40, 0, 2.0],
		["altin_dizi", 316, 212, 3, 16], ["altin_dizi", 656, 212, 3, 16]]},
	{"ad": "28_tavan_piston", "zorluk": 2, "uzunluk": 1100, "ogeler": [
		["zemin", 0, 1100], ["tavan", 260, 600], ["piston", 760, 24, 24, 0.3],
		["altin_dizi", 290, 262, 7, 40], ["altin_kavis", 772, 190, 5, 110]]},
	{"ad": "29_nefes_merdiven", "zorluk": 0, "uzunluk": 1000, "ogeler": [
		["zemin", 0, 1000], ["platform", 280, 400, 244], ["platform", 440, 560, 208], ["platform", 600, 720, 172],
		["altin_dizi", 300, 230, 3, 36], ["altin_dizi", 460, 194, 3, 36], ["altin_dizi", 620, 158, 3, 36]]},
	{"ad": "30_nefes_yildiz", "zorluk": 0, "uzunluk": 900, "ogeler": [
		["zemin", 0, 900], ["altin_kavis", 330, 200, 7, 220], ["altin_dizi", 290, 250, 3, 40],
		["altin_dizi", 610, 250, 3, 40]]},
	{"ad": "31_blok_cukur", "zorluk": 3, "uzunluk": 1100, "ogeler": [
		["zemin", 0, 620], ["zemin", 800, 1100], ["blok", 360, 28, 48],
		["altin_kavis", 374, 176, 3, 100], ["altin_kavis", 710, 190, 5, 150]]},
	{"ad": "32_uclu_diken", "zorluk": 2, "uzunluk": 1100, "ogeler": [
		["zemin", 0, 1100], ["diken", 280, 24], ["diken", 520, 24], ["diken", 760, 24],
		["altin_kavis", 292, 196, 3, 80], ["altin_kavis", 532, 196, 3, 80], ["altin_kavis", 772, 196, 3, 80]]},
	{"ad": "33_asansor_cukur", "zorluk": 3, "uzunluk": 1000, "ogeler": [
		["zemin", 0, 300], ["zemin", 500, 1000], ["hareketli", 368, 250, 64, 0, -40, 2.4],
		["altin_kavis", 400, 180, 5, 160]]},
	{"ad": "34_tavan_cukur", "zorluk": 3, "uzunluk": 1100, "ogeler": [
		["zemin", 0, 640], ["zemin", 760, 1100], ["tavan", 260, 520],
		["altin_dizi", 290, 262, 6, 40], ["altin_kavis", 700, 226, 3, 70]]},
	{"ad": "35_cift_piston_cukur", "zorluk": 3, "uzunluk": 1100, "ogeler": [
		["zemin", 0, 710], ["zemin", 850, 1100], ["piston", 160, 24, 24, 0.0], ["piston", 420, 24, 24, 0.5],
		["altin_kavis", 172, 190, 3, 80], ["altin_kavis", 432, 190, 3, 80], ["altin_kavis", 780, 196, 3, 110]]},
	{"ad": "36_nefes_kopru", "zorluk": 0, "uzunluk": 1000, "ogeler": [
		["zemin", 0, 1000], ["platform", 300, 700, 236], ["hareketli", 780, 230, 64, 0, -30, 2.6],
		["altin_dizi", 320, 222, 10, 38]]},
	# v0.4: çürük iskele (basınca ISKELE_COKME sn sonra çöker)
	{"ad": "37_curuk_iskele", "zorluk": 1, "uzunluk": 900, "ogeler": [
		["zemin", 0, 320], ["iskele", 320, 470], ["zemin", 470, 900],
		["altin_kavis", 395, 200, 5, 120]]},
	{"ad": "38_iskele_zinciri", "zorluk": 2, "uzunluk": 1000, "ogeler": [
		["zemin", 0, 280], ["iskele", 280, 430], ["iskele", 430, 580], ["zemin", 580, 1000],
		["altin_kavis", 505, 196, 5, 130]]},
	{"ad": "39_iskele_diken", "zorluk": 2, "uzunluk": 1000, "ogeler": [
		["zemin", 0, 340], ["iskele", 340, 500], ["zemin", 500, 1000], ["diken", 760, 24],
		["altin_kavis", 420, 204, 3, 70], ["altin_kavis", 772, 200, 3, 60]]},
	{"ad": "40_uzun_iskele", "zorluk": 3, "uzunluk": 1100, "ogeler": [
		["zemin", 0, 300], ["iskele", 300, 450], ["iskele", 450, 600], ["iskele", 600, 750],
		["zemin", 750, 1100], ["altin_dizi", 450, 214, 4, 50]]},
	# v0.5: rüzgâr (yalnız havadayken yatay hıza eklenir; eksi = karşıdan)
	{"ad": "41_karsi_ruzgar", "zorluk": 2, "uzunluk": 1000, "ogeler": [
		["ruzgar", 160, 560, -80], ["zemin", 0, 320], ["zemin", 450, 1000],
		["altin_kavis", 385, 196, 5, 110]]},
	{"ad": "42_arka_ruzgar", "zorluk": 2, "uzunluk": 1100, "ogeler": [
		["ruzgar", 200, 760, 90], ["zemin", 0, 320], ["zemin", 430, 1100],
		["diken", 720, 24], ["altin_dizi", 480, 230, 5, 34]]},
	{"ad": "43_firtina", "zorluk": 3, "uzunluk": 1300, "ogeler": [
		["ruzgar", 120, 520, -90], ["zemin", 0, 300], ["zemin", 460, 760],
		["ruzgar", 700, 1140, 100], ["zemin", 900, 1300], ["diken", 1080, 36],
		["altin_kavis", 380, 190, 5, 120], ["altin_kavis", 830, 190, 5, 100]]},
]


func _initialize() -> void:
	var yollar: Array[String] = []
	var zorluklar := {}
	for tanim in PARCALAR:
		var yol := "res://scenes/parcalar/%s.tscn" % tanim["ad"]
		_kaydet(_parca(tanim), yol)
		yollar.append(yol)
		zorluklar[yol] = tanim["zorluk"]
	_liste_yaz(yollar, zorluklar)
	_kaydet(_oyuncu(), "res://scenes/oyuncu.tscn")
	_kaydet(_oyun(), "res://scenes/oyun.tscn")
	_kaydet(_menu(), "res://scenes/menu.tscn")
	print("Sahneler üretildi: %d parça" % yollar.size())
	quit(0)


# ---------------------------------------------------------------- parçalar
func _parca(t: Dictionary) -> Node2D:
	var kok := Node2D.new()
	kok.name = "Parca"
	kok.set_script(_betik("res://scripts/parca.gd"))
	kok.set("zorluk", t["zorluk"])
	kok.set("uzunluk", float(t["uzunluk"]))
	var giris := Marker2D.new()
	giris.name = "Giris"
	giris.position = Vector2(0, ZY)
	kok.add_child(giris)
	var cikis := Marker2D.new()
	cikis.name = "Cikis"
	cikis.position = Vector2(t["uzunluk"], ZY)
	kok.add_child(cikis)
	var sayac := {}
	for o in t["ogeler"]:
		match o[0]:
			"zemin":
				var ust: float = o[3] if o.size() > 3 else ZY
				_ekle(kok, _zemin(o[1], o[2], ust, false), "Zemin", sayac)
			"platform":
				_ekle(kok, _zemin(o[1], o[2], o[3], true), "Platform", sayac)
			"ruzgar":
				var rz := Node2D.new()
				rz.set_script(_betik("res://scripts/ruzgar.gd"))
				rz.position = Vector2(o[1], ZY)
				rz.set("genislik", float(o[2] - o[1]))
				rz.set("guc", float(o[3]))
				_ekle(kok, rz, "Ruzgar", sayac)
			"iskele":
				var isk := StaticBody2D.new()
				isk.set_script(_betik("res://scripts/coken.gd"))
				isk.position = Vector2(o[1], ZY)
				isk.set("genislik", float(o[2] - o[1]))
				isk.set("yukseklik", 10.0)
				_ekle(kok, isk, "Iskele", sayac)
			"hareketli":
				var h := AnimatableBody2D.new()
				h.set_script(_betik("res://scripts/hareketli.gd"))
				h.position = Vector2(o[1], o[2])
				h.set("genislik", float(o[3]))
				h.set("sapma", Vector2(o[4], o[5]))
				h.set("periyot", float(o[6]))
				_ekle(kok, h, "Hareketli", sayac)
			"diken":
				var taban: float = o[3] if o.size() > 3 else ZY
				var dk := _tehlike(0, o[1], o[2], 12.0)
				dk.position.y = taban
				_ekle(kok, dk, "Diken", sayac)
			"blok":
				_ekle(kok, _tehlike(1, o[1], o[2], o[3]), "Blok", sayac)
			"tavan":
				var alt: float = o[3] if o.size() > 3 else TAVAN_ALT
				var tv := _tehlike(2, o[1], o[2] - o[1], 20.0)
				tv.position.y = alt
				_ekle(kok, tv, "Tavan", sayac)
			"piston":
				var ps := _tehlike(3, o[1], o[2], o[3])
				ps.set("faz", float(o[4]))
				_ekle(kok, ps, "Piston", sayac)
			"altin":
				_ekle(kok, _altin(o[1], o[2]), "Altin", sayac)
			"altin_dizi":
				for i in o[3]:
					_ekle(kok, _altin(o[1] + i * o[4], o[2]), "Altin", sayac)
			"altin_kavis":
				var n: int = o[3]
				for i in n:
					var u := 0.0 if n == 1 else float(i) / (n - 1) * 2.0 - 1.0
					_ekle(kok, _altin(o[1] + u * o[4] / 2.0, o[2] + 40.0 * u * u), "Altin", sayac)
	return kok


## Betiği yükler; derlenmiyorsa (ör. yeni class_name henüz içe aktarılmadıysa) üretimi durdurur.
## Aksi hâlde sahne betiksiz kaydedilir ve hata ancak testlerde "Parca değil" olarak görünür.
func _betik(yol: String) -> Script:
	var s: Script = load(yol)
	if s == null or not s.can_instantiate():
		push_error("Betik derlenmiyor: %s — önce 'godot --headless --import' çalıştır, sonra tekrar dene." % yol)
		quit(1)
	return s


func _ekle(kok: Node, n: Node, ad: String, sayac: Dictionary) -> void:
	sayac[ad] = sayac.get(ad, 0) + 1
	n.name = "%s%d" % [ad, sayac[ad]]
	kok.add_child(n)


func _zemin(x0: float, x1: float, ust: float, tek_yonlu: bool) -> Node2D:
	var z := StaticBody2D.new()
	z.set_script(_betik("res://scripts/zemin.gd"))
	z.position = Vector2(x0, ust)
	z.set("genislik", x1 - x0)
	z.set("yukseklik", 6.0 if tek_yonlu else 400.0 - ust)
	z.set("tek_yonlu", tek_yonlu)
	return z


func _tehlike(tur: int, x: float, w: float, h: float) -> Node2D:
	var t := Area2D.new()
	t.set_script(_betik("res://scripts/tehlike.gd"))
	t.position = Vector2(x, ZY)
	t.set("tur", tur)
	t.set("genislik", w)
	t.set("yukseklik", h)
	return t


func _altin(x: float, y: float) -> Node2D:
	var a := Area2D.new()
	a.set_script(_betik("res://scripts/altin.gd"))
	a.position = Vector2(x, y)
	return a


func _liste_yaz(yollar: Array[String], zorluklar: Dictionary) -> void:
	var s := "class_name ParcaListesi\nextends RefCounted\n"
	s += "## OTOMATİK ÜRETİLDİ: tools/sahne_uret.gd — elle düzenleme.\n\n"
	s += "const DUZ := \"%s\"\n\n" % yollar[0]
	s += "const YOLLAR: Array[String] = [\n"
	for y in yollar:
		s += "\t\"%s\",\n" % y
	s += "]\n\nconst ZORLUK := {\n"
	for y in yollar:
		s += "\t\"%s\": %d,\n" % [y, zorluklar[y]]
	s += "}\n"
	var f := FileAccess.open("res://scripts/parca_listesi.gd", FileAccess.WRITE)
	f.store_string(s)
	f.close()


# ---------------------------------------------------------------- oyuncu
func _oyuncu() -> Node:
	var o := CharacterBody2D.new()
	o.name = "Oyuncu"
	o.set_script(_betik("res://scripts/oyuncu.gd"))
	var s := CollisionShape2D.new()
	s.name = "Sekil"
	var k := CapsuleShape2D.new()
	k.radius = 7.0
	k.height = 22.0
	s.shape = k
	s.position = Vector2(0, -11)
	o.add_child(s)
	return o


# ---------------------------------------------------------------- oyun
func _paralaks(ad: String, doku: String, olcek: float, y: float, tekrar: float, oto := 0.0) -> Parallax2D:
	var p := Parallax2D.new()
	p.name = ad
	p.scroll_scale = Vector2(olcek, 0.0)
	p.repeat_size = Vector2(tekrar, 0)
	p.repeat_times = 3
	p.autoscroll = Vector2(oto, 0)
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sp := Sprite2D.new()
	sp.name = "Resim"
	sp.texture = load(doku)
	sp.centered = false
	sp.position = Vector2(0, y)
	p.add_child(sp)
	return p


## Düz renkli dünya: gökyüzü (oyun.gd renklendirir), az yıldız, iki basamaklı siluet katmanı.
func _arka_plan(kok: Node, oto: bool) -> void:
	var gk := CanvasLayer.new()
	gk.name = "Gokyuzu"
	gk.layer = -20
	kok.add_child(gk)
	var gok := TextureRect.new()
	gok.name = "Gok"
	gok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gok.stretch_mode = TextureRect.STRETCH_SCALE
	gok.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gk.add_child(gok)
	var k := 1.0 if oto else 0.0
	kok.add_child(_paralaks("Yildizlar", "res://assets/sprites/yildizlar.png", 0.03, 0, 320, -3.0 * k))
	kok.add_child(_paralaks("SehirUzak", "res://assets/sprites/sehir_uzak.png", 0.2, 150, 640, -12.0 * k))
	kok.add_child(_paralaks("SehirYakin", "res://assets/sprites/sehir_yakin.png", 0.45, 170, 640, -30.0 * k))


func _oyun() -> Node:
	var kok := Node2D.new()
	kok.name = "Oyun"
	kok.set_script(_betik("res://scripts/oyun.gd"))
	kok.process_mode = Node.PROCESS_MODE_ALWAYS
	kok.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_arka_plan(kok, false)
	for ad in ["Yildizlar", "SehirUzak", "SehirYakin"]:
		kok.get_node(ad).process_mode = Node.PROCESS_MODE_PAUSABLE

	var dunya := Node2D.new()
	dunya.name = "Dunya"
	dunya.process_mode = Node.PROCESS_MODE_PAUSABLE
	kok.add_child(dunya)

	var oyuncu: Node = (load("res://scenes/oyuncu.tscn") as PackedScene).instantiate()
	oyuncu.process_mode = Node.PROCESS_MODE_PAUSABLE
	kok.add_child(oyuncu)

	var efekt := Node2D.new()
	efekt.name = "Efektler"
	kok.add_child(efekt)

	var kamera := Camera2D.new()
	kamera.name = "Kamera"
	kok.add_child(kamera)

	var yg := CanvasLayer.new()
	yg.name = "Yagis"
	yg.layer = 1
	kok.add_child(yg)
	var damla := CPUParticles2D.new()
	damla.name = "Damlalar"
	damla.emitting = false
	damla.amount = 70
	damla.lifetime = 0.7
	damla.position = Vector2(360, -10)
	damla.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	damla.emission_rect_extents = Vector2(380, 4)
	damla.direction = Vector2(-0.35, 1)
	damla.spread = 3.0
	damla.initial_velocity_min = 420.0
	damla.initial_velocity_max = 520.0
	damla.gravity = Vector2.ZERO
	# İnce, eğik düz çizgi (damla yönü boyunca hizalı; renk geçişi yok)
	var dt := GradientTexture2D.new()
	var dg := Gradient.new()
	dg.colors = PackedColorArray([Color.WHITE, Color.WHITE])
	dt.gradient = dg
	dt.width = 1
	dt.height = 8
	damla.texture = dt
	damla.particle_flag_align_y = true
	damla.scale_amount_min = 1.0
	damla.scale_amount_max = 1.3
	damla.color = Color(Tema.KAGIT, 0.5)
	yg.add_child(damla)

	var ui := CanvasLayer.new()
	ui.name = "Arayuz"
	ui.layer = 10
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	kok.add_child(ui)

	# --- HUD: sol üst mesafe + altın, sağ üst en iyi + duraklat ---
	var ust := HBoxContainer.new()
	ust.name = "Ust"
	ust.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	ust.offset_left = 14
	ust.offset_right = -12
	ust.offset_top = 8
	ust.offset_bottom = 46
	ust.add_theme_constant_override("separation", 10)
	ust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ust)
	var mesafe := _etiket("Mesafe", "0 m", 26, Tema.KAGIT, true)
	mesafe.custom_minimum_size = Vector2(0, 34)
	ust.add_child(mesafe)
	var ikon := TextureRect.new()
	ikon.name = "AltinIkon"
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/sprites/altin.png")
	at.region = Rect2(0, 0, 12, 12)
	ikon.texture = at
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ikon.custom_minimum_size = Vector2(14, 34)
	ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ust.add_child(ikon)
	ust.add_child(_etiket("AltinSayisi", "0", 16, Tema.CAM, true))
	var rze := _etiket("RuzgarEtiketi", "", 8, Tema.CAM, true)
	rze.custom_minimum_size = Vector2(0, 34)
	rze.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rze.visible = false
	ust.add_child(rze)
	var bosluk := Control.new()
	bosluk.name = "Bosluk"
	bosluk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bosluk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ust.add_child(bosluk)
	var rk := _etiket("Rekor", "Rekor: 0 m", 8, Tema.KAGIT)
	rk.custom_minimum_size = Vector2(0, 34)
	rk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rk.modulate.a = 0.7
	ust.add_child(rk)
	var dd := _dugme("DuraklatDugme", "II", Vector2(34, 34), "Kucuk")
	dd.add_theme_font_size_override("font_size", 12)
	ust.add_child(dd)

	# Tek satır ipucu (ilk koşuda oyun.gd adım adım değiştirir)
	var ipucu := _etiket("Ipucu", "Zıpla: Boşluk ya da dokun", 9, Tema.KAGIT)
	ipucu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ipucu.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	ipucu.offset_left = -280
	ipucu.offset_right = 280
	ipucu.offset_top = 56
	ipucu.offset_bottom = 76
	ui.add_child(ipucu)

	var gb := _etiket("GorevBildirimi", "", 9, Tema.PEMBE, true)
	gb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gb.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	gb.offset_left = -300
	gb.offset_right = 300
	gb.offset_top = 40
	gb.offset_bottom = 58
	ui.add_child(gb)

	var te := _etiket("TekrarEtiketi", "Ölüm tekrarı  •  geçmek için dokun", 9, Tema.KAGIT)
	te.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	te.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	te.offset_left = -300
	te.offset_right = 300
	te.offset_top = -40
	te.offset_bottom = -16
	ui.add_child(te)

	# --- Duraklat kartı: Devam / Baştan / Ayarlar / Menü (+ açılır ses ve dil) ---
	var perde_d := ColorRect.new()
	perde_d.name = "DuraklatPerde"
	perde_d.color = Color(Tema.MUREKKEP, 0.6)
	perde_d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	perde_d.mouse_filter = Control.MOUSE_FILTER_STOP
	perde_d.unique_name_in_owner = true
	perde_d.visible = false
	ui.add_child(perde_d)
	var dp := _kart("DuraklatPaneli")
	dp.custom_minimum_size = Vector2(250, 0)
	ui.add_child(dp)
	var dk: VBoxContainer = dp.get_child(0)
	dk.add_child(_etiket("DuraklatEtiket", "DURAKLATILDI", 8, Tema.MUREKKEP, false, true))
	dk.add_child(_dugme("DevamDugme", "Devam", Vector2(0, 38), "Birincil"))
	var d2 := HBoxContainer.new()
	d2.name = "DurSatir"
	d2.add_theme_constant_override("separation", 6)
	dk.add_child(d2)
	for cift in [["BastanDugme", "Baştan"], ["DurAyarDugme", "Ayarlar"], ["MenuDugme", "Menü"]]:
		var b := _dugme(cift[0], cift[1], Vector2(0, 30), "KartDugme")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d2.add_child(b)
	var ayar := VBoxContainer.new()
	ayar.name = "DurAyarlar"
	ayar.unique_name_in_owner = true
	ayar.add_theme_constant_override("separation", 4)
	ayar.visible = false
	dk.add_child(ayar)
	for cift in [["DurMuzik", "Müzik"], ["DurEfekt", "Efektler"]]:
		var satir := HBoxContainer.new()
		var l := _etiket(cift[0] + "Etiket", cift[1], 11, Tema.MUREKKEP, false, true)
		l.custom_minimum_size = Vector2(64, 0)
		satir.add_child(l)
		satir.add_child(_kaydirici(cift[0], 150))
		ayar.add_child(satir)
	ayar.add_child(_dugme("DurDilDugme", "Dil: Türkçe", Vector2(0, 28), "KartDugme"))

	# --- Oyun sonu kartı: skor, en iyi, tek dokunuşla tekrar ---
	var sp := _kart("SonPaneli")
	sp.custom_minimum_size = Vector2(380, 0)
	ui.add_child(sp)
	var sk: VBoxContainer = sp.get_child(0)
	sk.add_theme_constant_override("separation", 3)
	sk.add_child(_etiket("SonBaslik", "KOŞU BİTTİ", 8, Tema.MUREKKEP, false, true))
	sk.add_child(_etiket("SonSkor", "Mesafe: 0 m", 30, Tema.MUREKKEP, true, true))
	var harita := Control.new()
	harita.name = "SonHarita"
	harita.unique_name_in_owner = true
	harita.set_script(_betik("res://scripts/mini_harita.gd"))
	harita.custom_minimum_size = Vector2(340, 26)
	harita.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sk.add_child(harita)
	sk.add_child(_etiket("SonRekor", "Rekor: 0 m", 9, Tema.PEMBE, true, true))
	sk.add_child(_etiket("SonAltin", "Altın: 0", 8, Tema.MUREKKEP, false, true))
	# v1.7: ritim koşusunda vuruş sapması histogramı (oyun.gd yalnız ritimde gösterir)
	var sapma := Control.new()
	sapma.name = "SonSapma"
	sapma.unique_name_in_owner = true
	sapma.set_script(_betik("res://scripts/sapma_grafigi.gd"))
	sapma.custom_minimum_size = Vector2(340, SapmaGrafigi.BOY)
	sapma.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sapma.visible = false
	sk.add_child(sapma)
	var sg := _etiket("SonGorevler", "", 8, Tema.MUREKKEP, false, true)
	sg.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sk.add_child(sg)
	var dugmeler := HBoxContainer.new()
	dugmeler.name = "Dugmeler"
	dugmeler.alignment = BoxContainer.ALIGNMENT_CENTER
	dugmeler.add_theme_constant_override("separation", 8)
	sk.add_child(dugmeler)
	dugmeler.add_child(_dugme("TekrarDugme", "Tekrar", Vector2(150, 36), "Birincil"))
	var pd := _dugme("PaylasDugme", "Paylaş", Vector2(110, 36), "KartDugme")
	pd.visible = false
	dugmeler.add_child(pd)
	var gcd := _dugme("GecikmeDugme", "Gecikme", Vector2(110, 36), "KartDugme")
	gcd.visible = false
	dugmeler.add_child(gcd)
	dugmeler.add_child(_dugme("SonMenuDugme", "Menü", Vector2(150, 36), "KartDugme"))
	sk.add_child(_etiket("SonIpucu", "Tekrar için dokun ya da Boşluk", 8, Tema.MUREKKEP, false, true))
	for ad in ["SonBaslik", "SonSkor", "SonRekor", "SonAltin", "SonIpucu"]:
		sk.get_node(ad).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sk.get_node("SonIpucu").modulate.a = 0.6

	var gc := CanvasLayer.new()
	gc.name = "Gecis"
	gc.layer = 100
	kok.add_child(gc)
	var perde := ColorRect.new()
	perde.name = "Perde"
	perde.color = Color(Tema.MUREKKEP, 0.0)
	perde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	perde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gc.add_child(perde)
	return kok


## Etiket. Yazı tipi temadaki varyasyondan gelir: kalin -> Bold, boyut <= 9 -> mono etiket
## (BÜYÜK HARF ve harf aralığı oyun kodunda). kart: kâğıt kart üstünde (mürekkep yazı).
func _etiket(ad: String, metin: String, boyut: int, renk: Variant = null, kalin := false, kart := false) -> Label:
	var l := Label.new()
	l.name = ad
	l.text = metin
	l.unique_name_in_owner = true
	var mono := boyut <= 9 and not kalin
	if kalin:
		l.theme_type_variation = &"KartBaslik" if kart else &"Baslik"
	elif mono:
		l.theme_type_variation = &"KartEtiket" if kart else &"Etiket"
	else:
		l.theme_type_variation = &"KartYazi" if kart else &"Govde"
	l.add_theme_font_size_override("font_size", boyut)
	if renk != null:
		var r: Color = renk
		if kart and mono and r == Tema.MUREKKEP:
			r = Color(Tema.MUREKKEP, 0.65)
		l.add_theme_color_override("font_color", r)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## tur: "" ikincil (şeffaf + kâğıt çizgi), "Birincil" (mor dolgu), "KartDugme" (kâğıt üstünde), "Kucuk"
func _dugme(ad: String, metin: String, boyut: Vector2, tur := "") -> Button:
	var b := Button.new()
	b.name = ad
	b.text = metin
	b.unique_name_in_owner = true
	b.custom_minimum_size = boyut
	if tur != "":
		b.theme_type_variation = StringName(tur)
	return b


func _kaydirici(ad: String, genislik: float) -> HSlider:
	var k := HSlider.new()
	k.name = ad
	k.unique_name_in_owner = true
	k.min_value = 0
	k.max_value = 100
	k.step = 5
	k.custom_minimum_size = Vector2(genislik, 24)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return k


## Kâğıt kart (video kartları): tema "KagitKart" PanelContainer + dikey kutu.
func _kart(ad: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = ad
	p.unique_name_in_owner = true
	p.theme_type_variation = &"KagitKart"
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.custom_minimum_size = Vector2(260, 0)
	var v := VBoxContainer.new()
	v.name = "Kutu"
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	return p


func _ortala(kutu: Node) -> void:
	for c in kutu.get_children():
		if c is Label:
			c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _anahtar(ad: String, metin: String) -> CheckButton:
	var cb := CheckButton.new()
	cb.name = ad
	cb.unique_name_in_owner = true
	cb.text = metin
	for r in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		cb.add_theme_color_override(r, Tema.MUREKKEP)
	cb.add_theme_font_size_override("font_size", 11)
	return cb


# ---------------------------------------------------------------- menü
func _menu() -> Node:
	var kok := Control.new()
	kok.name = "Menu"
	kok.set_script(_betik("res://scripts/menu.gd"))
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Boş yere dokunmak da oyunu başlatsın: kök dokunuşu yutmasın.
	kok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var sahne := Node2D.new()
	sahne.name = "Sahne"
	kok.add_child(sahne)
	_arka_plan(sahne, true)
	var cati := ColorRect.new()
	cati.name = "CatiGovde"
	cati.color = Tema.MUREKKEP
	cati.position = Vector2(0, 296)
	cati.size = Vector2(640, 64)
	cati.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sahne.add_child(cati)
	var cizgi := ColorRect.new()
	cizgi.name = "Cati"
	cizgi.color = Tema.KAGIT
	cizgi.position = Vector2(0, 296)
	cizgi.size = Vector2(640, 2)
	cizgi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sahne.add_child(cizgi)
	var onizleme := AnimatedSprite2D.new()
	onizleme.name = "Onizleme"
	onizleme.unique_name_in_owner = true
	onizleme.centered = false
	onizleme.offset = Vector2(-10, -25)
	onizleme.scale = Vector2(2, 2)
	onizleme.position = Vector2(560, 298)
	sahne.add_child(onizleme)

	# --- Ana panel: ortada başlık, büyük OYNA, tek satır nasıl oynanır, ikincil düğmeler ---
	var ana := VBoxContainer.new()
	ana.name = "AnaPanel"
	ana.unique_name_in_owner = true
	ana.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ana.offset_top = 20
	ana.offset_bottom = -70
	ana.alignment = BoxContainer.ALIGNMENT_CENTER
	ana.add_theme_constant_override("separation", 6)
	ana.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.add_child(ana)
	var slogan := _etiket("Slogan", "TEK TUŞ · TAM RİTİM", 8, Tema.MOR)
	slogan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ana.add_child(slogan)
	var baslik := _etiket("Baslik", "Tek Tuş Koşu", 42, Tema.KAGIT, true)
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ana.add_child(baslik)
	var bosluk1 := Control.new()
	bosluk1.custom_minimum_size = Vector2(0, 6)
	bosluk1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ana.add_child(bosluk1)
	var oyna := _dugme("BaslaDugme", "Oyna", Vector2(200, 46), "Birincil")
	oyna.add_theme_font_size_override("font_size", 22)
	oyna.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ana.add_child(oyna)
	var nasil := _etiket("Nasil", "Boşluk ya da dokun: zıpla · basılı tut: daha yüksek · havada bir kez daha", 10, Tema.KAGIT)
	nasil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nasil.modulate.a = 0.75
	ana.add_child(nasil)
	var bosluk2 := Control.new()
	bosluk2.custom_minimum_size = Vector2(0, 4)
	bosluk2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ana.add_child(bosluk2)
	for cift in [["RitimDugme", "Ritim", "GunlukDugme", "Günlük koşu"], ["KarakterDugme", "Karakter", "BasarimDugme", "Başarımlar", "AyarlarDugme", "Ayarlar"]]:
		var satir := HBoxContainer.new()
		satir.name = cift[0] + "Satir"
		satir.alignment = BoxContainer.ALIGNMENT_CENTER
		satir.add_theme_constant_override("separation", 6)
		satir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in range(0, cift.size(), 2):
			var b := _dugme(cift[i], cift[i + 1], Vector2(112, 28))
			b.add_theme_font_size_override("font_size", 11)
			satir.add_child(b)
		ana.add_child(satir)

	# Alt sol: rekor + altın, alt sağ: görevler (küçük, mono)
	var alt := HBoxContainer.new()
	alt.name = "Alt"
	alt.unique_name_in_owner = true
	alt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	alt.offset_left = 16
	alt.offset_right = -16
	alt.offset_top = -66
	alt.offset_bottom = -10
	alt.add_theme_constant_override("separation", 20)
	alt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.add_child(alt)
	var sol := VBoxContainer.new()
	sol.name = "Sol"
	sol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sol.alignment = BoxContainer.ALIGNMENT_END
	sol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alt.add_child(sol)
	sol.add_child(_etiket("RekorEtiketi", "Rekor: 0 m", 9, Tema.PEMBE, true))
	sol.add_child(_etiket("AltinEtiketi", "Altın: 0", 8, Tema.KAGIT))
	var gorev := VBoxContainer.new()
	gorev.name = "GorevPaneli"
	gorev.unique_name_in_owner = true
	gorev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gorev.alignment = BoxContainer.ALIGNMENT_END
	gorev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alt.add_child(gorev)
	var gl := _etiket("GorevListesi", "GÖREVLER", 8, Tema.KAGIT)
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gl.modulate.a = 0.8
	gl.add_theme_constant_override("line_spacing", -3)
	gorev.add_child(gl)

	# Çıkış (yalnız masaüstü) ve dil düğmesi: köşe
	var cikis := _dugme("CikisDugme", "Çıkış", Vector2(60, 26), "Kucuk")
	cikis.add_theme_font_size_override("font_size", 10)
	cikis.position = Vector2(10, 10)
	kok.add_child(cikis)
	var dil := _dugme("DilDugme", "TR", Vector2(40, 26), "Kucuk")
	dil.add_theme_font_size_override("font_size", 10)
	dil.position = Vector2(590, 10)
	kok.add_child(dil)

	var ip := _etiket("Ipucu", "Başlamak için boş bir yere dokun ya da Boşluk", 8, Tema.KAGIT)
	ip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	ip.offset_left = -300
	ip.offset_right = 300
	ip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	ip.offset_left = -150
	ip.offset_right = 150
	ip.offset_top = 14
	ip.offset_bottom = 28
	ip.modulate.a = 0.6
	kok.add_child(ip)

	# --- Karakter paneli ---
	var kp := _kart("KarakterPaneli")
	kp.custom_minimum_size = Vector2(380, 0)
	kok.add_child(kp)
	var kv: VBoxContainer = kp.get_child(0)
	kv.add_theme_constant_override("separation", 4)
	kv.add_child(_etiket("KarakterBaslik", "Karakter", 20, Tema.MUREKKEP, true, true))
	kv.add_child(_etiket("KarakterAltin", "Altın: 0", 9, Tema.PEMBE, true, true))
	var liste := VBoxContainer.new()
	liste.name = "KostumListesi"
	liste.unique_name_in_owner = true
	liste.add_theme_constant_override("separation", 2)
	kv.add_child(liste)
	kv.add_child(_dugme("KarakterGeri", "Geri", Vector2(160, 32), "KartDugme"))
	_ortala(kv)

	# --- Ayarlar paneli: ses + dil + oynanış anahtarları ---
	var ap := _kart("AyarlarPaneli")
	ap.custom_minimum_size = Vector2(360, 0)
	kok.add_child(ap)
	var av: VBoxContainer = ap.get_child(0)
	av.add_theme_constant_override("separation", 4)
	av.add_child(_etiket("AyarlarBaslik", "Ayarlar", 20, Tema.MUREKKEP, true, true))
	for cift in [["MuzikKaydirici", "Müzik"], ["EfektKaydirici", "Efektler"]]:
		var satir := HBoxContainer.new()
		satir.name = cift[0] + "Satir"
		var l := _etiket(cift[0] + "Etiket", cift[1], 11, Tema.MUREKKEP, false, true)
		l.custom_minimum_size = Vector2(90, 0)
		satir.add_child(l)
		satir.add_child(_kaydirici(cift[0], 220))
		av.add_child(satir)
	var dil_satir := HBoxContainer.new()
	dil_satir.name = "DilSatir"
	var dl := _etiket("DilEtiket", "Dil", 11, Tema.MUREKKEP, false, true)
	dl.custom_minimum_size = Vector2(90, 0)
	dil_satir.add_child(dl)
	dil_satir.add_child(_dugme("AyarDilDugme", "Türkçe", Vector2(120, 26), "KartDugme"))
	av.add_child(dil_satir)
	for cift in [["TamEkranKutu", "Tam ekran"], ["SarsintiKutu", "Ekran sarsıntısı"], ["TitresimKutu", "Titreşim (telefon)"], ["KontrastKutu", "Yüksek kontrast (tehlike çerçevesi)"], ["RahatKutu", "Rahat mod (%80 hız, ayrı rekor)"]]:
		av.add_child(_anahtar(cift[0], cift[1]))
	av.add_child(_dugme("AyarlarGeri", "Geri", Vector2(160, 32), "KartDugme"))
	av.get_node("AyarlarBaslik").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# --- Ritim paneli: şarkı seçimi + ses gecikmesi ---
	var rp := _kart("RitimPaneli")
	rp.custom_minimum_size = Vector2(380, 0)
	kok.add_child(rp)
	var rv: VBoxContainer = rp.get_child(0)
	rv.add_theme_constant_override("separation", 5)
	rv.add_child(_etiket("RitimBaslik", "Ritim koşusu", 20, Tema.MUREKKEP, true, true))
	rv.add_child(_etiket("RitimAciklama", "Engeller müziğin vuruşuna hizalı. Pembe oklu çizgide zıpla.", 10, Tema.MUREKKEP, false, true))
	for i in 3:
		var sd := _dugme("SarkiDugme%d" % i, "Şarkı %d" % (i + 1), Vector2(300, 30), "KartDugme")
		sd.add_theme_font_size_override("font_size", 12)
		rv.add_child(sd)
	var grd := _dugme("GunlukRitimDugme", "Günün ritmi", Vector2(300, 30), "KartDugme")
	grd.add_theme_font_size_override("font_size", 12)
	rv.add_child(grd)
	var gs := HBoxContainer.new()
	gs.name = "GecikmeSatir"
	gs.add_theme_constant_override("separation", 8)
	var gl2 := _etiket("GecikmeEtiket", "Ses gecikmesi", 11, Tema.MUREKKEP, false, true)
	gl2.custom_minimum_size = Vector2(100, 0)
	gs.add_child(gl2)
	var gk := HSlider.new()
	gk.name = "GecikmeKaydirici"
	gk.unique_name_in_owner = true
	gk.min_value = -150
	gk.max_value = 300
	gk.step = 10
	gk.custom_minimum_size = Vector2(150, 24)
	gk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gs.add_child(gk)
	var gd2 := _etiket("GecikmeDeger", "+0 ms", 9, Tema.PEMBE, true, true)
	gd2.custom_minimum_size = Vector2(56, 0)
	gd2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gs.add_child(gd2)
	rv.add_child(gs)
	rv.add_child(_etiket("GecikmeIpucu", "Vuruşları geç duyuyorsan (bluetooth kulaklık) artır.", 10, Tema.MUREKKEP, false, true))
	var ik := _anahtar("IpucuSesiKutu", "Zıplama vuruşundan önce tık sesi")
	ik.add_theme_font_size_override("font_size", 10)
	rv.add_child(ik)
	rv.add_child(_dugme("RitimGeri", "Geri", Vector2(160, 30), "KartDugme"))
	for ad in ["RitimBaslik", "RitimAciklama", "GecikmeIpucu"]:
		rv.get_node(ad).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# --- Başarımlar paneli ---
	var bp := _kart("BasarimPaneli")
	bp.custom_minimum_size = Vector2(430, 0)
	kok.add_child(bp)
	var bv: VBoxContainer = bp.get_child(0)
	bv.add_theme_constant_override("separation", 3)
	var bb := _etiket("BasarimBaslik", "Başarımlar", 20, Tema.MUREKKEP, true, true)
	bb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(bb)
	# v1.7: 16 başarım tek sütunda 360 px'e sığmıyor; iki sütunlu ızgara (menu.gd doldurur).
	var bl := GridContainer.new()
	bl.name = "BasarimListesi"
	bl.unique_name_in_owner = true
	bl.columns = 2
	bl.add_theme_constant_override("v_separation", 1)
	bl.add_theme_constant_override("h_separation", 14)
	bv.add_child(bl)
	bv.add_child(_dugme("BasarimGeri", "Geri", Vector2(160, 30), "KartDugme"))
	_ortala(bv)

	var perde := ColorRect.new()
	perde.name = "Perde"
	perde.unique_name_in_owner = true
	perde.color = Color(Tema.MUREKKEP, 0.0)
	perde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	perde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.add_child(perde)
	return kok


# ---------------------------------------------------------------- kayıt
func _kaydet(kok: Node, yol: String) -> void:
	_sahiplen(kok, kok)
	var ps := PackedScene.new()
	var e := ps.pack(kok)
	if e != OK:
		push_error("Paketlenemedi: %s (%d)" % [yol, e])
		quit(1)
	e = ResourceSaver.save(ps, yol)
	if e != OK:
		push_error("Kaydedilemedi: %s (%d)" % [yol, e])
		quit(1)
	_kimlikleri_sabitle(yol)
	kok.free()


## Godot her kayıtta düğümlere rastgele unique_id verir; her üretimde bütün sahneler değişmiş
## görünmesin diye kimliği dosya adı + düğüm yolundan türet (dosya içinde tekil kalır).
func _kimlikleri_sabitle(yol: String) -> void:
	var f := FileAccess.open(yol, FileAccess.READ)
	var satirlar := f.get_as_text().split("\n")
	f.close()
	var dugum := RegEx.create_from_string('^\\[node name="([^"]*)"(.*) unique_id=(\\d+)\\]$')
	var ebeveyn := RegEx.create_from_string('parent="([^"]*)"')
	var kullanilan := {}
	for i in satirlar.size():
		var m := dugum.search(satirlar[i])
		if m == null:
			continue
		var p := ebeveyn.search(m.get_string(2))
		var dugum_yolu := m.get_string(1) if p == null else p.get_string(1) + "/" + m.get_string(1)
		var k := absi((yol.get_file() + ":" + dugum_yolu).hash()) % 2000000000 + 1
		while kullanilan.has(k):
			k += 1
		kullanilan[k] = true
		satirlar[i] = satirlar[i].replace(" unique_id=" + m.get_string(3) + "]", " unique_id=%d]" % k)
	f = FileAccess.open(yol, FileAccess.WRITE)
	f.store_string("\n".join(satirlar))
	f.close()


func _sahiplen(n: Node, kok: Node) -> void:
	for c in n.get_children():
		c.owner = kok
		if c.scene_file_path.is_empty():
			_sahiplen(c, kok)
