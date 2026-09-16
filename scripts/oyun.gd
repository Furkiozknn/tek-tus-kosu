extends Node2D
## Sonsuz koşu oyun sahnesi: parça üretimi, hız artışı, puan, görevler, temalar,
## oyun hissi (parçacık, sarsıntı), ölüm tekrarı, duraklatma, oyun sonu.

signal kosu_bitti(mesafe: int, altin: int)

# --- Test / demo ayarları (normal oyunda dokunulmaz) ---
var bot_modu := false
var sabit_hiz := -1.0                 ## >= 0 ise hız artmaz
var parca_sirasi: Array[String] = []  ## Boş değilse parçalar bu sırayla gelir
var tohum := -1                       ## >= 0 ise rastgelelik sabit
var sira_bitince_duz := false         ## Test: sıra bitince yalnız düz zemin gelsin
var kayit_yap := true
var olum_tekrari_acik := true         ## Testlerde kapatılabilir
var gunluk := false                   ## Günlük koşu (menüden Gunluk.secili ile gelir)

const TEMALAR := [
	{"ad": "Akşam", "ust": Color("68386c"), "alt": Color("f77622"), "uzak": Color(1, 0.85, 0.8), "yakin": Color(1, 0.9, 0.9), "yildiz": 0.3, "yagis": false},
	{"ad": "Gece", "ust": Color("181425"), "alt": Color("262b44"), "uzak": Color(1, 1, 1), "yakin": Color(1, 1, 1), "yildiz": 1.0, "yagis": false},
	{"ad": "Yağış", "ust": Color("262b44"), "alt": Color("5a6988"), "uzak": Color(0.75, 0.8, 0.9), "yakin": Color(0.8, 0.85, 0.95), "yildiz": 0.0, "yagis": true},
	{"ad": "Neon", "ust": Color("181425"), "alt": Color("b55088"), "uzak": Color(0.9, 0.7, 1.0), "yakin": Color(1.0, 0.75, 1.0), "yildiz": 0.6, "yagis": false},
]

@onready var dunya: Node2D = $Dunya
@onready var oyuncu: Oyuncu = $Oyuncu
@onready var kamera: Camera2D = $Kamera
@onready var efektler: Node2D = $Efektler
@onready var gok: TextureRect = $Gokyuzu/Gok
@onready var yagis: CPUParticles2D = $Yagis/Damlalar
@onready var katman_yildiz: Parallax2D = $Yildizlar
@onready var katman_uzak: Parallax2D = $SehirUzak
@onready var katman_yakin: Parallax2D = $SehirYakin
@onready var gecis: ColorRect = $Gecis/Perde
@onready var mesafe_etiketi: Label = %Mesafe
@onready var altin_etiketi: Label = %AltinSayisi
@onready var rekor_etiketi: Label = %Rekor
@onready var ipucu: Label = %Ipucu
@onready var gorev_bildirimi: Label = %GorevBildirimi
@onready var tekrar_etiketi: Label = %TekrarEtiketi
@onready var duraklat_paneli: Control = %DuraklatPaneli
@onready var son_paneli: Control = %SonPaneli
@onready var son_skor: Label = %SonSkor
@onready var son_rekor: Label = %SonRekor
@onready var son_altin: Label = %SonAltin
@onready var son_gorevler: Label = %SonGorevler

var rng := RandomNumberGenerator.new()          ## görevler vb.
var parca_rng := RandomNumberGenerator.new()    ## yalnız parça dizisi (günlük koşuda sabit tohum)
var parcalar: Array[Parca] = []
var sonraki_x := 0.0
var baslangic_x := 0.0
var sure := 0.0
var altin := 0
var bitti := false
var rahat := false
var istatistik := Gorevler.bos_istatistik()
var gorevler: Array = []
var son_sonuc := {}
var tema := -1
var sarsinti_acik := true

