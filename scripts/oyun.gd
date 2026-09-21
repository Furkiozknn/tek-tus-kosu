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
var ritim := false                    ## Ritim koşusu (menüden Ritim.secili ile gelir)
var ritim_sarki := -1                 ## Ritim şarkısı (-1: menüden Ritim.sarki)
var ritim_gunluk := false             ## Günün ritmi (tarihten tohum + şarkı; menüden Ritim.gunluk_secili)

const TEMALAR := [
	{"ad": "Akşam", "ust": Color("68386c"), "alt": Color("f77622"), "uzak": Color(1, 0.85, 0.8), "yakin": Color(1, 0.9, 0.9), "yildiz": 0.3, "yagis": false},
	{"ad": "Gece", "ust": Color("181425"), "alt": Color("262b44"), "uzak": Color(1, 1, 1), "yakin": Color(1, 1, 1), "yildiz": 1.0, "yagis": false},
	{"ad": "Yağış", "ust": Color("262b44"), "alt": Color("5a6988"), "uzak": Color(0.75, 0.8, 0.9), "yakin": Color(0.8, 0.85, 0.95), "yildiz": 0.0, "yagis": true},
	{"ad": "Neon", "ust": Color("181425"), "alt": Color("b55088"), "uzak": Color(0.9, 0.7, 1.0), "yakin": Color(1.0, 0.75, 1.0), "yildiz": 0.6, "yagis": false},
	# v1.5: yalnız şarkı kilidiyle (Ritim.SARKILAR[i].tema) gelir, normal koşu döngüsüne girmez (TEMA_DONGU)
	{"ad": "Fırtına", "ust": Color("14162b"), "alt": Color("3a4466"), "uzak": Color(0.6, 0.65, 0.82), "yakin": Color(0.68, 0.74, 0.9), "yildiz": 0.0, "yagis": true, "simsek": true},
]
const TEMA_DONGU := 4                 ## normal koşuda mesafeyle dönen tema sayısı (ilk 4)
const SIMSEK_OLASILIK := 0.4          ## fırtına temasında her 2 ölçüde bir şimşek olasılığı

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
var _izgara0 := 0.0                     ## ritim: 0. vuruşun dünya x'i (ses gecikmesi dahil)
var _ritim_olcu := 0
var _ritim_son := -1
var _ritim_olaylar := {}                ## ritim: henüz değerlendirilmemiş zıplama vuruşları
var _ritim_seri := 0
var _ritim_bas_x := 0.0                 ## ritim: müziğin başladığı andaki oyuncu x'i
var _ritim_ses_onceki := -1.0            ## ritim: son okunan müzik konumu (döngü sayımı için)
var _ritim_ses_tur := 0
var _ritim_kayma_kare := 0
var _adim := Ritim.ADIM                 ## ritim: bu şarkıda vuruş aralığı (px)
var _ritim_sapmalar: Array[float] = []  ## ritim: değerlendirilen zıplamaların sapması (ms, + geç)
var _gecikme_onerisi: Variant = null
var _ritim_ipucu := true                ## ritim: zıplama vuruşundan bir vuruş önce tık sesi (ayar)
var _ritim_vurus_k := -999999           ## ritim: son geçilen vuruş indeksi
var _simsek_rng := RandomNumberGenerator.new()   ## şimşek zamanlaması (parça dizisinden bağımsız)
var _simsek_rect: ColorRect                       ## şimşek perdesi (gökyüzü katmanında, çalışma anında kurulur)
var _simsek_sayisi := 0                           ## test/istatistik: bu koşuda çakan şimşek
var _ritim_ipucu_sayisi := 0            ## ritim: çalınan ipucu sesi sayısı (test)


