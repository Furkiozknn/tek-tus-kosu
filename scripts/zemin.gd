@tool
class_name Zemin
extends StaticBody2D
## Dikdörtgen zemin/platform (çatı teması). Konum = sol üst köşe.

const KARO := 16
const DOKU := preload("res://assets/sprites/zemin.png")

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
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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


func _karo(sutun: int, satir: int, hucre: int) -> void:
	var w := minf(KARO, genislik - sutun * KARO)
	var h := minf(KARO, yukseklik - satir * KARO)
	if w <= 0 or h <= 0:
		return
	draw_texture_rect_region(DOKU, Rect2(sutun * KARO, satir * KARO, w, h), Rect2(hucre * KARO, 0, w, h))


func _draw() -> void:
	var sutunlar := int(ceil(genislik / KARO))
	if tek_yonlu:
		for s in sutunlar:
			var w := minf(KARO, genislik - s * KARO)
			draw_texture_rect_region(DOKU, Rect2(s * KARO, 0, w, 6), Rect2(4 * KARO, 0, w, 6))
		return
	var satirlar := int(ceil(yukseklik / KARO))
	# Konuma bağlı sabit sözde rastgele pencere dizilimi (her parçada aynı görünür)
	for s in sutunlar:
		_karo(s, 0, 0)
		for y in range(1, satirlar):
			var h := hash(Vector3i(s, y, int(position.x))) % 13
			var hucre := 1
			if y % 2 == 1 and h == 0:
				hucre = 2
			elif y % 2 == 1 and h == 1:
				hucre = 3
			_karo(s, y, hucre)
	# Sol ve sağ kenarda koyu çizgi: binaların ayrıldığı okunsun
	draw_rect(Rect2(0, 0, 1, yukseklik), Color("181425"))
	draw_rect(Rect2(genislik - 1, 0, 1, yukseklik), Color("181425"))
