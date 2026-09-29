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
		var y := Ayarlar.ZEMIN_Y
		if zipla[i]:
			# Zipla vurusu: videodaki gibi ince pembe dikey cizgi + zeminde pembe ok; vurusta parlar
			var r := Tema.PEMBE.lerp(Color.WHITE, parlak * 0.5)
			draw_rect(Rect2(x - 0.5, y - 70.0, 1, 70.0), Color(Tema.PEMBE, 0.16 + 0.34 * parlak))
			var oy := y - 8.0 - 2.0 * parlak
			draw_colored_polygon(PackedVector2Array([Vector2(x - 5, oy), Vector2(x + 5, oy), Vector2(x, oy - 7)]), Color(r, 0.8 + 0.2 * parlak))
			draw_rect(Rect2(x - 2.0, oy, 4, 5), Color(r, 0.8 + 0.2 * parlak))
		else:
			var olcu_basi := i % Ritim.OLCU == 0
			var w := 6.0 if olcu_basi else 4.0
			draw_rect(Rect2(x - w * 0.5, y + 4, w, 2), Color(Tema.KAGIT, 0.35 + 0.5 * parlak))