func _ready() -> void:
	Simgeler.kur()
	add_to_group("oyun")
	var du := DikeyUyari.new()
	add_child(du)
	du.dikey_oldu.connect(_dikey_oldu)
	ritim = ritim or Ritim.secili
	ritim_gunluk = ritim and (ritim_gunluk or Ritim.gunluk_secili)
	if ritim_gunluk:
		ritim_sarki = Ritim.gunun_sarkisi(Gunluk.bugun())
	elif ritim_sarki < 0:
		ritim_sarki = Ritim.sarki
	ritim_sarki = clampi(ritim_sarki, 0, Ritim.SARKILAR.size() - 1)
	_adim = Ritim.adim(ritim_sarki)
	gunluk = (gunluk or Gunluk.secili) and not ritim
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
	%PaylasDugme.pressed.connect(_paylas)
	%GecikmeDugme.pressed.connect(gecikme_uygula)
	yeniden_baslat()


## Koşuyu sahneyi yeniden yüklemeden sıfırlar (< 1 sn).
func yeniden_baslat() -> void:
	get_tree().paused = false
	var d := Kayit.yukle()
	var ayar: Dictionary = d["ayarlar"]
	rahat = bool(ayar["rahat"]) and not bot_modu and not gunluk and not ritim
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
	elif ritim_gunluk:
		parca_rng.seed = Ritim.gunun_tohumu(Gunluk.bugun())
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
	oyuncu.iz_acik = not bot_modu
	oyuncu.kostum_uygula(str(d["kostum"]))
	oyuncu.sifirla(Vector2(100.0, Ayarlar.ZEMIN_Y))
	oyuncu.hiz = _hiz_hesapla()
	baslangic_x = oyuncu.global_position.x
	var gecikme := clampi(int(ayar.get("ritim_gecikme", 0)), Ritim.GECIKME_ARALIK.x, Ritim.GECIKME_ARALIK.y)
	_izgara0 = baslangic_x + Ritim.HIZ * (AudioServer.get_output_latency() + gecikme / 1000.0)
	_ritim_sapmalar.clear()
	_gecikme_onerisi = null
	_ritim_ipucu = bool(ayar.get("ritim_ipucu", true)) and not bot_modu
	_ritim_vurus_k = -999999
	_ritim_ipucu_sayisi = 0
	_simsek_sayisi = 0
	_simsek_rng.seed = tohum if tohum >= 0 else int(Time.get_ticks_usec())
	if _simsek_rect:
		_simsek_rect.color.a = 0.0
	_ritim_olcu = 0
	_ritim_son = -1
	_ritim_olaylar.clear()
	_ritim_seri = 0
	_ritim_bas_x = baslangic_x
	_ritim_ses_onceki = -1.0
	_ritim_ses_tur = 0
	_ritim_kayma_kare = 0
	altin_etiketi.text = "0"
	mesafe_etiketi.text = "0 m"
	duraklat_paneli.hide()
	son_paneli.hide()
	tekrar_etiketi.hide()
	gorev_bildirimi.hide()
	ipucu.visible = not bot_modu
	if ritim:
		ipucu.text = "Müziği dinle: sarı oklu lambaya vuruşta basınca zıpla\nKısa dokunuş: alçak tavanın altından geç"

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
		_bot.ruzgar = ruzgar_gucu
	%RuzgarEtiketi.hide()
	if ritim:
		Ses.muzik(str(Ritim.SARKILAR[ritim_sarki]["muzik"]), true)  # vuruş ızgarası müziğin başıyla hizalı
	elif not bot_modu:
		Ses.muzik("muzik_oyun")
	gecis.color.a = 1.0
	create_tween().tween_property(gecis, "color:a", 0.0, 0.35)


