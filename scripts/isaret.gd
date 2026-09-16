class_name Isaret
extends Node2D
## Dünyada dikey kesikli çizgi ve kısa yazı: rekor, son ölüm yeri, hayaletin bittiği yer.
## Konum: x = işaretin mesafesi, y = 0 (çizgi yukarıdan zemine iner).

var metin := ""
var renk := Color.WHITE
var ust_y := 44.0


func _ready() -> void:
	var l := Label.new()
	l.text = metin
	l.position = Vector2(5, ust_y - 15)
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", renk)
	l.add_theme_color_override("font_outline_color", Color("181425"))
	l.add_theme_constant_override("outline_size", 3)
	add_child(l)


func _draw() -> void:
	var y := ust_y
	while y < Ayarlar.ZEMIN_Y:
		draw_line(Vector2(0, y), Vector2(0, minf(y + 6.0, Ayarlar.ZEMIN_Y)), Color(renk, 0.8), 2.0)
		y += 10.0
	# Bayrak
	draw_line(Vector2(0, ust_y - 16), Vector2(0, ust_y), renk, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(1, ust_y - 16), Vector2(1, ust_y - 8), Vector2(-1 + 4.0 + metin.length() * 6.2 + 4.0, ust_y - 8), Vector2(-1 + 4.0 + metin.length() * 6.2 + 4.0, ust_y - 16)]), Color("181425", 0.7))