var _yeniden_baslat_izni := 0.0
var _son_parca := ""
var _sahneler := {}
var _bot: Bot
var _rekor := 0
var _nefes_sayac := 0
var _nefes_hedef := 5
var _gorev_bildirildi := [false, false, false]
var _sarsinti := 0.0
var _altin_seri := 0.0
var _altin_perde := 1.0
var _tekrar_dizi: Array = []
var _tekrar_i := 0.0
var _tekrar_hayalet: AnimatedSprite2D
var _tekrar_vurgu: Line2D
var _tema_tween: Tween
var _gok_gradyan := Gradient.new()
var _tehlike_sirasi: Array = []        ## henüz geçilmemiş tehlikeler (x'e göre)
var _basarim_bildirilen: Array = []
var _basarim_sayac := 0
var _hayalet_kayit: Hayalet             ## bu koşunun örnekleri (günlük)
var _hayalet_rakip: Hayalet             ## günün en iyi denemesi
var _hayalet_sprite: AnimatedSprite2D
var _hayalet_bitti := false
var _isaretler: Array = []
var _titresim := true
var _basarim_onbellek: Dictionary = {}


func _ready() -> void:
	add_to_group("oyun")
	gunluk = gunluk or Gunluk.secili
	for yol in ParcaListesi.YOLLAR:
		_sahneler[yol] = load(yol)
	var gt := GradientTexture2D.new()
	gt.gradient = _gok_gradyan
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	gok.texture = gt

	oyuncu.oldu.connect(_oyuncu_oldu)
	oyuncu.ziplandi.connect(_ziplandi)
	oyuncu.indi.connect(_indi)
	%DuraklatDugme.pressed.connect(duraklat)
	%DevamDugme.pressed.connect(devam)
	%MenuDugme.pressed.connect(menuye_don)
	%TekrarDugme.pressed.connect(yeniden_baslat)
	%SonMenuDugme.pressed.connect(menuye_don)
	yeniden_baslat()


## Koşuyu sahneyi yeniden yüklemeden sıfırlar (< 1 sn).
func yeniden_baslat() -> void:
	get_tree().paused = false
	var d := Kayit.yukle()
	var ayar: Dictionary = d["ayarlar"]
	rahat = bool(ayar["rahat"]) and not bot_modu and not gunluk
	sarsinti_acik = bool(ayar["sarsinti"])
	_titresim = bool(ayar.get("titresim", true))
	Tehlike.kontrast = bool(ayar["kontrast"])
	if tohum >= 0:
		rng.seed = tohum
		parca_rng.seed = tohum
	else:
		rng.randomize()
		parca_rng.randomize()
	if gunluk:
		parca_rng.seed = Gunluk.tohum(Gunluk.bugun())
	Gorevler.hazirla(d, rng)
	if kayit_yap:
		Kayit.kaydet(d)
	gorevler = d["gorevler"].duplicate(true)
	_gorev_bildirildi = [false, false, false]
	for i in gorevler.size():
		_gorev_bildirildi[i] = Gorevler.tamam_mi(gorevler[i], Gorevler.bos_istatistik())
	_rekor = _mod_rekoru(d)
	rekor_etiketi.text = _rekor_metni(_rekor)

	for p in parcalar:
		if is_instance_valid(p):
			dunya.remove_child(p)
			p.queue_free()
	parcalar.clear()
	for c in efektler.get_children():
		c.queue_free()
	_tekrar_temizle()
	sonraki_x = 0.0
	sure = 0.0
	altin = 0
	istatistik = Gorevler.bos_istatistik()
	bitti = false
	son_sonuc = {}
	_son_parca = ""
	_nefes_sayac = 0
	_nefes_hedef = parca_rng.randi_range(Ayarlar.NEFES_ARALIGI.x, Ayarlar.NEFES_ARALIGI.y)
	_tehlike_sirasi.clear()
	_basarim_bildirilen.clear()
	_basarim_sayac = 0
	_sarsinti = 0.0
	dunya.process_mode = Node.PROCESS_MODE_INHERIT
	oyuncu.process_mode = Node.PROCESS_MODE_PAUSABLE
	oyuncu.visible = true
	oyuncu.kostum_uygula(str(d["kostum"]))
	oyuncu.sifirla(Vector2(100.0, Ayarlar.ZEMIN_Y))
	oyuncu.hiz = _hiz_hesapla()
	baslangic_x = oyuncu.global_position.x
	altin_etiketi.text = "0"
	mesafe_etiketi.text = "0 m"
	duraklat_paneli.hide()
	son_paneli.hide()
	tekrar_etiketi.hide()
	gorev_bildirimi.hide()
	ipucu.visible = not bot_modu

	# Başlangıçta iki düz parça: ısınma alanı.
	_parca_ekle(ParcaListesi.DUZ)
	_parca_ekle(ParcaListesi.DUZ)
	_isaretleri_kur(d)
	_hayalet_kur()
	_kamera_guncelle()
	_parcalari_guncelle()
	tema = -1
	_tema_guncelle(true)

	if bot_modu:
		_bot = Bot.new(oyuncu, dunya_tehlike_araliklari, dunya_tavan_araliklari)
	if not bot_modu:
		Ses.muzik("muzik_oyun")
	gecis.color.a = 1.0
	create_tween().tween_property(gecis, "color:a", 0.0, 0.35)


