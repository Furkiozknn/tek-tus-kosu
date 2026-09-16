extends Control
## Ana menü: Başla / Karakter / Ayarlar / Çıkış, görevler, rekor ve toplam altın.

var d: Dictionary
var _aktif_panel: Control
var _basliyor := false


func _ready() -> void:
	Simgeler.kur()
	add_child(DikeyUyari.new())
	d = Kayit.yukle()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	Gorevler.hazirla(d, rng)
	Kayit.kaydet(d)
	_tam_ekran_uygula(bool(d["ayarlar"]["tam_ekran"]))
	Ses.ses_duzeyi_uygula()
	Ses.muzik("muzik_menu")

	%BaslaDugme.pressed.connect(basla)
	%GunlukDugme.pressed.connect(basla.bind(true))
	%RitimDugme.pressed.connect(func() -> void: _panel_ac(%RitimPaneli))
	for i in Ritim.SARKILAR.size():
		get_node("%%SarkiDugme%d" % i).pressed.connect(basla.bind(false, true, i))
	%RitimGeri.pressed.connect(func() -> void: _panel_ac(%AnaPanel))
	%GecikmeKaydirici.value = float(d["ayarlar"].get("ritim_gecikme", 0))
	%GecikmeKaydirici.value_changed.connect(func(v: float) -> void: _ayar("ritim_gecikme", int(v)); _yenile())
	%KarakterDugme.pressed.connect(func() -> void: _panel_ac(%KarakterPaneli))
	%BasarimDugme.pressed.connect(func() -> void: _panel_ac(%BasarimPaneli))
	%AyarlarDugme.pressed.connect(func() -> void: _panel_ac(%AyarlarPaneli))
	%CikisDugme.pressed.connect(func() -> void: get_tree().quit())
	%KarakterGeri.pressed.connect(func() -> void: _panel_ac(%AnaPanel))
	%BasarimGeri.pressed.connect(func() -> void: _panel_ac(%AnaPanel))
	%AyarlarGeri.pressed.connect(func() -> void: _panel_ac(%AnaPanel))
	# Web ve mobilde "Çıkış" ve tam ekran anlamsız.
	var masaustu := not (OS.has_feature("web") or OS.has_feature("mobile"))
	%CikisDugme.visible = masaustu
	%TamEkranKutu.visible = masaustu

	var a: Dictionary = d["ayarlar"]
	%MuzikKaydirici.value = float(a["muzik"]) * 100.0
	%EfektKaydirici.value = float(a["efekt"]) * 100.0
	%TamEkranKutu.button_pressed = bool(a["tam_ekran"])
	%SarsintiKutu.button_pressed = bool(a["sarsinti"])
	%TitresimKutu.button_pressed = bool(a.get("titresim", true))
	%KontrastKutu.button_pressed = bool(a["kontrast"])
	%RahatKutu.button_pressed = bool(a["rahat"])
	%MuzikKaydirici.value_changed.connect(func(v: float) -> void: _ayar("muzik", v / 100.0))
	%EfektKaydirici.value_changed.connect(func(v: float) -> void: _ayar("efekt", v / 100.0); Ses.cal("tik"))
	%TamEkranKutu.toggled.connect(func(v: bool) -> void: _ayar("tam_ekran", v); _tam_ekran_uygula(v))
	%SarsintiKutu.toggled.connect(func(v: bool) -> void: _ayar("sarsinti", v))
	%TitresimKutu.toggled.connect(func(v: bool) -> void: _ayar("titresim", v); if v: Input.vibrate_handheld(40))
	%KontrastKutu.toggled.connect(func(v: bool) -> void: _ayar("kontrast", v))
	%RahatKutu.toggled.connect(func(v: bool) -> void: _ayar("rahat", v); _yenile())

	%Onizleme.sprite_frames = Kostumler.kareler(str(d["kostum"]))
	%Onizleme.play("kos")
	_kostum_listesi()
	_basarim_listesi()
	_yenile()
	_panel_ac(%AnaPanel)
	%Perde.color.a = 1.0
	create_tween().tween_property(%Perde, "color:a", 0.0, 0.3)


