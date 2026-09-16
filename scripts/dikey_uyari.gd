class_name DikeyUyari
extends CanvasLayer
## Telefon dikey tutulunca "yan çevir" perdesi. Oyun yatay (640×360) tasarlandı; dikeyde ekran
## ince bir şeride dönüşüyor. Oyun sahnesi `dikey_oldu` sinyalinde koşuyu duraklatır.

signal dikey_oldu

## Testler için: -1 gerçek pencere boyutu, 0 yatay say, 1 dikey say.
static var zorla := -1

var perde: ColorRect
var dikey := false


func _ready() -> void:
	name = "DikeyUyari"
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	perde = ColorRect.new()
	perde.name = "Perde"
	perde.color = Color("181425", 0.95)
	perde.set_anchors_preset(Control.PRESET_FULL_RECT)
	perde.mouse_filter = Control.MOUSE_FILTER_STOP
	perde.visible = false
	add_child(perde)
	var kutu := VBoxContainer.new()
	kutu.set_anchors_preset(Control.PRESET_FULL_RECT)
	kutu.alignment = BoxContainer.ALIGNMENT_CENTER
	kutu.add_theme_constant_override("separation", 14)
	kutu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	perde.add_child(kutu)
	var simge := Simge.new()
	simge.custom_minimum_size = Vector2(220, 110)
	simge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	kutu.add_child(simge)
	for satir in [["Telefonu yan çevir", 50, Color("2ce8f5")], ["Tek Tuş Koşu yatay oynanır", 26, Color("c0cbdc")]]:
		var l := Label.new()
		l.text = satir[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", satir[1])
		l.add_theme_color_override("font_color", satir[2])
		kutu.add_child(l)
	get_tree().root.size_changed.connect(denetle)
	denetle()


static func dikey_mi(boyut: Vector2) -> bool:
	return boyut.y > boyut.x * 1.05


func denetle() -> void:
	var d := dikey_mi(Vector2(get_window().size)) if zorla < 0 else zorla == 1
	if d == dikey:
		return
	dikey = d
	perde.visible = d
	if d:
		dikey_oldu.emit()


## Dikey telefon → dönüş oku → yatay telefon (koddan çizilir).
class Simge extends Control:
	func _draw() -> void:
		# Perde yalnız dikeyde görünür; orada oyun alanı küçüldüğü için simge iri çizilir.
		draw_set_transform(size / 2.0, 0.0, Vector2(2.0, 2.0))
		var r := Color("c0cbdc")
		var c := Vector2.ZERO
		draw_rect(Rect2(c.x - 52, c.y - 22, 22, 40), r, false, 2.0)
		draw_rect(Rect2(c.x - 44, c.y + 13, 6, 2), r)
		draw_rect(Rect2(c.x + 12, c.y - 12, 40, 22), r, false, 2.0)
		draw_rect(Rect2(c.x + 45, c.y - 4, 2, 6), r)
		var ok := Color("fee761")
		draw_line(Vector2(c.x - 20, c.y), Vector2(c.x + 4, c.y), ok, 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(c.x + 4, c.y - 6), Vector2(c.x + 10, c.y), Vector2(c.x + 4, c.y + 6)]), ok)
