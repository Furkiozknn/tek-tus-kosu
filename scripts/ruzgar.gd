@tool
class_name Ruzgar
extends Node2D
## Rüzgâr bölgesi. Oyuncu bu aralıkta HAVADAYKEN yatay hızına `guc` eklenir:
## artı = arkadan (zıplama uzar), eksi = karşıdan (zıplama kısalır). Yerde koşu hızı değişmez.
## Konum = bölgenin sol kenarı, zemin hizası. Görsel: akan çizgiler + girişte yön bayrağı.

@export var genislik := 300.0:
	set(v):
		genislik = v
		queue_redraw()
@export var guc := -80.0:
	set(v):
		guc = v
		queue_redraw()

var _zaman := 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_zaman += delta
	queue_redraw()


func _draw() -> void:
	var yon := signf(guc)
	var renk := Color("c0cbdc", 0.45) if guc < 0.0 else Color("2ce8f5", 0.45)
	for i in 14:
		var h := float(hash(i * 7 + 3) % 1000) / 1000.0
		var y := -24.0 - h * 190.0
		var hiz := 110.0 + 90.0 * h
		var x := fposmod(h * genislik + yon * hiz * _zaman, genislik)
		var uz := 10.0 + 16.0 * h
		var x2 := clampf(x - yon * uz, 0.0, genislik)
		draw_line(Vector2(x, y), Vector2(x2, y), renk, 1.0)
	# Girişte bayrak: rüzgârın estiği yöne dalgalanır (karşıdan: sola, arkadan: sağa)
	var direk := 18.0 if guc < 0.0 else 2.0
	draw_rect(Rect2(direk, -46, 2, 46), Color("8b9bb4"))
	var dalga := sin(_zaman * 9.0) * 1.5
	var uc := direk + (-16.0 if guc < 0.0 else 18.0)
	var kok := direk + (0.0 if guc < 0.0 else 2.0)
	var bayrak := Color("e43b44") if guc < 0.0 else Color("63c74d")
	draw_colored_polygon(PackedVector2Array([Vector2(kok, -46), Vector2(uc, -41 + dalga), Vector2(kok, -36)]), bayrak)
