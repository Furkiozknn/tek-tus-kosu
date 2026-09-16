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
	kok.set_script(load("res://scripts/parca.gd"))
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
			"hareketli":
				var h := AnimatableBody2D.new()
				h.set_script(load("res://scripts/hareketli.gd"))
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


func _ekle(kok: Node, n: Node, ad: String, sayac: Dictionary) -> void:
	sayac[ad] = sayac.get(ad, 0) + 1
	n.name = "%s%d" % [ad, sayac[ad]]
	kok.add_child(n)


func _zemin(x0: float, x1: float, ust: float, tek_yonlu: bool) -> Node2D:
	var z := StaticBody2D.new()
	z.set_script(load("res://scripts/zemin.gd"))
	z.position = Vector2(x0, ust)
	z.set("genislik", x1 - x0)
	z.set("yukseklik", 6.0 if tek_yonlu else 400.0 - ust)
	z.set("tek_yonlu", tek_yonlu)
	return z


func _tehlike(tur: int, x: float, w: float, h: float) -> Node2D:
	var t := Area2D.new()
	t.set_script(load("res://scripts/tehlike.gd"))
	t.position = Vector2(x, ZY)
	t.set("tur", tur)
	t.set("genislik", w)
	t.set("yukseklik", h)
	return t


func _altin(x: float, y: float) -> Node2D:
	var a := Area2D.new()
	a.set_script(load("res://scripts/altin.gd"))
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
	o.set_script(load("res://scripts/oyuncu.gd"))
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


## ay_konum: oyunda ay, sağ üstteki rekor yazısının altına iner.
func _arka_plan(kok: Node, oto: bool, ay_konum := Vector2(520, 34)) -> void:
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
	var ay := _paralaks("Ay", "res://assets/sprites/ay.png", 0.0, ay_konum.y, 0)
	ay.get_node("Resim").position.x = ay_konum.x
	ay.repeat_times = 1
	kok.add_child(ay)
	kok.add_child(_paralaks("SehirUzak", "res://assets/sprites/sehir_uzak.png", 0.2, 150, 640, -12.0 * k))
	kok.add_child(_paralaks("SehirYakin", "res://assets/sprites/sehir_yakin.png", 0.45, 170, 640, -30.0 * k))


