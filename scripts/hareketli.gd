@tool
class_name Hareketli
extends AnimatableBody2D
## Gidip gelen tek yönlü platform. Konum = başlangıç sol üst köşesi.

@export var genislik := 64.0:
	set(v):
		genislik = v
		_guncelle()
## Başlangıç konumundan en uç sapma (ör. (60, 0) yatay, (0, 40) dikey)
@export var sapma := Vector2(60, 0)
@export var periyot := 2.4
@export var faz := 0.0

var _baslangic := Vector2.ZERO
var _zaman := 0.0
var _sekil: CollisionShape2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_baslangic = position
	_guncelle()


func _guncelle() -> void:
	if not is_node_ready():
		return
	if _sekil == null:
		_sekil = CollisionShape2D.new()
		_sekil.one_way_collision = true
		add_child(_sekil)
	var r := RectangleShape2D.new()
	r.size = Vector2(genislik, 8)
	_sekil.shape = r
	_sekil.position = r.size / 2.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_zaman += delta
	var k := sin(TAU * (_zaman / periyot + faz))
	position = _baslangic + sapma * k


func _draw() -> void:
	draw_rect(Rect2(0, 0, genislik, 5), Tema.MOR)
	# Tasiyici: iki kisa ayak (hareketli oldugu okunsun)
	for x in [5.0, genislik - 9.0]:
		draw_rect(Rect2(x, 5, 4, 3), Tema.MOR)
