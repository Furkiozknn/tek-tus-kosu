extends SceneTree
## itch.io için ekran görüntüleri (1280x720) ve kapak (630x500) üretir.
## Görüntü gerektirir (headless değil). Linux'ta:
##   xvfb-run -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       --fixed-fps 60 --path . -s res://tools/ekran_goruntusu.gd
## Windows'ta aynı komut xvfb-run olmadan çalışır.

const CIKTI := "res://yayin/"


func _initialize() -> void:
	_calistir.call_deferred()


func _calistir() -> void:
	Kayit.yol = "user://ekran_kayit.cfg"
	var d := Kayit.yukle()
	d["rekor"] = 180
	d["toplam_altin"] = 240
	d["acik_kostumler"] = ["klasik", "kizil", "neon"]
	Kayit.kaydet(d)
	await _menu()
	await _oyun_tavan()
	await _oyun_yagis()
	await _oyun_son()
	await _kapak()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.yol))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.yedek_yolu()))
	print("ekran görüntüleri hazır")
	quit()


func _bekle(n: int) -> void:
	for i in n:
		await process_frame


func _kaydet(ad: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(CIKTI + ad))
	print("  ", ad, " ", img.get_size())


func _oyun(sira: Array[String], hiz: float, ileri_m: int, tohum: int) -> Node2D:
	var oyun: Node2D = (load("res://scenes/oyun.tscn") as PackedScene).instantiate()
	oyun.parca_sirasi = sira
	oyun.sabit_hiz = hiz
	oyun.tohum = tohum
	oyun.kayit_yap = true
	root.add_child(oyun)
	await _bekle(2)
	oyun.baslangic_x -= ileri_m * Ayarlar.PIKSEL_METRE
	oyun.ipucu.hide()
	oyun._bot = Bot.new(oyun.oyuncu, oyun.dunya_tehlike_araliklari, oyun.dunya_tavan_araliklari)
	return oyun


func _menu() -> void:
	var menu: Control = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _bekle(90)
	await _kaydet("ekran-1.png")
	menu.queue_free()
	await _bekle(2)


## Akşam teması, alçak tavanın altında kısa sıçrama.
func _oyun_tavan() -> void:
	var sira: Array[String] = ["res://scenes/parcalar/13_nefes_altin.tscn", "res://scenes/parcalar/21_riskli_rota.tscn",
		"res://scenes/parcalar/16_alcak_gecit.tscn", "res://scenes/parcalar/18_alcak_diken.tscn"]
	var oyun := await _oyun(sira, 260.0, 0, 5)
	# Oyuncu tavanın altına girene kadar koş
	var sinir := 60 * 20
	while sinir > 0:
		sinir -= 1
		await process_frame
		var x: float = oyun.oyuncu.global_position.x
		var alti := false
		for t in oyun.dunya_tavan_araliklari():
			if x > t[0] + 40.0 and x < t[1] - 120.0:
				alti = true
		if alti and not oyun.oyuncu.is_on_floor():
			break
	await _kaydet("ekran-2.png")
	oyun.queue_free()
	await _bekle(2)


## Yağış teması, pistonlar ve hareketli platform.
func _oyun_yagis() -> void:
	var sira: Array[String] = ["res://scenes/parcalar/13_nefes_altin.tscn", "res://scenes/parcalar/19_iki_piston.tscn",
		"res://scenes/parcalar/20_hareketli_kopru.tscn", "res://scenes/parcalar/24_piston_cukur.tscn"]
	var oyun := await _oyun(sira, 380.0, 1000, 8)
	await _bekle(60 * 4)
	# Bir piston ekrandayken çek
	var sinir := 60 * 10
	while sinir > 0:
		sinir -= 1
		await process_frame
		var gorunur := false
		for p in oyun.parcalar:
			for c in p.find_children("*", "", true, false):
				if not c is Tehlike:
					continue
				var dx: float = (c as Node2D).global_position.x - oyun.oyuncu.global_position.x
				if c.tur == Tehlike.Tur.PISTON and dx > 120.0 and dx < 260.0:
					gorunur = true
		if gorunur and not oyun.oyuncu.is_on_floor():
			break
	await _kaydet("ekran-3.png")
	oyun.queue_free()
	await _bekle(2)


## Neon teması, ölüm tekrarı ve sonuç paneli.
func _oyun_son() -> void:
	var sira: Array[String] = ["res://scenes/parcalar/13_nefes_altin.tscn", "res://scenes/parcalar/17_piston.tscn",
		"res://scenes/parcalar/10_diken_blok.tscn"]
	var oyun := await _oyun(sira, 340.0, 1500, 11)
	await _bekle(60 * 3)
	oyun._bot = null  # botu kapat, bir sonraki engelde koşu biter
	var sinir := 60 * 10
	while not oyun.bitti and sinir > 0:
		sinir -= 1
		await process_frame
	await _bekle(40)
	await _kaydet("ekran-4a-tekrar.png")
	sinir = 60 * 6
	while not oyun.son_paneli.visible and sinir > 0:
		sinir -= 1
		await process_frame
	await _bekle(30)
	await _kaydet("ekran-4.png")
	oyun.queue_free()
	await _bekle(2)


