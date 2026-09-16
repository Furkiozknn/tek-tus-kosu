extends Node2D
## Sonsuz koşu oyun sahnesi: parça üretimi, hız artışı, puan, duraklatma, oyun sonu.

signal kosu_bitti(mesafe: int, altin: int)

# --- Test / demo ayarları (normal oyunda dokunulmaz) ---
var bot_modu := false
var sabit_hiz := -1.0                 ## >= 0 ise hız artmaz
var parca_sirasi: Array[String] = []  ## Boş değilse parçalar bu sırayla gelir, sonra düz zemin
var tohum := -1                       ## >= 0 ise rastgelelik sabit
var sira_bitince_duz := false         ## Test: sıra bitince yalnız düz zemin gelsin
var kayit_yap := true

@onready var dunya: Node2D = $Dunya
@onready var oyuncu: Oyuncu = $Oyuncu
@onready var kamera: Camera2D = $Kamera
@onready var mesafe_etiketi: Label = %Mesafe
@onready var altin_etiketi: Label = %AltinSayisi
@onready var rekor_etiketi: Label = %Rekor
@onready var ipucu: Label = %Ipucu
@onready var duraklat_paneli: Control = %DuraklatPaneli
@onready var son_paneli: Control = %SonPaneli
@onready var son_skor: Label = %SonSkor
@onready var son_rekor: Label = %SonRekor
@onready var son_altin: Label = %SonAltin

var rng := RandomNumberGenerator.new()
var parcalar: Array[Parca] = []
var sonraki_x := 0.0
var baslangic_x := 0.0
var sure := 0.0
var altin := 0
var bitti := false
var _yeniden_baslat_izni := 0.0
var _son_parca := ""
var _sahneler := {}
var _bot: Bot
var _rekor := 0


func _ready() -> void:
	add_to_group("oyun")
	if tohum >= 0:
		rng.seed = tohum
	else:
		rng.randomize()
	for yol in ParcaListesi.YOLLAR:
		_sahneler[yol] = load(yol)

	_rekor = int(Kayit.yukle()["rekor"])
	rekor_etiketi.text = "Rekor: %d m" % _rekor
	oyuncu.global_position = Vector2(100.0, Ayarlar.ZEMIN_Y)
	oyuncu.hiz = Ayarlar.HIZ_BAS if sabit_hiz < 0.0 else sabit_hiz
	oyuncu.oldu.connect(_oyuncu_oldu)
	baslangic_x = oyuncu.global_position.x

	# Başlangıçta iki düz parça: ısınma alanı.
	_parca_ekle(ParcaListesi.DUZ)
	_parca_ekle(ParcaListesi.DUZ)
	_kamera_guncelle()
	_parcalari_guncelle()

	%DuraklatDugme.pressed.connect(duraklat)
	%DevamDugme.pressed.connect(devam)
	%MenuDugme.pressed.connect(menuye_don)
	%TekrarDugme.pressed.connect(yeniden_baslat)
	%SonMenuDugme.pressed.connect(menuye_don)
	duraklat_paneli.hide()
	son_paneli.hide()

	if bot_modu:
		_bot = Bot.new(oyuncu, dunya_tehlike_araliklari)
		ipucu.hide()


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	if bitti:
		_yeniden_baslat_izni -= delta
		return
	sure += delta
	if sabit_hiz < 0.0:
		oyuncu.hiz = minf(Ayarlar.HIZ_BAS + Ayarlar.HIZ_ARTIS * sure, Ayarlar.HIZ_AZAMI)
	if _bot:
		_bot.adim()
	_parcalari_guncelle()
	_kamera_guncelle()
	mesafe_etiketi.text = "%d m" % mesafe()
	if ipucu.visible and sure > 4.0:
		ipucu.hide()


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
		if basildi and _yeniden_baslat_izni <= 0.0:
			yeniden_baslat()
		return
	if basildi:
		oyuncu.zipla_bas()
	else:
		oyuncu.zipla_birak()


func mesafe() -> int:
	return int((oyuncu.global_position.x - baslangic_x) / Ayarlar.PIKSEL_METRE)


func altin_toplandi() -> void:
	altin += 1
	altin_etiketi.text = str(altin)


## Tüm canlı parçaların tehlike aralıkları, dünya koordinatında.
func dunya_tehlike_araliklari() -> Array:
	var sonuc: Array = []
	for p in parcalar:
		for a in p.tehlike_araliklari():
			sonuc.append(a + Vector2(p.position.x, p.position.x))
	return sonuc


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
	var hiz := oyuncu.hiz
	var adaylar: Array[String] = []
	var agirliklar: Array[float] = []
	for yol in ParcaListesi.YOLLAR:
		var z: int = ParcaListesi.ZORLUK[yol]
		if hiz < Ayarlar.zorluk_esigi(z) or yol == _son_parca:
			continue
		adaylar.append(yol)
		# Hız arttıkça zor parçalar daha sık gelsin.
		agirliklar.append(1.0 + (z - 1) * clampf((hiz - Ayarlar.HIZ_BAS) / 120.0, 0.0, 2.0))
	var secim := adaylar[rng.rand_weighted(PackedFloat32Array(agirliklar))]
	_son_parca = secim
	return secim


func _parca_ekle(yol: String) -> void:
	var p: Parca = _sahneler[yol].instantiate()
	p.position = Vector2(sonraki_x, 0.0)
	dunya.add_child(p)
	parcalar.append(p)
	sonraki_x += p.uzunluk


func _kamera_guncelle() -> void:
	kamera.global_position = Vector2(oyuncu.global_position.x - Ayarlar.OYUNCU_EKRAN_X + 320.0, 180.0)


func _oyuncu_oldu() -> void:
	bitti = true
	_yeniden_baslat_izni = 0.5
	var m := mesafe()
	var d := {"rekor": maxi(_rekor, m), "yeni_rekor": m > _rekor}
	if kayit_yap:
		d = Kayit.kosu_kaydet(m, altin)
	son_skor.text = "Mesafe: %d m" % m
	son_rekor.text = ("YENİ REKOR!" if d["yeni_rekor"] else "Rekor: %d m" % d["rekor"])
	son_altin.text = "Altın: %d" % altin
	son_paneli.show()
	%TekrarDugme.grab_focus()
	kosu_bitti.emit(m, altin)


func duraklat() -> void:
	if bitti:
		return
	get_tree().paused = true
	duraklat_paneli.show()
	%DevamDugme.grab_focus()


func devam() -> void:
	get_tree().paused = false
	duraklat_paneli.hide()


func yeniden_baslat() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func menuye_don() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
