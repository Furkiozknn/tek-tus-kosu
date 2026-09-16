extends SceneTree
## Sahne üretici. Parça ve arayüz sahnelerini koddan üretir, böylece .tscn
## dosyaları her zaman geçerli olur. Parça eklemek/değiştirmek için
## PARCALAR listesini düzenle ve çalıştır:
##   godot --headless --path . -s res://tools/sahne_uret.gd

const ZY := 280.0  # Ayarlar.ZEMIN_Y (araç bağımsız çalışsın diye kopya)

## Öğe türleri:
##  ["zemin", x0, x1, (ust_y)]         katı zemin
##  ["platform", x0, x1, y]            tek yönlü platform (12 px kalın)
##  ["diken", x, genislik]              zemin üstünde diken (12 px)
##  ["blok", x, genislik, yukseklik]    zemin üstünde öldüren blok
##  ["altin", x, y]
##  ["altin_dizi", x, y, adet, aralik]
##  ["altin_kavis", orta_x, tepe_y, adet, genislik]
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
			"diken":
				_ekle(kok, _tehlike(0, o[1], o[2], 12.0), "Diken", sayac)
			"blok":
				_ekle(kok, _tehlike(1, o[1], o[2], o[3]), "Blok", sayac)
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
	z.set("yukseklik", 12.0 if tek_yonlu else 400.0 - ust)
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
func _oyun() -> Node:
	var kok := Node2D.new()
	kok.name = "Oyun"
	kok.set_script(load("res://scripts/oyun.gd"))
	kok.process_mode = Node.PROCESS_MODE_ALWAYS

	var arka := CanvasLayer.new()
	arka.name = "Arkaplan"
	arka.layer = -10
	kok.add_child(arka)
	var gok := ColorRect.new()
	gok.name = "Gok"
	gok.color = Color("222034")
	gok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arka.add_child(gok)
	var ufuk := ColorRect.new()
	ufuk.name = "Ufuk"
	ufuk.color = Color("3f3f74")
	ufuk.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ufuk.offset_top = -170
	ufuk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arka.add_child(ufuk)

	var dunya := Node2D.new()
	dunya.name = "Dunya"
	dunya.process_mode = Node.PROCESS_MODE_PAUSABLE
	kok.add_child(dunya)

	var oyuncu: Node = (load("res://scenes/oyuncu.tscn") as PackedScene).instantiate()
	oyuncu.process_mode = Node.PROCESS_MODE_PAUSABLE
	kok.add_child(oyuncu)

	var kamera := Camera2D.new()
	kamera.name = "Kamera"
	kok.add_child(kamera)

	var ui := CanvasLayer.new()
	ui.name = "Arayuz"
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	kok.add_child(ui)

	var ust := HBoxContainer.new()
	ust.name = "Ust"
	ust.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	ust.offset_left = 12
	ust.offset_right = -12
	ust.offset_top = 8
	ust.offset_bottom = 48
	ust.add_theme_constant_override("separation", 16)
	ust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ust)
	ust.add_child(_etiket("Mesafe", "0 m", 22))
	ust.add_child(_etiket("AltinSayisi", "0", 22, Color("fbf236")))
	var bosluk := Control.new()
	bosluk.name = "Bosluk"
	bosluk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bosluk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ust.add_child(bosluk)
	ust.add_child(_etiket("Rekor", "Rekor: 0 m", 14, Color("cbdbfc")))
	ust.add_child(_dugme("DuraklatDugme", "II", Vector2(44, 40)))

	var ipucu := _etiket("Ipucu", "Zıplamak için dokun / Boşluk\nBasılı tut: daha yüksek • Havada bir kez daha zıpla", 14)
	ipucu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ipucu.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	ipucu.offset_left = -220
	ipucu.offset_right = 220
	ipucu.offset_top = 70
	ipucu.offset_bottom = 120
	ui.add_child(ipucu)

	var dp := _panel("DuraklatPaneli")
	ui.add_child(dp)
	var dk: VBoxContainer = dp.get_child(0)
	dk.add_child(_etiket("DuraklatBaslik", "Duraklatıldı", 28))
	dk.add_child(_dugme("DevamDugme", "Devam", Vector2(200, 44)))
	dk.add_child(_dugme("MenuDugme", "Menüye Dön", Vector2(200, 44)))

	var sp := _panel("SonPaneli")
	ui.add_child(sp)
	var sk: VBoxContainer = sp.get_child(0)
	sk.add_child(_etiket("SonBaslik", "Koşu bitti", 28))
	sk.add_child(_etiket("SonSkor", "Mesafe: 0 m", 20))
	sk.add_child(_etiket("SonRekor", "Rekor: 0 m", 16, Color("fbf236")))
	sk.add_child(_etiket("SonAltin", "Altın: 0", 16))
	sk.add_child(_dugme("TekrarDugme", "Tekrar", Vector2(200, 44)))
	sk.add_child(_dugme("SonMenuDugme", "Menü", Vector2(200, 44)))
	sk.add_child(_etiket("SonIpucu", "Tekrar için dokun ya da Boşluk", 12, Color("cbdbfc")))
	_ortala(dk)
	_ortala(sk)
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
	var arka := ColorRect.new()
	arka.name = "Arkaplan"
	arka.color = Color("222034")
	arka.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arka.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.add_child(arka)
	var v := VBoxContainer.new()
	v.name = "Kutu"
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.add_child(v)
	var baslik := _etiket("Baslik", "TEK TUŞ KOŞU", 40, Color("5fcde4"))
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(baslik)
	var r := _etiket("RekorEtiketi", "Rekor: 0 m", 16, Color("fbf236"))
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(r)
	var a := _etiket("AltinEtiketi", "Toplam altın: 0", 14)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(a)
	v.add_child(_dugme("BaslaDugme", "Başla", Vector2(220, 48)))
	v.add_child(_dugme("CikisDugme", "Çıkış", Vector2(220, 40)))
	var ip := _etiket("Ipucu", "Başlamak için dokun ya da Boşluk", 12, Color("9badb7"))
	ip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ip)
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