func _hiz_hesapla() -> float:
	var h := Ayarlar.HIZ_BAS + Ayarlar.HIZ_ARTIS * sure if sabit_hiz < 0.0 else sabit_hiz
	h = minf(h, Ayarlar.HIZ_AZAMI) if sabit_hiz < 0.0 else h
	return h * (Ayarlar.RAHAT_MOD_CARPANI if rahat else 1.0)


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	_sarsinti_guncelle(delta)
	if bitti:
		_yeniden_baslat_izni -= delta
		_tekrar_adim()
		return
	sure += delta
	oyuncu.hiz = _hiz_hesapla()
	if _bot:
		_bot.adim()
	_parcalari_guncelle()
	_kamera_guncelle()
	var m := mesafe()
	istatistik["mesafe"] = m
	mesafe_etiketi.text = "%d m" % m
	if ipucu.visible and sure > 4.0:
		ipucu.hide()
	_altin_seri = maxf(_altin_seri - delta, 0.0)
	_gecisleri_say()
	_gorevleri_denetle()
	_basarimlari_denetle()
	_hayalet_adim()
	_tema_guncelle(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("duraklat"):
		if get_tree().paused:
			devam()
		elif not bitti:
			duraklat()
		get_viewport().set_input_as_handled()
		return
	if bot_modu or get_tree().paused:
		return
	var basildi := false
	var birakildi := false
	if event.is_action_pressed("zipla"):
		basildi = true
	elif event.is_action_released("zipla"):
		birakildi = true
	elif event is InputEventScreenTouch:
		if %DuraklatDugme.get_global_rect().has_point(event.position):
			return
		basildi = event.pressed
		birakildi = not event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.device != InputEvent.DEVICE_ID_EMULATION:
		basildi = event.pressed
		birakildi = not event.pressed
	if not (basildi or birakildi):
		return
	get_viewport().set_input_as_handled()
	if bitti:
		if basildi and not _tekrar_dizi.is_empty():
			_tekrar_bitir()
		elif basildi and _yeniden_baslat_izni <= 0.0 and son_paneli.visible:
			yeniden_baslat()
		return
	if basildi:
		oyuncu.zipla_bas()
	else:
		oyuncu.zipla_birak()


func mesafe() -> int:
	return int((oyuncu.global_position.x - baslangic_x) / Ayarlar.PIKSEL_METRE)


# ------------------------------------------------------------------ olaylar
func altin_toplandi(konum: Vector2 = Vector2.INF) -> void:
	altin += 1
	istatistik["altin"] = altin
	altin_etiketi.text = str(altin)
	_altin_perde = minf(_altin_perde + 0.06, 1.6) if _altin_seri > 0.0 else 1.0
	_altin_seri = 0.45
	Ses.cal("altin", _altin_perde)
	if konum != Vector2.INF:
		_parcacik(konum, Color("fee761"), 6, 60.0, 0.3)


func yakin_kacis(tehlike: Node2D) -> void:
	if bitti:
		return
	altin += Ayarlar.YAKIN_KACIS_ODULU
	istatistik["altin"] = altin
	istatistik["yakin"] = int(istatistik["yakin"]) + 1
	altin_etiketi.text = str(altin)
	Ses.cal("yakin")
	_yazi(oyuncu.global_position + Vector2(0, -34), "Kıl payı! +%d" % Ayarlar.YAKIN_KACIS_ODULU, Color("2ce8f5"))
	if tehlike:
		_parcacik(oyuncu.global_position, Color("2ce8f5"), 5, 50.0, 0.25)


func _ziplandi(ikinci: bool) -> void:
	if ikinci:
		istatistik["ikinci"] = int(istatistik["ikinci"]) + 1
		Ses.cal("ikinci")
		_parcacik(oyuncu.global_position, Color("c0cbdc"), 6, 70.0, 0.25)
	else:
		Ses.cal("zipla")
		_parcacik(oyuncu.global_position, Color("8b9bb4"), 5, 40.0, 0.25)


func _indi() -> void:
	Ses.cal("indi")
	_parcacik(oyuncu.global_position, Color("8b9bb4"), 6, 45.0, 0.3)


func _gorevleri_denetle() -> void:
	for i in gorevler.size():
		if _gorev_bildirildi[i]:
			continue
		if Gorevler.tamam_mi(gorevler[i], istatistik):
			_gorev_bildirildi[i] = true
			Ses.cal("gorev")
			gorev_bildirimi.text = "Görev tamam: %s  +%d altın" % [gorevler[i]["metin"], int(gorevler[i]["odul"])]
			gorev_bildirimi.show()
			gorev_bildirimi.modulate.a = 1.0
			var tw := create_tween()
			tw.tween_interval(1.8)
			tw.tween_property(gorev_bildirimi, "modulate:a", 0.0, 0.5)


## Tüm canlı parçaların tehlike aralıkları, dünya koordinatında.
func dunya_tehlike_araliklari() -> Array:
	var sonuc: Array = []
	for p in parcalar:
		for a in p.tehlike_araliklari():
			sonuc.append(a + Vector2(p.position.x, p.position.x))
	return sonuc


func dunya_tavan_araliklari() -> Array:
	var sonuc: Array = []
	for p in parcalar:
		for t in p.tavan_araliklari():
			sonuc.append([t[0] + p.position.x, t[1] + p.position.x, t[2]])
	return sonuc


# ------------------------------------------------------------------ parçalar
func _parcalari_guncelle() -> void:
	var sol := kamera.global_position.x - 320.0
	var sag := kamera.global_position.x + 320.0
	while sonraki_x < sag + Ayarlar.PARCA_ONDEN_URET:
		_parca_ekle(_parca_sec())
	while not parcalar.is_empty() and parcalar[0].position.x + parcalar[0].uzunluk < sol - Ayarlar.PARCA_ARKADA_SIL:
		parcalar.pop_front().queue_free()


func _parca_sec() -> String:
	if not parca_sirasi.is_empty():
		return parca_sirasi.pop_front()
	if sira_bitince_duz:
		return ParcaListesi.DUZ
	var hiz := _secim_hizi()
	_nefes_sayac += 1
	var nefes := _nefes_sayac > _nefes_hedef
	if nefes:
		_nefes_sayac = 0
		_nefes_hedef = parca_rng.randi_range(Ayarlar.NEFES_ARALIGI.x, Ayarlar.NEFES_ARALIGI.y)
	var adaylar: Array[String] = []
	var agirliklar: Array[float] = []
	for yol in ParcaListesi.YOLLAR:
		var z: int = ParcaListesi.ZORLUK[yol]
		if (z == 0) != nefes or hiz < Ayarlar.zorluk_esigi(z) or yol == _son_parca:
			continue
		adaylar.append(yol)
		# Hız arttıkça zor parçalar daha sık gelsin.
		agirliklar.append(1.0 + maxi(z - 1, 0) * clampf((hiz - Ayarlar.HIZ_BAS) / 120.0, 0.0, 2.0))
	if adaylar.is_empty():
		return ParcaListesi.DUZ
	var secim := adaylar[parca_rng.rand_weighted(PackedFloat32Array(agirliklar))]
	_son_parca = secim
	return secim


## Parçanın başladığı yerde oyuncunun (rahat mod çarpanı olmadan) sahip olacağı hız.
## Kare hızından bağımsızdır; aynı tohum her makinede aynı parça dizisini verir.
func _secim_hizi() -> float:
	if sabit_hiz >= 0.0:
		return sabit_hiz
	var d := (sonraki_x - baslangic_x) / (Ayarlar.RAHAT_MOD_CARPANI if rahat else 1.0)
	return Ayarlar.hiz_mesafede(d)


func _parca_ekle(yol: String) -> void:
	var p: Parca = _sahneler[yol].instantiate()
	p.position = Vector2(sonraki_x, 0.0)
	dunya.add_child(p)
	parcalar.append(p)
	sonraki_x += p.uzunluk
	for c in p.get_children():
		if c is Tehlike and (c.tur == Tehlike.Tur.TAVAN or c.tur == Tehlike.Tur.PISTON):
			_tehlike_sirasi.append(c)


func _kamera_guncelle() -> void:
	var hedef: Vector2 = oyuncu.global_position if _tekrar_hayalet == null else _tekrar_hayalet.global_position
	kamera.global_position = Vector2(hedef.x - Ayarlar.OYUNCU_EKRAN_X + 320.0, 180.0)


# ------------------------------------------------------------------ görsel
func _tema_guncelle(aninda: bool) -> void:
	var yeni := int(mesafe() / Ayarlar.TEMA_ARALIGI_M) % TEMALAR.size()
	if yeni == tema:
		return
	tema = yeni
	var t: Dictionary = TEMALAR[tema]
	yagis.emitting = t["yagis"]
	if _tema_tween:
		_tema_tween.kill()
	var sure_ := 0.0 if aninda else 2.0
	var bas_ust: Color = _gok_gradyan.get_color(0) if _gok_gradyan.get_point_count() > 0 else t["ust"]
	var bas_alt: Color = _gok_gradyan.get_color(1) if _gok_gradyan.get_point_count() > 1 else t["alt"]
	if aninda:
		_gok_ayarla(t["ust"], t["alt"])
		katman_uzak.modulate = t["uzak"]
		katman_yakin.modulate = t["yakin"]
		katman_yildiz.modulate.a = t["yildiz"]
		return
	_tema_tween = create_tween().set_parallel()
	_tema_tween.tween_method(func(k: float) -> void: _gok_ayarla(bas_ust.lerp(t["ust"], k), bas_alt.lerp(t["alt"], k)), 0.0, 1.0, sure_)
	_tema_tween.tween_property(katman_uzak, "modulate", t["uzak"], sure_)
	_tema_tween.tween_property(katman_yakin, "modulate", t["yakin"], sure_)
	_tema_tween.tween_property(katman_yildiz, "modulate:a", t["yildiz"], sure_)
	_yazi(oyuncu.global_position + Vector2(120, -80), t["ad"], Color("c0cbdc"))


func _gok_ayarla(ust: Color, alt: Color) -> void:
	_gok_gradyan.colors = PackedColorArray([ust, alt])
	_gok_gradyan.offsets = PackedFloat32Array([0.0, 1.0])


func _parcacik(konum: Vector2, renk: Color, adet: int, hiz: float, omur: float) -> void:
	if bot_modu:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = adet
	p.lifetime = omur
	p.explosiveness = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = hiz * 0.5
	p.initial_velocity_max = hiz
	p.gravity = Vector2(0, 200)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = renk
	p.global_position = konum
	efektler.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _yazi(konum: Vector2, metin: String, renk: Color) -> void:
	var l := Label.new()
	l.text = metin
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", renk)
	l.add_theme_color_override("font_outline_color", Color("181425"))
	l.add_theme_constant_override("outline_size", 4)
	l.position = konum - Vector2(40, 0)
	efektler.add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", konum.y - 24.0, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)


func sars(guc: float) -> void:
	if sarsinti_acik:
		_sarsinti = maxf(_sarsinti, guc)


func _sarsinti_guncelle(delta: float) -> void:
	if _sarsinti <= 0.05:
		kamera.offset = Vector2.ZERO
		return
	kamera.offset = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _sarsinti
	_sarsinti = move_toward(_sarsinti, 0.0, delta * 20.0)


# ------------------------------------------------------------------ ölüm + tekrar
func _oyuncu_oldu() -> void:
	bitti = true
	_yeniden_baslat_izni = 0.5
	Ses.cal("olum")
	sars(Ayarlar.SARSINTI_OLUM)
	if _titresim and not bot_modu:
		Input.vibrate_handheld(Ayarlar.TITRESIM_OLUM_MS)
	_parcacik(oyuncu.global_position + Vector2(0, -10), Color("0099db"), 18, 110.0, 0.6)
	_kosu_sonucunu_isle()
	if olum_tekrari_acik and oyuncu.gecmis.size() > 10:
		_tekrar_baslat()
	else:
		_son_paneli_goster()


func _kosu_sonucunu_isle() -> void:
	var m := mesafe()
	istatistik["mesafe"] = m
	istatistik["kosu"] = 1
	var d := Kayit.yukle()
	var anahtar := "rekor_rahat" if rahat else "rekor"
	var onceki_olumler := _olum_listesi(d).duplicate()
	var onceki_rekor := _mod_rekoru(d)
	var yeni_rekor: bool = m > onceki_rekor
	var gorev_sonuc := {"tamamlanan": [], "odul": 0, "seviye_atladi": false}
	var basarimlar: Array = []
	if kayit_yap:
		d[anahtar] = maxi(int(d[anahtar]), m)
		d["toplam_altin"] = int(d["toplam_altin"]) + altin
		d["kosu_sayisi"] = int(d["kosu_sayisi"]) + 1
		d["toplam_mesafe"] = int(d["toplam_mesafe"]) + m
		if gunluk:
			Gunluk.kosu_isle(d, m)
			if yeni_rekor and _hayalet_kayit:
				_hayalet_kayit.tarih = Gunluk.bugun()
				_hayalet_kayit.mesafe = m
				_hayalet_kayit.kaydet()
		else:
			var liste: Array = d["olumler_rahat" if rahat else "olumler"]
			liste.append(m)
			while liste.size() > Ayarlar.OLUM_ISARETI_SAYISI:
				liste.pop_front()
		gorev_sonuc = Gorevler.kosu_sonu(d, istatistik, rng)
		basarimlar = Basarimlar.denetle(d, istatistik, gunluk)
		Kayit.kaydet(d)
	son_sonuc = {"mesafe": m, "yeni_rekor": yeni_rekor, "rekor": maxi(onceki_rekor, m), "gorev": gorev_sonuc,
		"gorevler": d["gorevler"], "seviye": int(d["gorev_seviyesi"]), "olumler": onceki_olumler,
		"basarimlar": basarimlar, "deneme": int(Gunluk.durum(d)["deneme"]) if gunluk else 0}
	kosu_bitti.emit(m, altin)


func _tekrar_baslat() -> void:
	dunya.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	oyuncu.visible = false
	var n := mini(Ayarlar.OLUM_TEKRARI_KARE, oyuncu.gecmis.size())
	_tekrar_dizi = oyuncu.gecmis.slice(oyuncu.gecmis.size() - n)
	_tekrar_i = 0.0
	_tekrar_hayalet = AnimatedSprite2D.new()
	_tekrar_hayalet.sprite_frames = oyuncu.gorsel.sprite_frames
	_tekrar_hayalet.centered = false
	_tekrar_hayalet.offset = oyuncu.gorsel.offset
	_tekrar_hayalet.modulate = Color(1, 1, 1, 0.8)
	efektler.add_child(_tekrar_hayalet)
	_tekrar_hayalet.global_position = _tekrar_dizi[0][0]
	var r := Rect2()
	var neden: Variant = oyuncu.olum_nedeni
	if neden is Tehlike:
		r = (neden as Tehlike).isabet_rect()
	elif neden is Node2D:
		var yer: Vector2 = _tekrar_dizi[-1][0]
		r = Rect2(yer.x + 4, yer.y - 26, 6, 26)
	if r.size != Vector2.ZERO:
		_tekrar_vurgu = Line2D.new()
		_tekrar_vurgu.width = 2.0
		_tekrar_vurgu.default_color = Color("ff0044")
		_tekrar_vurgu.points = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position])
		efektler.add_child(_tekrar_vurgu)
	tekrar_etiketi.text = "Çukura düştün  •  geçmek için dokun" if str(neden) == "cukur" else "Ölüm tekrarı  •  geçmek için dokun"
	tekrar_etiketi.show()


