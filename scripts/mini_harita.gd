class_name MiniHarita
extends Control
## Koşu sonu "şehir ışıkları" şeridi: bu koşuda geçilen yer ışıklı pencerelerle,
## önceki ölüm yerleri kırmızı çentikle, rekor sarı işaretle gösterilir.

var mesafe := 0
var rekor := 0
var olumler: Array = []


func ayarla(m: int, r: int, o: Array) -> void:
	mesafe = m
	rekor = r
	olumler = o.duplicate()
	queue_redraw()


func _draw() -> void:
	var en := float(maxi(maxi(mesafe, rekor), 1))
	for o in olumler:
		en = maxf(en, float(o))
	en *= 1.08
	var w := size.x
	var h := size.y
	var taban := h - 5.0
	draw_rect(Rect2(0, taban, w, 2), Color("5a6988"))
	# Bina silüetleri; geçilenlerin pencereleri yanık.
	var adim := 10.0
	var i := 0
	var x := 0.0
	while x < w:
		var boy := 6.0 + float((i * 7919) % 9)
		var bina := Rect2(x + 1, taban - boy, adim - 2, boy)
		draw_rect(bina, Color("262b44"))
		var gecildi := (x + adim * 0.5) / w * en <= mesafe
		var pencere := Color("fee761") if gecildi else Color("3a4466")
		draw_rect(Rect2(x + 3, taban - boy + 2, 2, 2), pencere)
		if boy > 9.0:
			draw_rect(Rect2(x + 6, taban - boy + 5, 2, 2), pencere)
		x += adim
		i += 1
	for o in olumler:
		var ox := float(o) / en * w
		draw_line(Vector2(ox, taban - 16), Vector2(ox, taban + 2), Color("e43b44", 0.8), 1.0)
	if rekor > 0:
		var rx := float(rekor) / en * w
		draw_line(Vector2(rx, 0), Vector2(rx, taban + 2), Color("fee761"), 1.0)
		draw_string(get_theme_default_font(), Vector2(minf(rx + 2, w - 40), 8), "rekor", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("fee761"))
	var mx := float(mesafe) / en * w
	draw_rect(Rect2(mx - 2, taban - 3, 4, 4), Color("2ce8f5"))