func _hiz_hesapla() -> float:
	if ritim and sabit_hiz < 0.0:
		return Ritim.HIZ
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
	oyuncu.ruzgar = ruzgar_gucu(oyuncu.global_position.x)
	_ruzgar_etiketi_guncelle()
	if _bot:
		_bot.adim()
	_parcalari_guncelle()
	_kamera_guncelle()
	var m := mesafe()
	istatistik["mesafe"] = m
	mesafe_etiketi.text = "%d m" % m
	if ipucu.visible and sure > (7.0 if ritim else 4.0):
		ipucu.hide()
	_altin_seri = maxf(_altin_seri - delta, 0.0)
	_gecisleri_say()
	_gorevleri_denetle()
	_basarimlari_denetle()
	_hayalet_adim()
	_tema_guncelle(false)
	if ritim:
		RitimIsaret.faz = fposmod((oyuncu.global_position.x - _izgara0) / _adim, 1.0)
		_ritim_kacanlar()
		_ritim_ses_hizala()
		_ritim_ipucu_sesi()


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
	if ritim and not ikinci and not bitti:
		_ritim_degerlendir()
	if ikinci:
		istatistik["ikinci"] = int(istatistik["ikinci"]) + 1
		Ses.cal("ikinci")
		_parcacik(oyuncu.global_position, Kostumler.toz_rengi(oyuncu.kostum, Color("c0cbdc")), 6, 70.0, 0.25)
	else:
		Ses.cal("zipla")
		_parcacik(oyuncu.global_position, Kostumler.toz_rengi(oyuncu.kostum, Color("8b9bb4")), 5, 40.0, 0.25)


func _indi() -> void:
	Ses.cal("indi")
	_parcacik(oyuncu.global_position, Kostumler.toz_rengi(oyuncu.kostum, Color("8b9bb4")), 6, 45.0, 0.3)


func iskele_catirdadi(iskele: Node2D) -> void:
	if bitti:
		return
	Ses.cal("catirti")
	_parcacik(Vector2(oyuncu.global_position.x, iskele.global_position.y), Color("b86f50"), 4, 30.0, 0.3)


func iskele_coktu(iskele: Node2D) -> void:
	Ses.cal("indi", 0.55)
	var w: float = iskele.get("genislik")
	for i in 3:
		_parcacik(iskele.global_position + Vector2(w * (0.2 + 0.3 * i), 4), Color("733e39"), 4, 40.0, 0.4)


## Ritim: zıplama bir olay vuruşuna ne kadar yakın?
func _ritim_degerlendir() -> void:
	var vk := Ritim.vurus_konumu(oyuncu.global_position.x, _izgara0, _adim)
	var n: int = vk[0]
	var ms: float = vk[1]
	if not _ritim_olaylar.has(n):
		return
	_ritim_olaylar.erase(n)
	if absf(ms) < 250.0:
		_ritim_sapmalar.append(ms)
	var yer := oyuncu.global_position + Vector2(0, -40)
	if absf(ms) <= Ritim.TAM_VURUS_MS:
		_ritim_seri += 1
		istatistik["ritim"] = int(istatistik["ritim"]) + 1
		_yazi(yer, "Tam vuruş" + (" ×%d" % _ritim_seri if _ritim_seri > 1 else ""), Color("fee761"))
		Ses.cal("tik", 1.0 + minf(_ritim_seri, 8) * 0.06)
	else:
		_ritim_seri = 0
		_yazi(yer, "%s %d ms" % ["Erken" if ms < 0.0 else "Geç", int(round(absf(ms)))], Color("c0cbdc"))


## Ritim: müzik oyun zamanından kaydıysa (sekme gizlendi, uzun takılma) müziği oyuna göre sar.
## Oyun yetkili: fizik ve dünya belirlenimci kalır; yalnız ses konumu düzeltilir.
func _ritim_ses_hizala() -> void:
	var t := Ses.muzik_konumu()
	var uzunluk := Ses.muzik_uzunlugu()
	if t < 0.0 or uzunluk <= 0.0:
		return
	if _ritim_ses_onceki >= 0.0 and t < _ritim_ses_onceki - uzunluk * 0.5:
		_ritim_ses_tur += 1
	_ritim_ses_onceki = t
	var oyun_t := (oyuncu.global_position.x - _ritim_bas_x) / Ritim.HIZ
	var fark := _ritim_ses_tur * uzunluk + t - oyun_t
	_ritim_kayma_kare = _ritim_kayma_kare + 1 if absf(fark) > Ritim.SES_KAYMA_SN else 0
	if _ritim_kayma_kare >= 6:
		_ritim_kayma_kare = 0
		var hedef := fposmod(oyun_t, uzunluk)
		_ritim_ses_tur = int(floor(oyun_t / uzunluk))
		_ritim_ses_onceki = hedef
		Ses.muzik_sar(hedef)