func _tekrar_adim() -> void:
	if _tekrar_dizi.is_empty():
		return
	_tekrar_i += Ayarlar.OLUM_TEKRARI_HIZ
	var i := int(_tekrar_i)
	if i >= _tekrar_dizi.size():
		_tekrar_bitir()
		return
	var kayit: Array = _tekrar_dizi[i]
	_tekrar_hayalet.global_position = kayit[0]
	if _tekrar_hayalet.animation != kayit[1]:
		_tekrar_hayalet.animation = kayit[1]
	_tekrar_hayalet.frame = kayit[2]
	if _tekrar_vurgu:
		_tekrar_vurgu.visible = int(_tekrar_i * 0.5) % 4 != 0
	_kamera_guncelle()


func _tekrar_bitir() -> void:
	_tekrar_dizi = []
	_tekrar_temizle()
	oyuncu.visible = true
	_kamera_guncelle()
	_son_paneli_goster()


func _tekrar_temizle() -> void:
	tekrar_etiketi.hide()
	if is_instance_valid(_tekrar_hayalet):
		_tekrar_hayalet.queue_free()
	if is_instance_valid(_tekrar_vurgu):
		_tekrar_vurgu.queue_free()
	_tekrar_hayalet = null
	_tekrar_vurgu = null


func _son_paneli_goster() -> void:
	_yeniden_baslat_izni = maxf(_yeniden_baslat_izni, 0.35)
	var s := son_sonuc
	son_skor.text = "Mesafe: %d m" % int(s.get("mesafe", mesafe()))
	if gunluk:
		son_rekor.text = ("GÜNÜN REKORU!" if s.get("yeni_rekor", false) else "Bugünün rekoru: %d m" % int(s.get("rekor", _rekor))) \
				+ "   (deneme %d)" % int(s.get("deneme", 0))
	else:
		son_rekor.text = ("YENİ REKOR!" if s.get("yeni_rekor", false) else "Rekor: %d m" % int(s.get("rekor", _rekor)))
	%SonHarita.ayarla(int(s.get("mesafe", mesafe())), int(s.get("rekor", _rekor)), s.get("olumler", []))
	if s.get("yeni_rekor", false):
		_rekor = int(s.get("rekor", _rekor))
		rekor_etiketi.text = _rekor_metni(_rekor)
		Ses.cal("rekor")
		_parcacik(kamera.global_position + Vector2(0, -60), Color("fee761"), 24, 150.0, 0.9)
	var g: Dictionary = s.get("gorev", {})
	var satirlar := []
	var ek_odul := int(g.get("odul", 0)) + Ayarlar.BASARIM_ODULU * (s.get("basarimlar", []) as Array).size()
	satirlar.append("Altın: %d" % altin + ("   Ödül: +%d" % ek_odul if ek_odul > 0 else ""))
	var yeni_basarimlar: Array = s.get("basarimlar", [])
	if not yeni_basarimlar.is_empty():
		satirlar.append("★ " + ", ".join(yeni_basarimlar.map(func(b: Dictionary) -> String: return str(b["ad"]))))
	for tamam in g.get("tamamlanan", []):
		satirlar.append("✓ " + str(tamam["metin"]))
	for gv in s.get("gorevler", gorevler):
		satirlar.append("• " + Gorevler.metin(gv))
	if g.get("seviye_atladi", false):
		satirlar.append("Görev seviyesi %d!" % int(s.get("seviye", 1)))
	son_altin.text = satirlar[0]
	son_gorevler.text = "\n".join(satirlar.slice(1))
	# Kalabalık panelde alt ipucu yer kaplamasın (dokunma/boşluk yine çalışır).
	%SonIpucu.visible = satirlar.size() <= 6
	son_paneli.reset_size()
	son_paneli.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	son_paneli.show()
	%TekrarDugme.grab_focus()


