@tool
class_name Altin
extends Area2D
## Toplanabilir altın. Toplanınca "oyun" grubuna haber verir.

const YARICAP := 6.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitorable = false
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = YARICAP + 2.0
	s.shape = c
	add_child(s)
	if not Engine.is_editor_hint():
		body_entered.connect(_govde_girdi)


func _govde_girdi(govde: Node2D) -> void:
	if govde is Oyuncu:
		get_tree().call_group("oyun", "altin_toplandi")
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, YARICAP, Color("fbf236"))
	draw_circle(Vector2.ZERO, YARICAP - 2.5, Color("dfb72d"))
	draw_rect(Rect2(-1, -3, 2, 6), Color("fbf236"))