## Ritim: bir sonraki vuruş zıplama vuruşuysa bu vuruşta (bir vuruş önceden) tık çal — sayım gibi.
func _ritim_ipucu_sesi() -> void:
	var k := int(floor((oyuncu.global_position.x - _izgara0) / _adim))
	if k == _ritim_vurus_k:
		return
	_ritim_vurus_k = k
	if _ritim_ipucu and _ritim_olaylar.has(k + 1):
		_ritim_ipucu_sayisi += 1
		Ses.cal("tik", 0.7)
	# v1.5: fırtına temasında iki ölçüde bir, ölçü başında şimşek (yalnız görsel; sarsıntı ayarı kapalıysa yok)
	if k >= 0 and k % (Ritim.OLCU * 2) == 0 and tema >= 0 and bool(TEMALAR[tema].get("simsek", false)) \
			and sarsinti_acik and _simsek_rng.randf() < SIMSEK_OLASILIK:
		_simsek()


## Kısa beyaz perde: 0,45 alfa → 0, 320 ms, güçlü ease-out (giriş yok, ışık anında çakar).
func _simsek() -> void:
	if _simsek_rect == null:
		_simsek_rect = ColorRect.new()
		_simsek_rect.name = "Simsek"
		_simsek_rect.color = Color(0.9, 0.95, 1.0, 0.0)
		_simsek_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_simsek_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		gok.get_parent().add_child(_simsek_rect)
	_simsek_sayisi += 1
	_simsek_rect.color.a = 0.45
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_simsek_rect, "color:a", 0.0, 0.32)


## Ritim: zıplanmadan (ya da çok erken/geç zıplanarak) geçilen vuruşlar seriyi bozar.
func _ritim_kacanlar() -> void:
	var sinir := (oyuncu.global_position.x - _izgara0) / _adim - 0.5
	for k in _ritim_olaylar.keys():
		if k < sinir:
			_ritim_olaylar.erase(k)
			_ritim_seri = 0


func _ruzgar_etiketi_guncelle() -> void:
	var r := oyuncu.ruzgar
	var e: Label = %RuzgarEtiketi
	if absf(r) < 1.0:
		e.hide()
		return
	e.text = "← karşı rüzgâr" if r < 0.0 else "arka rüzgâr →"
	e.add_theme_color_override("font_color", Color("f6757a") if r < 0.0 else Color("2ce8f5"))
	e.show()


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


func dunya_ruzgar_araliklari() -> Array:
	var sonuc: Array = []
	for p in parcalar:
		for r in p.ruzgar_araliklari():
			sonuc.append([r[0] + p.position.x, r[1] + p.position.x, r[2]])
	return sonuc


## x noktasındaki rüzgâr gücü (rahat modda hızla aynı oranda).
func ruzgar_gucu(x: float) -> float:
	for p in parcalar:
		if x < p.position.x or x > p.position.x + p.uzunluk:
			continue
		for r in p.ruzgar_araliklari():
			if x >= r[0] + p.position.x and x <= r[1] + p.position.x:
				return float(r[2]) * (Ayarlar.RAHAT_MOD_CARPANI if rahat else 1.0)
	return 0.0


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
		if ritim and parca_sirasi.is_empty():
			_ritim_parcasi_ekle()
		else:
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
	_parca_yerlestir(_sahneler[yol].instantiate())


func _ritim_parcasi_ekle() -> void:
	var r := Ritim.parca_uret(sonraki_x, _izgara0, parca_rng, _ritim_olcu, _ritim_son, _adim, ritim_sarki)
	_ritim_olcu += Ritim.PARCA_OLCU
	_ritim_son = r[1]
	for k in r[2]:
		_ritim_olaylar[k] = true
	_parca_yerlestir(r[0])