# ------------------------------------------------------------------ v0.3: kip, işaretler, hayalet, başarımlar
func _mod_rekoru(d: Dictionary) -> int:
	if gunluk:
		return int(Gunluk.durum(d)["rekor"])
	return int(d["rekor_rahat"] if rahat else d["rekor"])


func _rekor_metni(r: int) -> String:
	if gunluk:
		return "Günlük rekor: %d m" % r
	return ("Rahat rekor: %d m" if rahat else "Rekor: %d m") % r


func _olum_listesi(d: Dictionary) -> Array:
	if gunluk:
		return Gunluk.durum(d).get("olumler", [])
	return d["olumler_rahat" if rahat else "olumler"]


## Rekor ve son ölüm yerine dünyada işaret koyar.
func _isaretleri_kur(d: Dictionary) -> void:
	for i in _isaretler:
		if is_instance_valid(i):
			i.queue_free()
	_isaretler.clear()
	if bot_modu:
		return
	var olumler := _olum_listesi(d)
	var son := int(olumler[-1]) if not olumler.is_empty() else 0
	if _rekor >= Ayarlar.ISARET_EN_AZ_M:
		_isaret_ekle(_rekor, "REKOR", Color("fee761"), 44.0)
	if son >= Ayarlar.ISARET_EN_AZ_M and absi(son - _rekor) > 3:
		_isaret_ekle(son, "SON", Color("e43b44"), 64.0)