# ------------------------------------------------------------------ kapak
func _doku(yol: String, bolge := Rect2i()) -> Texture2D:
	var t: Texture2D = load(yol)
	if bolge.size == Vector2i.ZERO:
		return t
	var img := t.get_image().get_region(bolge)
	return ImageTexture.create_from_image(img)


func _sprite(kok: Node, doku: Texture2D, konum: Vector2, olcek: float, merkez := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = doku
	s.centered = merkez
	s.position = konum
	s.scale = Vector2(olcek, olcek)
	kok.add_child(s)
	return s


func _kapak() -> void:
	var boyut := Vector2i(630, 500)
	var sv := SubViewport.new()
	sv.size = boyut
	sv.transparent_bg = false
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(sv)

	var gok := TextureRect.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("262b44"), Color("68386c"), Color("f77622")])
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 128
	gok.texture = gt
	gok.size = Vector2(boyut)
	gok.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gok.stretch_mode = TextureRect.STRETCH_SCALE
	sv.add_child(gok)

	var yildiz := _sprite(sv, _doku("res://assets/sprites/yildizlar.png"), Vector2.ZERO, 2.0)
	yildiz.modulate.a = 0.7
	_sprite(sv, _doku("res://assets/sprites/ay.png"), Vector2(500, 120), 3.0)
	var uzak := _sprite(sv, _doku("res://assets/sprites/sehir_uzak.png"), Vector2(-120, 200), 1.5)
	uzak.modulate = Color(1, 0.85, 0.8)
	var yakin := _sprite(sv, _doku("res://assets/sprites/sehir_yakin.png"), Vector2(-60, 180), 1.5)
	yakin.modulate = Color(1, 0.9, 0.9)

	# Çatı: kenar karosu + tuğla/pencere
	var olcek := 3.0
	var karo := 16.0 * olcek
	var cati_y := 410.0
	var kenar := _doku("res://assets/sprites/zemin.png", Rect2i(0, 0, 16, 16))
	var tugla := _doku("res://assets/sprites/zemin.png", Rect2i(16, 0, 16, 16))
	var pencere := _doku("res://assets/sprites/zemin.png", Rect2i(32, 0, 16, 16))
	for i in 14:
		var x := i * karo
		_sprite(sv, kenar, Vector2(x, cati_y), olcek)
		_sprite(sv, pencere if i % 4 == 1 else tugla, Vector2(x, cati_y + karo), olcek)
	# Engeller
	var diken := _doku("res://assets/sprites/diken.png")
	for i in 3:
		_sprite(sv, diken, Vector2(400 + i * 36, cati_y - 36), 3.0)
	var tabela := _sprite(sv, _doku("res://assets/sprites/tavan_engeli.png"), Vector2(528, 244), 3.0)
	tabela.modulate = Color(1, 1, 1)
	# Altın kavisi
	var altin := _doku("res://assets/sprites/altin.png", Rect2i(0, 0, 12, 12))
	for i in 6:
		var t := float(i) / 5.0
		var ax := 250.0 + t * 250.0
		var ay := 330.0 - sin(t * PI) * 110.0
		_sprite(sv, altin, Vector2(ax, ay), 2.5, true)
	# Oyuncu: zıplama karesi
	var oyuncu := _doku("res://assets/sprites/oyuncu_klasik.png", Rect2i(8 * 20, 0, 20, 26))
	_sprite(sv, oyuncu, Vector2(190, 240), 6.0, true)

	# Başlık
	var baslik := Label.new()
	baslik.text = "TEK TUŞ KOŞU"
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	baslik.position = Vector2(0, 22)
	baslik.size = Vector2(boyut.x, 90)
	baslik.add_theme_font_size_override("font_size", 72)
	baslik.add_theme_color_override("font_color", Color("2ce8f5"))
	baslik.add_theme_color_override("font_outline_color", Color("181425"))
	baslik.add_theme_constant_override("outline_size", 16)
	sv.add_child(baslik)
	var alt := Label.new()
	alt.text = "tek tuş  •  sonsuz çatı koşusu"
	alt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alt.position = Vector2(0, 108)
	alt.size = Vector2(boyut.x, 30)
	alt.add_theme_font_size_override("font_size", 24)
	alt.add_theme_color_override("font_color", Color("fee761"))
	alt.add_theme_color_override("font_outline_color", Color("181425"))
	alt.add_theme_constant_override("outline_size", 8)
	sv.add_child(alt)

	await _bekle(5)
	await RenderingServer.frame_post_draw
	var img := sv.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(CIKTI + "kapak.png"))
	print("  kapak.png ", img.get_size())
	sv.queue_free()