func _parca_yerlestir(p: Parca) -> void:
	p.position = Vector2(sonraki_x, 0.0)
	dunya.add_child(p)
	parcalar.append(p)
	sonraki_x += p.uzunluk
	for c in p.get_children():
		if c is Coken or (c is Tehlike and (c.tur == Tehlike.Tur.TAVAN or c.tur == Tehlike.Tur.PISTON)):
			_tehlike_sirasi.append(c)


func _kamera_guncelle() -> void:
	var hedef: Vector2 = oyuncu.global_position if _tekrar_hayalet == null else _tekrar_hayalet.global_position
	kamera.global_position = Vector2(hedef.x - Ayarlar.OYUNCU_EKRAN_X + 320.0, 180.0)


# ------------------------------------------------------------------ görsel
## Şarkıya kilitli tema (Fırtına Hattı → Fırtına); yoksa mesafeyle dönen ilk TEMA_DONGU tema.
func _tema_secimi() -> int:
	if ritim:
		var kilit: int = int(Ritim.SARKILAR[ritim_sarki].get("tema", -1))
		if kilit >= 0 and kilit < TEMALAR.size():
			return kilit
	return int(mesafe() / Ayarlar.TEMA_ARALIGI_M) % TEMA_DONGU


func _tema_guncelle(aninda: bool) -> void:
	var yeni := _tema_secimi()
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
	var anahtar := _ritim_anahtar("rekor") if ritim else ("rekor_rahat" if rahat else "rekor")
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
		if ritim_gunluk:
			Ritim.gunluk_isle(d, m)
			if yeni_rekor and _hayalet_kayit:
				_hayalet_kayit.tarih = Gunluk.bugun()
				_hayalet_kayit.mesafe = m
				_hayalet_kayit.kaydet("ritim")
		elif gunluk:
			Gunluk.kosu_isle(d, m)
			Gunluk.seri_isle(d)
			if yeni_rekor and _hayalet_kayit:
				_hayalet_kayit.tarih = Gunluk.bugun()
				_hayalet_kayit.mesafe = m
				_hayalet_kayit.kaydet()
		else:
			var liste: Array = d[_ritim_anahtar("olumler") if ritim else ("olumler_rahat" if rahat else "olumler")]
			liste.append(m)
			while liste.size() > Ayarlar.OLUM_ISARETI_SAYISI:
				liste.pop_front()
		gorev_sonuc = Gorevler.kosu_sonu(d, istatistik, rng)
		basarimlar = Basarimlar.denetle(d, istatistik, gunluk)
		Kayit.kaydet(d)
	son_sonuc = {"mesafe": m, "yeni_rekor": yeni_rekor, "rekor": maxi(onceki_rekor, m), "gorev": gorev_sonuc,
		"gorevler": d["gorevler"], "seviye": int(d["gorev_seviyesi"]), "olumler": onceki_olumler,
		"basarimlar": basarimlar, "deneme": _gunluk_deneme(d),
		"seri": Gunluk.seri(d) if gunluk else 0}
	if ritim:
		var toplam := 0.0
		for m2 in _ritim_sapmalar:
			toplam += m2
		son_sonuc["ritim_sapma"] = toplam / _ritim_sapmalar.size() if not _ritim_sapmalar.is_empty() else 0.0
		son_sonuc["ritim_sapma_sayi"] = _ritim_sapmalar.size()
		_gecikme_onerisi = Ritim.gecikme_onerisi(int(d["ayarlar"].get("ritim_gecikme", 0)), _ritim_sapmalar)
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
	if gunluk or ritim_gunluk:
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
	satirlar.append("Altın: %d" % altin + ("   Ödül: +%d" % ek_odul if ek_odul > 0 else "")
			+ ("   Tam vuruş: %d" % int(istatistik["ritim"]) if ritim else "")
			+ ("   Ort. sapma: %+d ms" % int(round(float(s.get("ritim_sapma", 0.0)))) if ritim and int(s.get("ritim_sapma_sayi", 0)) > 0 else ""))
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
	# Günlük koşuda üç düğme: Tekrar | Paylaş | Menü. Ritimde gecikme önerisi varsa: Tekrar | Gecikme | Menü
	%PaylasDugme.visible = gunluk or ritim_gunluk
	%PaylasDugme.text = "Paylaş"
	var gd: Button = %GecikmeDugme
	gd.visible = ritim and _gecikme_onerisi != null
	gd.disabled = false
	if gd.visible:
		gd.text = "Gecikme %+d ms" % int(_gecikme_onerisi)
		gd.tooltip_text = "Zıplamaların vuruştan ortalama %+d ms uzakta. Ses gecikmesi ayarını buna göre değiştir." % int(round(float(s.get("ritim_sapma", 0.0))))
	var dugme_sayisi := 2 + int(%PaylasDugme.visible) + int(gd.visible)
	var genislik := 150.0 if dugme_sayisi == 2 else (110.0 if dugme_sayisi == 3 else 96.0)
	for b in [%PaylasDugme, gd]:
		b.custom_minimum_size.x = genislik
	%TekrarDugme.custom_minimum_size.x = genislik
	%SonMenuDugme.custom_minimum_size.x = genislik
	son_paneli.reset_size()
	son_paneli.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	son_paneli.show()
	%TekrarDugme.grab_focus()


