@tool
class_name Tehlike
extends Area2D
## Dokunan oyuncuyu öldüren engel. Konum = sol alt köşe (zemin hizası).

enum Tur { DIKEN, BLOK }

@export var tur: Tur = Tur.DIKEN:
	set(v):
		tur = v
		_guncelle()
@export var genislik := 36.0:
	set(v):
		genislik = v
		_guncelle()
@export var yukseklik := 12.0:
	set(v):
		yukseklik = v
		_guncelle()

var _sekil: CollisionShape2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitorable = false
	_guncelle()
	if not Engine.is_editor_hint():
		body_entered.connect(_govde_girdi)


func _guncelle() -> void:
	if not is_node_ready():
		return
	if _sekil == null:
		_sekil = CollisionShape2D.new()
		add_child(_sekil)
	# Adil olsun diye isabet kutusu görselden biraz küçük.
	var pay := 3.0 if tur == Tur.DIKEN else 1.0
	var r := RectangleShape2D.new()
	r.size = Vector2(maxf(genislik - pay * 2.0, 2.0), maxf(yukseklik - pay, 2.0))
	_sekil.shape = r
	_sekil.position = Vector2(genislik / 2.0, -r.size.y / 2.0)
	queue_redraw()


func _govde_girdi(govde: Node2D) -> void:
	if govde.has_method("ol"):
		govde.ol()


func _draw() -> void:
	if tur == Tur.DIKEN:
		var adet := maxi(1, int(round(genislik / 12.0)))
		var w := genislik / adet
		for i in adet:
			var x := i * w
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, 0), Vector2(x + w / 2.0, -yukseklik), Vector2(x + w, 0)
			]), Color("ac3232"))
	else:
		draw_rect(Rect2(0, -yukseklik, genislik, yukseklik), Color("ac3232"))
		draw_rect(Rect2(3, -yukseklik + 3, genislik - 6, yukseklik - 6), Color("d95763"))
		draw_line(Vector2(3, -yukseklik + 3), Vector2(genislik - 3, -3), Color("ac3232"), 2.0)
