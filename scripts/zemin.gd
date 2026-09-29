@tool
class_name Zemin
extends StaticBody2D
## Dikdörtgen zemin/platform (çatı teması). Konum = sol üst köşe.

const GOVDE := Tema.MUREKKEP
const CIZGI := Tema.KAGIT

@export var genislik := 200.0:
	set(v):
		genislik = v
		_guncelle()
@export var yukseklik := 120.0:
	set(v):
		yukseklik = v
		_guncelle()
## Tek yönlü platform: yalnızca üstten basılır, alttan geçilir.
@export var tek_yonlu := false:
	set(v):
		tek_yonlu = v
		_guncelle()

var _sekil: CollisionShape2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_guncelle()


func _guncelle() -> void:
	if not is_node_ready():
		return
	if _sekil == null:
		_sekil = CollisionShape2D.new()
		add_child(_sekil)
	var r := RectangleShape2D.new()
	r.size = Vector2(genislik, yukseklik)
	_sekil.shape = r
	_sekil.position = r.size / 2.0
	_sekil.one_way_collision = tek_yonlu
	queue_redraw()


func _draw() -> void:
	if tek_yonlu:
		draw_rect(Rect2(0, 0, genislik, 4), CIZGI)
		return
	# Duz koyu blok + ustte ince acik cizgi (videodaki zemin).
	draw_rect(Rect2(0, 0, genislik, yukseklik), GOVDE)
	draw_rect(Rect2(0, 0, genislik, 2), CIZGI)
