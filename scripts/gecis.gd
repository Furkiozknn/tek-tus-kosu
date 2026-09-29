class_name GecisKatmani
extends CanvasLayer
## Sahne gecisi (autoload "Gecis"): tam ekran renk bandi soldan girer (~260 ms),
## sahne degisir, bant saga cikar (~200 ms). Stil rehberi: pembe bant (videodaki
## pembe kart). Duraklatma sirasinda da calisir. Testler `hizli = true` ile bekleme
## surelerini sifirlar.

const ORTME := 0.26
const ACMA := 0.20
const GENISLIK := 660.0

static var hizli := false
## Testler: false ise bant oynar ama sahne degismez (menu.basla() testte oyun sahnesini ortaya sokmasin).
static var degistir := true

var _bant: ColorRect
var _mesgul := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bant = ColorRect.new()
	_bant.color = Tema.PEMBE
	_bant.size = Vector2(GENISLIK, 380.0)
	_bant.position = Vector2(-GENISLIK, -10.0)
	_bant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bant.visible = false
	add_child(_bant)


func mesgul_mu() -> bool:
	return _mesgul


## Sahneyi bantla degistirir. Bant sirasinda ikinci cagri yok sayilir (cift tik).
func git(yol: String, renk: Color = Tema.PEMBE) -> void:
	if _mesgul:
		return
	_mesgul = true
	await kapat(renk)
	if degistir:
		get_tree().change_scene_to_file(yol)
	await get_tree().process_frame
	await get_tree().process_frame
	await ac()
	_mesgul = false


## Bant ekrani soldan ORTER (260 ms, ease-out).
func kapat(renk: Color = Tema.PEMBE) -> void:
	_bant.color = renk
	_bant.position.x = -GENISLIK
	_bant.visible = true
	if hizli:
		_bant.position.x = -10.0
		return
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_bant, "position:x", -10.0, ORTME)
	await t.finished


## Bant saga cikip ekrani ACAR (200 ms, ease-in).
func ac() -> void:
	if not hizli:
		var t := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		t.tween_property(_bant, "position:x", GENISLIK, ACMA)
		await t.finished
	_bant.visible = false