func _isaret_ekle(m: int, metin: String, renk: Color, ust_y: float) -> Isaret:
	var i := Isaret.new()
	i.metin = metin
	i.renk = renk
	i.ust_y = ust_y
	i.position = Vector2(baslangic_x + m * Ayarlar.PIKSEL_METRE, 0.0)
	add_child(i)
	_isaretler.append(i)
	return i


func _hayalet_kur() -> void:
	if is_instance_valid(_hayalet_sprite):
		_hayalet_sprite.queue_free()
	_hayalet_sprite = null
	_hayalet_rakip = null
	_hayalet_kayit = null
	_hayalet_bitti = false
	if not gunluk:
		return
	_hayalet_kayit = Hayalet.new()
	_hayalet_rakip = Hayalet.yukle(Gunluk.bugun())
	if _hayalet_rakip == null or _hayalet_rakip.sayi() < 2:
		_hayalet_rakip = null
		return
	_hayalet_sprite = AnimatedSprite2D.new()
	_hayalet_sprite.name = "HayaletRakip"
	_hayalet_sprite.sprite_frames = oyuncu.gorsel.sprite_frames
	_hayalet_sprite.centered = false
	_hayalet_sprite.offset = oyuncu.gorsel.offset
	_hayalet_sprite.modulate = Color(1.3, 1.7, 2.0, Ayarlar.HAYALET_SAYDAMLIK)
	add_child(_hayalet_sprite)
	# Paralaks arka planın önünde, oyuncunun arkasında çizilsin.
	move_child(_hayalet_sprite, oyuncu.get_index())
	_hayalet_sprite.play("kos")
	_hayalet_adim()