func _oyun() -> Node:
	var kok := Node2D.new()
	kok.name = "Oyun"
	kok.set_script(load("res://scripts/oyun.gd"))
	kok.process_mode = Node.PROCESS_MODE_ALWAYS
	kok.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_arka_plan(kok, false, Vector2(548, 66))
	for ad in ["Yildizlar", "Ay", "SehirUzak", "SehirYakin"]:
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
	damla.amount = 90
	damla.lifetime = 0.7
	damla.position = Vector2(360, -10)
	damla.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	damla.emission_rect_extents = Vector2(380, 4)
	damla.direction = Vector2(-0.35, 1)
	damla.spread = 3.0
	damla.initial_velocity_min = 420.0
	damla.initial_velocity_max = 520.0
	damla.gravity = Vector2.ZERO
	# İnce, eğik çizgi şeklinde damla (yön boyunca hizalı)
	var dg := Gradient.new()
	dg.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0)])
	var dt := GradientTexture2D.new()
	dt.gradient = dg
	dt.width = 1
	dt.height = 7
	dt.fill_from = Vector2(0, 0)
	dt.fill_to = Vector2(0, 1)
	damla.texture = dt
	damla.particle_flag_align_y = true
	damla.scale_amount_min = 1.0
	damla.scale_amount_max = 1.4
	damla.color = Color(0.78, 0.87, 1.0, 0.7)
	yg.add_child(damla)

	var ui := CanvasLayer.new()
	ui.name = "Arayuz"
	ui.layer = 10
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	kok.add_child(ui)

	var ust := HBoxContainer.new()
	ust.name = "Ust"
	ust.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	ust.offset_left = 12
	ust.offset_right = -12
	ust.offset_top = 8
	ust.offset_bottom = 48
	ust.add_theme_constant_override("separation", 10)
	ust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ust)
	ust.add_child(_etiket("Mesafe", "0 m", 22))
	var ikon := TextureRect.new()
	ikon.name = "AltinIkon"
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/sprites/altin.png")
	at.region = Rect2(0, 0, 12, 12)
	ikon.texture = at
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ikon.custom_minimum_size = Vector2(14, 30)
	ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ust.add_child(ikon)
	ust.add_child(_etiket("AltinSayisi", "0", 22, Color("fee761")))
	var bosluk := Control.new()
	bosluk.name = "Bosluk"
	bosluk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bosluk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ust.add_child(bosluk)
	ust.add_child(_etiket("Rekor", "Rekor: 0 m", 14, Color("c0cbdc")))
	ust.add_child(_dugme("DuraklatDugme", "II", Vector2(44, 40)))

	var ipucu := _etiket("Ipucu", "Zıplamak için dokun / Boşluk\nBasılı tut: daha yüksek • Havada bir kez daha zıpla\nKırmızı tabelanın altında KISA zıpla", 13)
	ipucu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ipucu.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	ipucu.offset_left = -240
	ipucu.offset_right = 240
	ipucu.offset_top = 64
	ipucu.offset_bottom = 124
	ui.add_child(ipucu)

	var gb := _etiket("GorevBildirimi", "", 14, Color("63c74d"))
	gb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gb.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	gb.offset_left = -300
	gb.offset_right = 300
	gb.offset_top = 46
	gb.offset_bottom = 66
	ui.add_child(gb)

	var te := _etiket("TekrarEtiketi", "Ölüm tekrarı  •  geçmek için dokun", 14, Color("ffffff"))
	te.add_theme_constant_override("outline_size", 6)
	te.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	te.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	te.offset_left = -300
	te.offset_right = 300
	te.offset_top = -40
	te.offset_bottom = -16
	ui.add_child(te)

	var dp := _panel("DuraklatPaneli")
	ui.add_child(dp)
	var dk: VBoxContainer = dp.get_child(0)
	dk.add_child(_etiket("DuraklatBaslik", "Duraklatıldı", 28))
	dk.add_child(_dugme("DevamDugme", "Devam", Vector2(200, 44)))
	dk.add_child(_dugme("MenuDugme", "Menüye Dön", Vector2(200, 44)))

	var sp := _panel("SonPaneli")
	sp.custom_minimum_size = Vector2(380, 0)
	ui.add_child(sp)
	var sk: VBoxContainer = sp.get_child(0)
	sk.add_theme_constant_override("separation", 4)
	sk.add_child(_etiket("SonBaslik", "Koşu bitti", 24))
	sk.add_child(_etiket("SonSkor", "Mesafe: 0 m", 20))
	sk.add_child(_etiket("SonRekor", "Rekor: 0 m", 16, Color("fee761")))
	sk.add_child(_etiket("SonAltin", "Altın: 0", 14))
	var sg := _etiket("SonGorevler", "", 11, Color("c0cbdc"))
	sg.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sk.add_child(sg)
	var dugmeler := HBoxContainer.new()
	dugmeler.name = "Dugmeler"
	dugmeler.alignment = BoxContainer.ALIGNMENT_CENTER
	dugmeler.add_theme_constant_override("separation", 10)
	sk.add_child(dugmeler)
	dugmeler.add_child(_dugme("TekrarDugme", "Tekrar", Vector2(150, 42)))
	dugmeler.add_child(_dugme("SonMenuDugme", "Menü", Vector2(150, 42)))
	sk.add_child(_etiket("SonIpucu", "Tekrar için dokun ya da Boşluk", 11, Color("8b9bb4")))
	_ortala(dk)
	for ad in ["SonBaslik", "SonSkor", "SonRekor", "SonAltin", "SonIpucu"]:
		sk.get_node(ad).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var gc := CanvasLayer.new()
	gc.name = "Gecis"
	gc.layer = 100
	kok.add_child(gc)
	var perde := ColorRect.new()
	perde.name = "Perde"
	perde.color = Color(0.094, 0.078, 0.145, 0.0)
	perde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	perde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gc.add_child(perde)
	return kok