## Ritim: önerilen ses gecikmesini ayara yaz (sonraki koşuda geçerli).
func gecikme_uygula() -> void:
	if _gecikme_onerisi == null:
		return
	Kayit.ayar_yaz("ritim_gecikme", int(_gecikme_onerisi))
	Ses.cal("tik")
	var gd: Button = %GecikmeDugme
	gd.text = "Ayarlandı ✓"
	gd.disabled = true
	_gecikme_onerisi = null


func _gunluk_deneme(d: Dictionary) -> int:
	if ritim_gunluk:
		return int(Ritim.gunluk_durum(d)["deneme"])
	return int(Gunluk.durum(d)["deneme"]) if gunluk else 0


func _ritim_anahtar(tur: String) -> String:
	return str(Ritim.SARKILAR[ritim_sarki][tur])


# ------------------------------------------------------------------ v0.4: paylaşım
func paylasim_metni() -> String:
	var s := son_sonuc
	if ritim_gunluk:
		return Gunluk.paylasim_metni(Gunluk.bugun(), int(s.get("mesafe", 0)), int(s.get("deneme", 0)),
				int(s.get("rekor", 0)), bool(s.get("yeni_rekor", false)), 0,
				"Günün ritmi (%s)" % Ritim.SARKILAR[ritim_sarki]["ad"])
	return Gunluk.paylasim_metni(Gunluk.bugun(), int(s.get("mesafe", 0)), int(s.get("deneme", 0)),
			int(s.get("rekor", 0)), bool(s.get("yeni_rekor", false)), int(s.get("seri", 0)))


## Telefonda tarayıcının paylaşım menüsü, diğer durumlarda panoya kopyalama.
func _paylas() -> void:
	var metin := paylasim_metni()
	var paylasildi := false
	if OS.has_feature("web"):
		var js := "(navigator.share && navigator.maxTouchPoints > 0) ? (navigator.share({text: %s}).catch(function(){}), true) : false" % JSON.stringify(metin)
		# JS true/false web'de 1/0 (int) olarak dönebiliyor; int == bool çalışma zamanı hatası verir.
		paylasildi = str(JavaScriptBridge.eval(js, true)) in ["true", "1"]
	if not paylasildi:
		DisplayServer.clipboard_set(metin)
	Ses.cal("tik")
	var dg: Button = %PaylasDugme
	dg.text = "Paylaşıldı ✓" if paylasildi else "Kopyalandı ✓"
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_callback(func() -> void: dg.text = "Paylaş")