func _hayalet_adim() -> void:
	if _hayalet_kayit:
		var basla := Vector2(baslangic_x, 0.0)
		while _hayalet_kayit.sayi() <= int(sure * Ayarlar.HAYALET_HZ):
			_hayalet_kayit.ekle(oyuncu.global_position - basla, str(oyuncu.gorsel.animation))
	if _hayalet_rakip == null or _hayalet_bitti or not is_instance_valid(_hayalet_sprite):
		return
	if sure > _hayalet_rakip.sure():
		_hayalet_bitti = true
		_hayalet_sprite.visible = false
		var son := _hayalet_rakip.konum(_hayalet_rakip.sure())
		var i := _isaret_ekle(int(son.x / Ayarlar.PIKSEL_METRE), "HAYALET", Color(0.6, 0.9, 1.0), 84.0)
		i.position.x = baslangic_x + son.x
		return
	_hayalet_sprite.global_position = Vector2(baslangic_x, 0.0) + _hayalet_rakip.konum(sure)
	var a := _hayalet_rakip.anim_adi(sure)
	if _hayalet_sprite.animation != a:
		_hayalet_sprite.play(a)


## Alçak tavan ve pistonların arkasında kalanları sayar (başarımlar için).
func _gecisleri_say() -> void:
	var arka := oyuncu.global_position.x - Oyuncu.YARIM_GENISLIK
	while not _tehlike_sirasi.is_empty():
		var t = _tehlike_sirasi[0]
		if not is_instance_valid(t):
			_tehlike_sirasi.pop_front()
			continue
		if (t as Tehlike).global_position.x + (t as Tehlike).genislik >= arka:
			break
		_tehlike_sirasi.pop_front()
		var anahtar := "tavan" if t.tur == Tehlike.Tur.TAVAN else "piston"
		istatistik[anahtar] = int(istatistik[anahtar]) + 1


