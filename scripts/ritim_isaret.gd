class_name RitimIsaret
extends Node2D
## Ritim parçasında çatı kenarına gömülü vuruş lambaları. Zıplanacak vuruşlar sarı ve iri;
## hepsi müzikle birlikte (Ritim ızgarası fazına göre) nabız gibi parlar.

## Oyunun her kare yazdığı vuruş fazı (0 = vuruş anı, 0..1).
static var faz := 0.0

var vuruslar := PackedFloat32Array()
var zipla := PackedByteArray()
var cukurlar: Array = []


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var parlak := pow(1.0 - faz, 3.0)
	for i in vuruslar.size():
		var x := vuruslar[i]
		var bosta := false
		for c in cukurlar:
			if x >= c.x - 2.0 and x <= c.y + 2.0:
				bosta = true
		if bosta:
			continue
		var y := Ayarlar.ZEMIN_Y + 3.0
		if zipla[i]:
			var r := Color("fee761").lerp(Color.WHITE, parlak * 0.6)
			# vuruşta parlayan hale
			draw_circle(Vector2(x, y + 1), 5.0 + 5.0 * parlak, Color(1.0, 0.9, 0.4, 0.12 + 0.3 * parlak))
			draw_rect(Rect2(x - 6, y - 1, 12, 5), Color("181425"))
			draw_rect(Rect2(x - 5, y, 10, 3), r)
			# zıplama oku (tabanlı, ölçüyle birlikte hafifçe zıplar)
			var oy := y - 9.0 - 2.0 * parlak
			draw_colored_polygon(PackedVector2Array([Vector2(x - 5, oy), Vector2(x + 5, oy), Vector2(x, oy - 6)]), Color(r, 0.75 + 0.25 * parlak))
			draw_rect(Rect2(x - 1.5, oy, 3, 4), Color(r, 0.75 + 0.25 * parlak))
		else:
			var olcu_basi := i % Ritim.OLCU == 0
			var w := 6.0 if olcu_basi else 4.0
			draw_rect(Rect2(x - w * 0.5, y, w, 2), Color("8b9bb4").lerp(Color.WHITE, parlak * 0.8))