func _ayar(ad: String, deger) -> void:
	d["ayarlar"][ad] = deger
	Kayit.kaydet(d)
	if ad in ["muzik", "efekt"]:
		Ses.ses_duzeyi_uygula()


func _tam_ekran_uygula(acik: bool) -> void:
	if OS.has_feature("web") or OS.has_feature("mobile") or DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if acik else DisplayServer.WINDOW_MODE_WINDOWED)


func _panel_ac(panel: Control) -> void:
	for p in [%AnaPanel, %KarakterPaneli, %AyarlarPaneli, %BasarimPaneli, %RitimPaneli]:
		p.visible = p == panel
	_aktif_panel = panel
	%Ipucu.visible = panel == %AnaPanel
	if panel == %AnaPanel:
		%BaslaDugme.grab_focus()
	elif panel == %KarakterPaneli:
		%KarakterGeri.grab_focus()
	elif panel == %BasarimPaneli:
		%BasarimGeri.grab_focus()
	elif panel == %RitimPaneli:
		%SarkiDugme0.grab_focus()
	else:
		%AyarlarGeri.grab_focus()
	Ses.cal("tik")


func _yenile() -> void:
	var rahat := bool(d["ayarlar"]["rahat"])
	%RekorEtiketi.text = ("Rahat rekor: %d m" % int(d["rekor_rahat"])) if rahat else ("Rekor: %d m" % int(d["rekor"]))
	%AltinEtiketi.text = "Altın: %d" % int(d["toplam_altin"])
	%KarakterAltin.text = "Altın: %d" % int(d["toplam_altin"])
	var gun := Gunluk.durum(d)
	var rr := 0
	for i in Ritim.SARKILAR.size():
		var sk: Dictionary = Ritim.SARKILAR[i]
		var r := int(d.get(sk["rekor"], 0))
		rr = maxi(rr, r)
		var b: Button = get_node("%%SarkiDugme%d" % i)
		b.text = "%s · %d BPM" % [sk["ad"], int(round(float(sk["bpm"])))] + ("" if r <= 0 else " · %d m" % r)
	%RitimDugme.text = "Ritim" if rr <= 0 else "Ritim · %d m" % rr
	%RitimDugme.tooltip_text = "Engeller müziğin vuruşlarına hizalı; vuruşta zıpla."
	var gc := int(d["ayarlar"].get("ritim_gecikme", 0))
	%GecikmeDeger.text = "%+d ms" % gc
	var seri := Gunluk.seri(d)
	%GunlukDugme.text = "Günlük koşu" if int(gun["deneme"]) == 0 else "Günlük · %d m" % int(gun["rekor"])
	if seri >= 2:
		%GunlukDugme.text += " · %d gün" % seri
	%GunlukDugme.tooltip_text = "Bugün herkes aynı çatılarda koşar. Deneme: %d" % int(gun["deneme"])
	%BasarimDugme.text = "Başarım %d/%d" % [(d["basarimlar"] as Array).size(), Basarimlar.LISTE.size()]
	var satirlar := ["GÖREVLER  (seviye %d)" % int(d["gorev_seviyesi"])]
	for g in d["gorevler"]:
		satirlar.append("• " + Gorevler.metin(g) + "  +%d" % int(g["odul"]))
	%GorevListesi.text = "\n".join(satirlar)


func _kostum_listesi() -> void:
	var liste: VBoxContainer = %KostumListesi
	for c in liste.get_children():
		c.queue_free()
	for k in Kostumler.LISTE:
		var satir := HBoxContainer.new()
		satir.add_theme_constant_override("separation", 10)
		satir.alignment = BoxContainer.ALIGNMENT_CENTER
		var resim := TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = load("res://assets/sprites/oyuncu_%s.png" % k["ad"])
		at.region = Rect2(12 * Kostumler.KARE.x, 0, Kostumler.KARE.x, Kostumler.KARE.y)
		resim.texture = at
		resim.custom_minimum_size = Vector2(24, 31)
		resim.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		resim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		satir.add_child(resim)
		var ad := Label.new()
		ad.text = k["isim"]
		ad.custom_minimum_size = Vector2(110, 0)
		ad.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ad.add_theme_font_size_override("font_size", 16)
		satir.add_child(ad)
		var dugme := Button.new()
		dugme.custom_minimum_size = Vector2(150, 30)
		dugme.add_theme_font_size_override("font_size", 14)
		var acik := (d["acik_kostumler"] as Array).has(k["ad"])
		if str(d["kostum"]) == k["ad"]:
			dugme.text = "Seçili"
			dugme.disabled = true
		elif acik:
			dugme.text = "Seç"
		else:
			dugme.text = "Satın al: %d altın" % int(k["fiyat"])
			dugme.disabled = int(d["toplam_altin"]) < int(k["fiyat"])
		dugme.pressed.connect(_kostum_sec.bind(str(k["ad"])))
		satir.add_child(dugme)
		liste.add_child(satir)