func _basarimlari_denetle() -> void:
	_basarim_sayac += 1
	if _basarim_sayac % 20 != 0 or bot_modu:
		return
	var d := Kayit.yukle() if _basarim_sayac == 20 or _basarim_onbellek.is_empty() else _basarim_onbellek
	_basarim_onbellek = d
	for b in Basarimlar.anlik(d, istatistik, gunluk, _basarim_bildirilen):
		_basarim_bildirilen.append(b["id"])
		Ses.cal("gorev", 1.2)
		gorev_bildirimi.text = "★ Başarım: %s  +%d altın" % [b["ad"], Ayarlar.BASARIM_ODULU]
		gorev_bildirimi.show()
		gorev_bildirimi.modulate.a = 1.0
		var tw := create_tween()
		tw.tween_interval(1.8)
		tw.tween_property(gorev_bildirimi, "modulate:a", 0.0, 0.5)


# ------------------------------------------------------------------ menüler
func duraklat() -> void:
	if bitti:
		return
	get_tree().paused = true
	duraklat_paneli.show()
	%DevamDugme.grab_focus()


func devam() -> void:
	get_tree().paused = false
	duraklat_paneli.hide()


func menuye_don() -> void:
	get_tree().paused = false
	var tw := create_tween()
	tw.tween_property(gecis, "color:a", 1.0, 0.25)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/menu.tscn"))
