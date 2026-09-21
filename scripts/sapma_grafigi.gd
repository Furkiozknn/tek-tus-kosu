class_name SapmaGrafigi
extends Control
## v1.7: ritim koşusu sonucunda vuruş sapması histogramı. Zıplamaların vuruşa göre erken/geç dağılımını
## beş kutuda gösterir; "tam" kutusu Ritim.TAM_VURUS_MS penceresidir, dış kutular UZAK_MS'den ötesi.
## Yalnız çizim; sayım `kutula()` ile saf hesap (testlenir).

const UZAK_MS := 150.0
const KUTU_ADLARI := ["çok erken", "erken", "tam", "geç", "çok geç"]
const RENKLER := [Color("8b9bb4"), Color("c0cbdc"), Color("fee761"), Color("c0cbdc"), Color("8b9bb4")]

var sayilar: Array[int] = [0, 0, 0, 0, 0]


## Sapmaları (ms, + geç) beş kutuya sayar: [< -UZAK, -UZAK..-TAM, |x| <= TAM, TAM..UZAK, > UZAK].
static func kutula(sapmalar: Array) -> Array[int]:
	var s: Array[int] = [0, 0, 0, 0, 0]
	for v in sapmalar:
		var ms := float(v)
		var k: int
		if absf(ms) <= Ritim.TAM_VURUS_MS:
			k = 2
		elif ms < -UZAK_MS:
			k = 0
		elif ms < 0.0:
			k = 1
		elif ms > UZAK_MS:
			k = 4
		else:
			k = 3
		s[k] += 1
	return s


func ayarla(sapmalar: Array) -> void:
	sayilar = kutula(sapmalar)
	queue_redraw()


func toplam() -> int:
	var t := 0
	for s in sayilar:
		t += s
	return t


func _draw() -> void:
	var w := size.x
	var h := size.y
	var yazi_h := 10.0            # alt etiket alanı
	var sayi_h := 10.0            # üst sayı alanı
	var taban := h - yazi_h
	var en_cok := 1
	for s in sayilar:
		en_cok = maxi(en_cok, s)
	var kutu_w := w / 5.0
	var font := get_theme_default_font()
	draw_rect(Rect2(0, taban, w, 1), Color("5a6988"))
	for i in 5:
		var x0 := kutu_w * i
		var oran := float(sayilar[i]) / float(en_cok)
		var boy := maxf(oran * (taban - sayi_h - 2.0), 1.0 if sayilar[i] > 0 else 0.0)
		var cubuk := Rect2(x0 + 8.0, taban - boy, kutu_w - 16.0, boy)
		if sayilar[i] > 0:
			draw_rect(cubuk, RENKLER[i])
		else:
			draw_rect(Rect2(x0 + 8.0, taban - 1.0, kutu_w - 16.0, 1.0), Color("5a6988"))
		var sayi := str(sayilar[i])
		var sw := font.get_string_size(sayi, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		draw_string(font, Vector2(x0 + (kutu_w - sw) * 0.5, taban - boy - 2.0), sayi, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, RENKLER[i] if sayilar[i] > 0 else Color("5a6988"))
		var ad: String = KUTU_ADLARI[i]
		var aw := font.get_string_size(ad, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		draw_string(font, Vector2(x0 + (kutu_w - aw) * 0.5, h - 1.0), ad, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("8b9bb4"))
