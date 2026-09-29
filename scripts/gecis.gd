class_name GecisKatmani
extends CanvasLayer
## Sahne gecisi (autoload "Gecis"). Gunluk videolardaki gecis aileleri ekran-uzayi shader'i
## ile (assets/gecis.gdshader): iris, glitch, bloklar, itme, perde, flas, kararma, zoom.
## Ortme ~260 ms, acma ~200 ms (stil rehberi). Renkler paletin video akisindan (Tema.AKIS)
## sirayla doner; aile, paletin havuzundan art arda tekrarlanmadan secilir. Bant sirasinda
## ikinci cagri yok sayilir. Duraklatma sirasinda da calisir.
## Hareket azaltma (Ayarlar "Sade gecisler" ya da tarayicida prefers-reduced-motion) acikken
## gecis ANINDA: efekt yok, bekleme yok. Testler `hizli = true` ile ayni yolu kullanir;
## `degistir = false` ise sahne degismez (menu.basla() testte oyun sahnesini ortaya sokmasin).

const ORTME := 0.26
const ACMA := 0.20
const SHADER := preload("res://assets/gecis.gdshader")

static var hizli := false
static var degistir := true
static var sade_ayar := false        ## kayit ayarlari "sade_gecis" (menu ve baslangic yazar)

var son_tur: StringName = &""        ## test/olcum icin: en son kullanilan aile
var acilis_yapildi: bool = false     ## menu acilis iris'i yalniz ilk acilista
var _kaplama: ColorRect
var _mat: ShaderMaterial
var _mesgul: bool = false
var _tween: Tween = null
var _sayac: int = 0                  ## renk akisi sirasi
var _sistem_azalt: bool = false      ## tarayici "hareketi azalt" istiyor


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_kaplama = ColorRect.new()
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_kaplama.material = _mat
	_kaplama.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kaplama.visible = false
	add_child(_kaplama)
	_kaplama.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if OS.has_feature("web"):
		_sistem_azalt = bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches"))
	sade_ayar = bool(Kayit.yukle()["ayarlar"].get("sade_gecis", false))


func mesgul_mu() -> bool:
	return _mesgul


func gorunur_mu() -> bool:
	return _kaplama.visible


## Hareket azaltma: ayar, tarayici ya da test kipi istiyorsa gecis anindadir.
func sade() -> bool:
	return hizli or sade_ayar or _sistem_azalt


## Paletin havuzundan sonraki gecis ailesi (video: gecisHavuz); bir oncekini tekrarlamaz.
func sec(pal: int) -> StringName:
	var havuz: Array = Tema.AKIS[clampi(pal, 0, Tema.AKIS.size() - 1)]["gecis"]
	return havuz[(havuz.find(son_tur) + 1) % havuz.size()]    # havuzu sirayla gezer: tekrar yok, hepsi kullanilir


## Ortme oncesi: shader'i bu gecisin tur ve renkleriyle kurar. Kaplama acma (ac)
## cagrilana kadar ayni renkte durur. `ozel` (alfa > 0) ilk rengi belirler (ornek: olum flasi pembe).
func _kur(tur: StringName, pal: int, ozel: Color = Color(0, 0, 0, 0)) -> void:
	if tur == &"":
		tur = sec(pal)
	son_tur = tur
	var a: Dictionary = Tema.AKIS[clampi(pal, 0, Tema.AKIS.size() - 1)]
	var r1: Color = Tema.akis_rengi(pal, _sayac)
	var r2: Color = Tema.akis_rengi(pal, _sayac + 2)
	if tur == &"flas":
		r1 = a["acik"]
	elif tur == &"kararma":
		r1 = a["koyu"]
	if ozel.a > 0.0:
		r1 = Color(ozel, 1.0)
	_sayac += 1
	_mat.set_shader_parameter("tur", maxi(Tema.GECIS_TURLERI.find(tur), 0))
	_mat.set_shader_parameter("renk", r1)
	_mat.set_shader_parameter("renk2", r2)
	var boyut := get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("oran", boyut.x / maxf(boyut.y, 1.0))
	_mat.set_shader_parameter("p", 0.0)


func _p_yaz(v: float) -> void:
	_mat.set_shader_parameter("p", v)
	_mat.set_shader_parameter("adim", floorf(Time.get_ticks_msec() / 33.0))


## Ekrani orter (await edilebilir). Sade kipte hicbir sey yapmaz ve bekletmez.
func kapat(tur: StringName = &"", pal: int = 0, sure: float = ORTME) -> void:
	if sade():
		return
	_kur(tur, pal)
	_kaplama.visible = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_method(_p_yaz, 0.0, 1.0, sure)
	await _tween.finished


## Ortuyu acar; bekletmek istemeyen cagiran await etmez (oyun akisi surer).
func ac(sure: float = ACMA, baslangic: float = 1.0) -> void:
	if not _kaplama.visible:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_method(_p_yaz, baslangic, 0.0, sure)
	await _tween.finished
	_kaplama.visible = false


## Kapali basla, ac: menu acilisi, duraklatma perdesi, olum flasi gibi "icerik acilir" anlari.
## Sahne gecisi surerken (git/ara) yok sayilir: onun tween'i oldurulup takilmasin.
func acilis(tur: StringName = &"iris", pal: int = 0, sure: float = ACMA + 0.1, baslangic: float = 1.0, ozel: Color = Color(0, 0, 0, 0)) -> void:
	if sade() or _mesgul:
		return
	_kur(tur, pal, ozel)
	_kaplama.visible = true
	_p_yaz(baslangic)
	await ac(sure, baslangic)


## Yerinde gecis: ort, `degistir`i cagir (metin/sahne degisimi), ac.
func ara(tur: StringName, pal: int, degistir_fn: Callable) -> void:
	if _mesgul:
		return
	_mesgul = true
	await kapat(tur, pal, ORTME * 0.7)
	degistir_fn.call()
	if not sade():
		await get_tree().process_frame
		await get_tree().process_frame
	await ac(ACMA)
	_mesgul = false


## Sahneyi degistirir. Bant sirasinda ikinci cagri yok sayilir (cift tik).
func git(yol: String, pal: int = 0, tur: StringName = &"") -> void:
	if _mesgul:
		return
	_mesgul = true
	if sade():
		if degistir:
			get_tree().change_scene_to_file(yol)
		_mesgul = false
		return
	await kapat(tur, pal)
	if degistir:
		get_tree().change_scene_to_file(yol)
	await get_tree().process_frame
	await get_tree().process_frame
	await ac(ACMA)
	_mesgul = false