func _basarim_listesi() -> void:
	var liste: VBoxContainer = %BasarimListesi
	for c in liste.get_children():
		c.queue_free()
	var acik: Array = d["basarimlar"]
	for b in Basarimlar.LISTE:
		var l := Label.new()
		var tamam := acik.has(b["id"])
		l.text = ("★ " if tamam else "☆ ") + "%s — %s" % [b["ad"], b["metin"]]
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", Color("fee761") if tamam else Color("8b9bb4"))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		liste.add_child(l)


func _kostum_sec(ad: String) -> void:
	var acik_mi := (d["acik_kostumler"] as Array).has(ad)
	if not Kostumler.satin_al(d, ad):
		Ses.cal("hata")
		return
	Ses.cal("tik" if acik_mi else "satin")
	d["kostum"] = ad
	Basarimlar.denetle(d, Gorevler.bos_istatistik(), false)
	Kayit.kaydet(d)
	_basarim_listesi()
	%Onizleme.sprite_frames = Kostumler.kareler(ad)
	%Onizleme.play("kos")
	_kostum_listesi()
	_yenile()
	%KarakterGeri.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _aktif_panel != %AnaPanel:
		if event.is_action_pressed("duraklat"):
			_panel_ac(%AnaPanel)
			get_viewport().set_input_as_handled()
		return
	var dokunma: bool = event is InputEventScreenTouch and event.pressed and not _dugme_ustunde(event.position)
	# Masaüstünde fareyle boş yere tıklamak da başlatır (dokunmadan taklit edilen fare olayı sayılmaz).
	var tik: bool = event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.device != InputEvent.DEVICE_ID_EMULATION \
			and not _dugme_ustunde(event.position)
	if event.is_action_pressed("zipla") or dokunma or tik:
		get_viewport().set_input_as_handled()
		basla()


func _dugme_ustunde(konum: Vector2) -> bool:
	for b in [%BaslaDugme, %GunlukDugme, %KarakterDugme, %BasarimDugme, %RitimDugme, %AyarlarDugme, %CikisDugme]:
		if b.visible and b.get_global_rect().has_point(konum):
			return true
	return false


## Web'de dokunmatik cihazda: tam ekran + yatay kilit dene (tarayıcı izin vermezse sessizce geçer).
## Kullanıcı dokunuşunun hemen ardından çağrılmalı (tarayıcı kuralı).
func _telefonda_tam_ekran() -> void:
	if not OS.has_feature("web") or not DisplayServer.is_touchscreen_available():
		return
	var js := "(function(){var e=document.documentElement;if(document.fullscreenElement||!e.requestFullscreen){return;}" \
		+ "e.requestFullscreen().then(function(){if(screen.orientation&&screen.orientation.lock){" \
		+ "screen.orientation.lock('landscape').catch(function(){});}}).catch(function(){});})()"
	JavaScriptBridge.eval(js, true)


func basla(gunluk := false, ritim := false, sarki := 0) -> void:
	if _basliyor:
		return
	_basliyor = true
	Gunluk.secili = gunluk and not ritim
	Ritim.secili = ritim
	Ritim.sarki = sarki
	set_process_unhandled_input(false)
	_telefonda_tam_ekran()
	var tw := create_tween()
	tw.tween_property(%Perde, "color:a", 1.0, 0.25)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/oyun.tscn"))
