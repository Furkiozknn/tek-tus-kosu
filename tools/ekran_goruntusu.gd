extends SceneTree
## itch.io için ekran görüntüleri (1280x720) ve kapak (630x500) üretir.
## Görüntü gerektirir (headless değil). Linux'ta:
##   xvfb-run -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       --fixed-fps 60 --path . -s res://tools/ekran_goruntusu.gd
## Windows'ta aynı komut xvfb-run olmadan çalışır.

const CIKTI := "res://yayin/"
const KONTROL := "res://build/kontrol/"  ## yayına girmeyen denetim görüntüleri


func _initialize() -> void:
	_calistir.call_deferred()


func _calistir() -> void:
	Kayit.yol = "user://ekran_kayit.cfg"
	var d := Kayit.yukle()
	d["rekor"] = 180
	d["toplam_altin"] = 240
	d["acik_kostumler"] = ["klasik", "kizil", "neon"]
	d["olumler"] = [95, 140]
	d["basarimlar"] = ["ilk_kosu", "m500", "altin50"]
	d["gunluk_seri"] = {"son": "2026-09-15", "seri": 3, "en_iyi": 3}
	Kayit.kaydet(d)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(KONTROL))
	Gunluk.tarih_ezme = "2026-09-16"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Hayalet.dosya_yolu()))
	await _menu()
	await _oyun_tavan()
	await _oyun_yagis()
	await _oyun_son()
	await _gunluk_hayalet()
	await _iskele()
	await _ruzgar()
	await _ritim()
	await _firtina()
	await _menu_paneller()
	await _kapak()
	Gunluk.tarih_ezme = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Hayalet.dosya_yolu()))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.yol))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.yedek_yolu()))
	print("ekran görüntüleri hazır")
	quit()


func _bekle(n: int) -> void:
	for i in n:
		await process_frame


func _kaydet(ad: String, klasor := CIKTI) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(klasor + ad))
	print("  ", ad, " ", img.get_size())


func _oyun(sira: Array[String], hiz: float, ileri_m: int, tohum: int, gunluk := false) -> Node2D:
	var oyun: Node2D = (load("res://scenes/oyun.tscn") as PackedScene).instantiate()
	oyun.parca_sirasi = sira
	oyun.sabit_hiz = hiz
	oyun.tohum = tohum
	oyun.kayit_yap = true
	oyun.gunluk = gunluk
	root.add_child(oyun)
	await _bekle(2)
	if ileri_m != 0:
		oyun.baslangic_x -= ileri_m * Ayarlar.PIKSEL_METRE
		oyun._isaretleri_kur(Kayit.yukle())
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


## Günlük koşu: önce hızlı bir deneme hayalet olarak kaydedilir, sonra normal hızda
## ikinci denemede hayalet önde koşar.
func _gunluk_hayalet() -> void:
	var ilk := await _oyun([], 250.0, 0, -1, true)
	ilk.ipucu.hide()
	await _bekle(60 * 12)
	ilk.oyuncu.ol()
	await _bekle(3)
	ilk.queue_free()
	await _bekle(2)
	var oyun := await _oyun([], -1.0, 0, -1, true)
	await _bekle(60 * 7)
	await _kaydet("gunluk-hayalet.png", KONTROL)
	await _kaydet("ekran-5-gunluk.png")
	# Günlük sonuç paneli (Paylaş düğmesi) — denetim görüntüsü
	oyun.olum_tekrari_acik = false
	oyun.oyuncu.ol()
	await _bekle(20)
	(oyun.get_node("%PaylasDugme") as Button).pressed.emit()
	await _bekle(5)
	await _kaydet("gunluk-sonuc.png", KONTROL)
	print("  paylaşım metni:\n" + oyun.paylasim_metni())
	oyun.queue_free()
	await _bekle(2)


## v0.4: çürük iskele çökerken, neon kostümün iziyle.
func _iskele() -> void:
	var d := Kayit.yukle()
	var eski_kostum: String = d["kostum"]
	d["kostum"] = "neon"
	Kayit.kaydet(d)
	var sira: Array[String] = ["res://scenes/parcalar/13_nefes_altin.tscn", "res://scenes/parcalar/37_curuk_iskele.tscn",
		"res://scenes/parcalar/38_iskele_zinciri.tscn"]
	var oyun := await _oyun(sira, 250.0, 700, 4)
	await _bekle(60 * 3)
	var sinir := 60 * 20
	while sinir > 0:
		sinir -= 1
		await process_frame
		var coken := false
		for p in oyun.parcalar:
			for c in p.get_children():
				# Çöktükten ~0,1-0,25 sn sonra: tahtalar düşerken görünür
				if c is Coken and c.durum == Coken.Durum.COKTU and c.modulate.a > 0.6 and c.modulate.a < 0.85:
					var dx: float = c.global_position.x - oyun.oyuncu.global_position.x
					coken = coken or (dx > -240.0 and dx < 80.0)
		if coken:
			break
	if sinir <= 0:
		push_error("iskele görüntüsü için uygun an bulunamadı")
	await _kaydet("ekran-6-iskele.png")
	sinir = 60 * 5
	while sinir > 0 and not oyun.oyuncu.is_on_floor():
		sinir -= 1
		await process_frame
	await _bekle(20)
	await _kaydet("iz-neon.png", KONTROL)
	oyun.queue_free()
	await _bekle(2)
	d = Kayit.yukle()
	d["kostum"] = eski_kostum
	Kayit.kaydet(d)