# ------------------------------------------------------------------ v0.3: kip, işaretler, hayalet, başarımlar
func _mod_rekoru(d: Dictionary) -> int:
	if gunluk:
		return int(Gunluk.durum(d)["rekor"])
	if ritim_gunluk:
		return int(Ritim.gunluk_durum(d)["rekor"])
	if ritim:
		return int(d[_ritim_anahtar("rekor")])
	return int(d["rekor_rahat"] if rahat else d["rekor"])


func _rekor_metni(r: int) -> String:
	if gunluk:
		return "Günlük rekor: %d m" % r
	if ritim_gunluk:
		return "Günün ritmi rekoru: %d m" % r
	if ritim:
		return "%s rekoru: %d m" % [Ritim.SARKILAR[ritim_sarki]["ad"], r]
	return ("Rahat rekor: %d m" if rahat else "Rekor: %d m") % r


func _olum_listesi(d: Dictionary) -> Array:
	if gunluk:
		return Gunluk.durum(d).get("olumler", [])
	if ritim_gunluk:
		return Ritim.gunluk_durum(d).get("olumler", [])
	return d[_ritim_anahtar("olumler") if ritim else ("olumler_rahat" if rahat else "olumler")]


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
	if not (gunluk or ritim_gunluk):
		return
	_hayalet_kayit = Hayalet.new()
	_hayalet_rakip = Hayalet.yukle(Gunluk.bugun(), _hayalet_turu())
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


## Günün ritminde hayalet vuruş ızgarasına göre kaydedilir: engeller ızgaraya bağlı olduğundan
## başka ses gecikmesiyle oynayanda da hayalet engelin üstünde zıplar.
func _hayalet_taban() -> Vector2:
	return Vector2(_izgara0 if ritim_gunluk else baslangic_x, 0.0)


func _hayalet_turu() -> String:
	return "ritim" if ritim_gunluk else ""


func _hayalet_adim() -> void:
	if _hayalet_kayit:
		var basla := _hayalet_taban()
		while _hayalet_kayit.sayi() <= int(sure * Ayarlar.HAYALET_HZ):
			_hayalet_kayit.ekle(oyuncu.global_position - basla, str(oyuncu.gorsel.animation))
	if _hayalet_rakip == null or _hayalet_bitti or not is_instance_valid(_hayalet_sprite):
		return
	if sure > _hayalet_rakip.sure():
		_hayalet_bitti = true
		_hayalet_sprite.visible = false
		var son := _hayalet_rakip.konum(_hayalet_rakip.sure())
		var i := _isaret_ekle(int(son.x / Ayarlar.PIKSEL_METRE), "HAYALET", Color(0.6, 0.9, 1.0), 84.0)
		i.position.x = _hayalet_taban().x + son.x
		return
	_hayalet_sprite.global_position = _hayalet_taban() + _hayalet_rakip.konum(sure)
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
		var son_x: float = (t as Node2D).global_position.x + float(t.get("genislik"))
		if son_x >= arka:
			break
		_tehlike_sirasi.pop_front()
		var anahtar := "iskele" if t is Coken else ("tavan" if t.tur == Tehlike.Tur.TAVAN else "piston")
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
## Telefon dikeye çevrildi: koşu sürüyorsa duraklat (yatay dönünce Devam'a basılır).
func _dikey_oldu() -> void:
	if not bitti and not get_tree().paused and not bot_modu:
		duraklat()


func duraklat() -> void:
	if bitti:
		return
	get_tree().paused = true
	if ritim:
		Ses.muzik_duraklat(true)
	duraklat_paneli.show()
	%DevamDugme.grab_focus()


func devam() -> void:
	get_tree().paused = false
	Ses.muzik_duraklat(false)
	duraklat_paneli.hide()


func menuye_don() -> void:
	get_tree().paused = false
	var tw := create_tween()
	tw.tween_property(gecis, "color:a", 1.0, 0.25)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/menu.tscn"))
