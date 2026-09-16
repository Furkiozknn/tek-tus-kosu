@tool
class_name Altin
extends Area2D
## Toplanabilir altın (dönen sprite). Toplanınca "oyun" grubuna haber verir.

const YARICAP := 6.0
const DOKU := preload("res://assets/sprites/altin.png")

var _kare := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitorable = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_kare = fposmod(position.x / 40.0, 4.0)
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = YARICAP + 2.0
	s.shape = c
	add_child(s)
	if not Engine.is_editor_hint():
		body_entered.connect(_govde_girdi)


func _govde_girdi(govde: Node2D) -> void:
	if govde is Oyuncu:
		get_tree().call_group("oyun", "altin_toplandi", global_position)
		queue_free()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var onceki := int(_kare)
	_kare = fposmod(_kare + delta * 8.0, 4.0)
	if int(_kare) != onceki:
		queue_redraw()


func _draw() -> void:
	draw_texture_rect_region(DOKU, Rect2(-6, -6, 12, 12), Rect2(int(_kare) * 12, 0, 12, 12))
