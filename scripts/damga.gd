class_name Damga
extends Panel
## "Yeni rekor" damgasi: paletin video renk akisinda (Tema.AKIS) 90 ms adimla doner, sonra ilk
## renkte durur. Yazi rengi her adimda vurgunun ustunde kodla secilir (>= Tema.ESIK).
## Sade geciste (hareket azaltma) akis ve olcek hareketi yok: ilk renkte sabit.

const ADIM := 0.09
const ADET := 6

var yazi: Label
var palet: int = 0
var _tween: Tween = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", Tema.kutu(Tema.PEMBE, 3))
	yazi = Label.new()
	yazi.theme_type_variation = &"EtiketKalin"
	yazi.add_theme_font_size_override("font_size", 9)
	yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yazi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	yazi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(yazi)
	visible = false


func rengi() -> Color:
	return (get_theme_stylebox("panel") as StyleBoxFlat).bg_color


## Metni yazar, boyutlar, akisi baslatir. `konum` ust kenardaki bir nokta; `hiza.x` damganin
## o noktaya gore yatay yeri (0 sol kenar, 0,5 orta, 1 sag kenar).
func goster(metin: String, pal: int, konum: Vector2, sade: bool, hiza: Vector2 = Vector2.ZERO) -> void:
	palet = pal
	yazi.text = metin
	var w: float = yazi.get_minimum_size().x + 16.0
	size = Vector2(w, 18.0)
	position = konum - Vector2(w * hiza.x, 0.0)
	yazi.size = size
	pivot_offset = size * 0.5
	visible = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_boya(0)
	scale = Vector2.ONE
	if sade:
		return
	scale = Vector2(1.5, 1.5)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	for k in range(1, ADET + 1):
		_tween.tween_callback(_boya.bind(k)).set_delay(ADIM)
	_tween.tween_callback(_boya.bind(0)).set_delay(ADIM)


func gizle() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visible = false


func _boya(k: int) -> void:
	var v: Color = Tema.akis_rengi(palet, k)
	(get_theme_stylebox("panel") as StyleBoxFlat).bg_color = v
	yazi.add_theme_color_override("font_color", Tema.yazi_rengi(v, palet))