func _etiket(ad: String, metin: String, boyut: int, renk := Color.WHITE) -> Label:
	var l := Label.new()
	l.name = ad
	l.text = metin
	l.unique_name_in_owner = true
	l.add_theme_font_size_override("font_size", boyut)
	l.add_theme_color_override("font_color", renk)
	l.add_theme_color_override("font_outline_color", Color("222034"))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _dugme(ad: String, metin: String, boyut: Vector2) -> Button:
	var b := Button.new()
	b.name = ad
	b.text = metin
	b.unique_name_in_owner = true
	b.custom_minimum_size = boyut
	b.add_theme_font_size_override("font_size", 18)
	return b


func _panel(ad: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = ad
	p.unique_name_in_owner = true
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.custom_minimum_size = Vector2(260, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("3f3f74", 0.96)
	sb.border_color = Color("cbdbfc")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(16)
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.name = "Kutu"
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	return p


func _ortala(kutu: Node) -> void:
	for c in kutu.get_children():
		if c is Label:
			c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


# ---------------------------------------------------------------- menü
func _menu() -> Node:
	var kok := Control.new()
	kok.name = "Menu"
	kok.set_script(load("res://scripts/menu.gd"))
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Boş yere dokunmak da oyunu başlatsın: kök dokunuşu yutmasın.
	kok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var sahne := Node2D.new()
	sahne.name = "Sahne"
	kok.add_child(sahne)
	_arka_plan(sahne, true)
	var cati := Sprite2D.new()
	cati.name = "Cati"
	cati.texture = load("res://assets/sprites/zemin.png")
	cati.region_enabled = true
	cati.region_rect = Rect2(0, 0, 16, 16)
	cati.centered = false
	cati.scale = Vector2(40, 1)
	cati.position = Vector2(0, 296)
	sahne.add_child(cati)
	var govde := ColorRect.new()
	govde.name = "CatiGovde"
	govde.color = Color("3e2731")
	govde.position = Vector2(0, 312)
	govde.size = Vector2(640, 48)
	govde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sahne.add_child(govde)
	var onizleme := AnimatedSprite2D.new()
	onizleme.name = "Onizleme"
	onizleme.unique_name_in_owner = true
	onizleme.centered = false
	onizleme.offset = Vector2(-10, -25)
	onizleme.position = Vector2(560, 297)
	onizleme.scale = Vector2(2, 2)
	onizleme.position = Vector2(560, 298)
	sahne.add_child(onizleme)

	var baslik := _etiket("Baslik", "TEK TUŞ KOŞU", 38, Color("2ce8f5"))
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	baslik.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	baslik.offset_left = -300
	baslik.offset_right = 300
	baslik.offset_top = 14
	baslik.offset_bottom = 64
	baslik.add_theme_constant_override("outline_size", 8)
	kok.add_child(baslik)

	# --- Ana panel: solda düğmeler, sağda görevler ---
	var ana := HBoxContainer.new()
	ana.name = "AnaPanel"
	ana.unique_name_in_owner = true
	ana.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ana.offset_left = 28
	ana.offset_right = -28
	ana.offset_top = 72
	ana.offset_bottom = -70
	ana.add_theme_constant_override("separation", 24)
	ana.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.add_child(ana)
	var sol := VBoxContainer.new()
	sol.name = "Sol"
	sol.add_theme_constant_override("separation", 6)
	sol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ana.add_child(sol)
	sol.add_child(_dugme("BaslaDugme", "Başla", Vector2(190, 40)))
	sol.add_child(_dugme("KarakterDugme", "Karakter", Vector2(190, 30)))
	sol.add_child(_dugme("AyarlarDugme", "Ayarlar", Vector2(190, 30)))
	sol.add_child(_dugme("CikisDugme", "Çıkış", Vector2(190, 30)))
	sol.add_child(_etiket("RekorEtiketi", "Rekor: 0 m", 16, Color("fee761")))
	sol.add_child(_etiket("AltinEtiketi", "Altın: 0", 14))
	var gorev := _panel("GorevPaneli")
	gorev.set_anchors_preset(Control.PRESET_TOP_LEFT)
	gorev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gorev.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	gorev.custom_minimum_size = Vector2(0, 0)
	gorev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ana.add_child(gorev)
	var gl := _etiket("GorevListesi", "GÖREVLER", 12, Color("ead4aa"))
	gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gorev.get_child(0).add_child(gl)

	var ip := _etiket("Ipucu", "Başlamak için boş bir yere dokun ya da Boşluk", 12, Color("c0cbdc"))
	ip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	ip.offset_left = -300
	ip.offset_right = 300
	ip.offset_top = -26
	ip.offset_bottom = -6
	kok.add_child(ip)

	# --- Karakter paneli ---
	var kp := _panel("KarakterPaneli")
	kp.custom_minimum_size = Vector2(380, 0)
	kok.add_child(kp)
	var kv: VBoxContainer = kp.get_child(0)
	kv.add_theme_constant_override("separation", 4)
	kv.add_child(_etiket("KarakterBaslik", "Karakter", 22))
	kv.add_child(_etiket("KarakterAltin", "Altın: 0", 14, Color("fee761")))
	var liste := VBoxContainer.new()
	liste.name = "KostumListesi"
	liste.unique_name_in_owner = true
	liste.add_theme_constant_override("separation", 2)
	kv.add_child(liste)
	kv.add_child(_dugme("KarakterGeri", "Geri", Vector2(160, 36)))
	_ortala(kv)

	# --- Ayarlar paneli ---
	var ap := _panel("AyarlarPaneli")
	ap.custom_minimum_size = Vector2(360, 0)
	kok.add_child(ap)
	var av: VBoxContainer = ap.get_child(0)
	av.add_theme_constant_override("separation", 4)
	av.add_child(_etiket("AyarlarBaslik", "Ayarlar", 22))
	for cift in [["MuzikKaydirici", "Müzik"], ["EfektKaydirici", "Efektler"]]:
		var satir := HBoxContainer.new()
		satir.name = cift[0] + "Satir"
		var l := _etiket(cift[0] + "Etiket", cift[1], 14)
		l.custom_minimum_size = Vector2(90, 0)
		satir.add_child(l)
		var k := HSlider.new()
		k.name = cift[0]
		k.unique_name_in_owner = true
		k.min_value = 0
		k.max_value = 100
		k.step = 5
		k.custom_minimum_size = Vector2(220, 28)
		satir.add_child(k)
		av.add_child(satir)
	for cift in [["TamEkranKutu", "Tam ekran"], ["SarsintiKutu", "Ekran sarsıntısı"], ["KontrastKutu", "Yüksek kontrast (tehlike çerçevesi)"], ["RahatKutu", "Rahat mod (%80 hız, ayrı rekor)"]]:
		var cb := CheckButton.new()
		cb.name = cift[0]
		cb.unique_name_in_owner = true
		cb.text = cift[1]
		cb.add_theme_font_size_override("font_size", 14)
		av.add_child(cb)
	av.add_child(_dugme("AyarlarGeri", "Geri", Vector2(160, 36)))
	av.get_node("AyarlarBaslik").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var perde := ColorRect.new()
	perde.name = "Perde"
	perde.unique_name_in_owner = true
	perde.color = Color(0.094, 0.078, 0.145, 0.0)
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
	kok.free()


func _sahiplen(n: Node, kok: Node) -> void:
	for c in n.get_children():
		c.owner = kok
		if c.scene_file_path.is_empty():
			_sahiplen(c, kok)