## v0.5: karşı rüzgârda zıplama (denetim görüntüsü) ve dikey uyarı perdesi.
func _ruzgar() -> void:
	var sira: Array[String] = ["res://scenes/parcalar/13_nefes_altin.tscn", "res://scenes/parcalar/41_karsi_ruzgar.tscn",
		"res://scenes/parcalar/43_firtina.tscn"]
	var oyun := await _oyun(sira, 320.0, 900, 6)
	var sinir := 60 * 20
	var cekilen := 0
	while sinir > 0 and cekilen < 2:
		sinir -= 1
		await process_frame
		var r: float = oyun.oyuncu.ruzgar
		if not oyun.oyuncu.is_on_floor() and ((cekilen == 0 and r < 0.0) or (cekilen == 1 and r > 0.0)) and oyun.oyuncu.velocity.y > -100.0:
			await _kaydet("ruzgar-karsi.png" if cekilen == 0 else "ruzgar-arka.png", KONTROL)
			cekilen += 1
	if cekilen < 2:
		push_error("rüzgâr görüntüsü için uygun an bulunamadı (%d)" % cekilen)
	DikeyUyari.zorla = 1
	(oyun.get_node("DikeyUyari") as DikeyUyari).denetle()
	await _bekle(5)
	await _kaydet("dikey-uyari.png", KONTROL)
	DikeyUyari.zorla = -1
	get_root_paused_sifirla()
	oyun.queue_free()
	await _bekle(2)


## v0.6: ritim koşusu — vuruş lambaları, tam vuruş yazısı.
func _ritim() -> void:
	var d := Kayit.yukle()
	d["rekor_ritim"] = 820
	Kayit.kaydet(d)
	var oyun: Node2D = (load("res://scenes/oyun.tscn") as PackedScene).instantiate()
	oyun.ritim = true
	oyun.tohum = 5
	oyun.kayit_yap = false
	oyun.olum_tekrari_acik = false
	oyun.bot_modu = true
	root.add_child(oyun)
	await _bekle(2)
	oyun.ipucu.hide()
	await _bekle(60 * 26)
	var sinir := 60 * 30
	var onceki: int = oyun.istatistik["ritim"]
	while sinir > 0:
		sinir -= 1
		await process_frame
		if int(oyun.istatistik["ritim"]) > onceki:
			onceki = int(oyun.istatistik["ritim"])
			# İkili desende art arda iki tam vuruş: ikincisinin tepesinde çek
			if onceki >= 2 and oyun._ritim_seri >= 2:
				break
	if sinir <= 0:
		push_error("ritim görüntüsü için uygun an bulunamadı")
	await _bekle(16)
	await _kaydet("ekran-7-ritim.png")
	# Sonuç paneli (v1.7): sapma histogramı — dağılım geç tarafa yığılı, ortalama +60 ms → gecikme önerisi düğmesi de çıkar
	oyun._ritim_sapmalar.clear()
	for ms in [-120.0, -60.0, -30.0, 10.0, 25.0, 40.0, 55.0, 65.0, 85.0, 95.0, 110.0, 130.0, 165.0, 190.0]:
		oyun._ritim_sapmalar.append(ms)
	oyun.oyuncu.ol()
	await _bekle(10)
	await _kaydet("ekran-9-sonuc.png")
	await _kaydet("ritim-sonuc.png", KONTROL)
	oyun.queue_free()
	await _bekle(2)


## v1.5: Fırtına Hattı — yağmurlu kilitli tema ve şimşek anı (ölçü başında çakar; 3. karede perde hâlâ belirgin)
func _firtina() -> void:
	var oyun: Node2D = (load("res://scenes/oyun.tscn") as PackedScene).instantiate()
	oyun.ritim = true
	oyun.ritim_sarki = 2
	oyun.tohum = 9
	oyun.kayit_yap = false
	oyun.olum_tekrari_acik = false
	oyun.bot_modu = true
	root.add_child(oyun)
	await _bekle(2)
	oyun.ipucu.hide()
	await _bekle(60 * 12)
	var sinir := 60 * 40
	var onceki: int = oyun._simsek_sayisi
	while sinir > 0:
		sinir -= 1
		await process_frame
		if oyun._simsek_sayisi > onceki:
			break
	if sinir <= 0:
		push_error("fırtına görüntüsü için şimşek bulunamadı")
	await _bekle(2)
	await _kaydet("ekran-8-firtina.png")
	oyun.queue_free()
	await _bekle(2)


func get_root_paused_sifirla() -> void:
	paused = false


func _menu_paneller() -> void:
	var menu: Control = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _bekle(20)
	(menu.get_node("%BasarimDugme") as Button).pressed.emit()
	await _bekle(10)
	await _kaydet("menu-basarim.png", KONTROL)
	(menu.get_node("%BasarimGeri") as Button).pressed.emit()
	(menu.get_node("%AyarlarDugme") as Button).pressed.emit()
	await _bekle(10)
	await _kaydet("menu-ayarlar.png", KONTROL)
	(menu.get_node("%AyarlarGeri") as Button).pressed.emit()
	(menu.get_node("%KarakterDugme") as Button).pressed.emit()
	await _bekle(10)
	await _kaydet("menu-karakter.png", KONTROL)
	(menu.get_node("%KarakterGeri") as Button).pressed.emit()
	(menu.get_node("%RitimDugme") as Button).pressed.emit()
	await _bekle(10)
	await _kaydet("menu-ritim.png", KONTROL)
	(menu.get_node("%RitimGeri") as Button).pressed.emit()
	await _bekle(10)
	await _kaydet("menu-gunluk-seri.png", KONTROL)
	menu.queue_free()
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
