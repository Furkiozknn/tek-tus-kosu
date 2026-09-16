@tool
class_name Coken
extends Zemin
## Çürük iskele: iki çatı arasındaki boşluğa uzanan tahta. Üstüne basılınca sallanır,
## Ayarlar.ISKELE_COKME sn sonra çöker (çarpışma kapanır, tahtalar düşer).
## Oyuncu hızını kesemediği için beceri, iskele çökmeden zıplayıp inmektir.

enum Durum { SAGLAM, CATIRDIYOR, COKTU }

var durum := Durum.SAGLAM
var _sure := 0.0
var _dusus_hizi := 0.0
var _ilk_y := 0.0


func _ready() -> void:
	super()
	_ilk_y = position.y


## Oyuncu üstüne bastığında çağrılır (Oyuncu._zemine_bildir).
func basildi() -> void:
	if durum != Durum.SAGLAM:
		return
	durum = Durum.CATIRDIYOR
	_sure = 0.0
	if is_inside_tree():
		get_tree().call_group("oyun", "iskele_catirdadi", self)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match durum:
		Durum.CATIRDIYOR:
			_sure += delta
			queue_redraw()
			if _sure >= Ayarlar.ISKELE_COKME:
				durum = Durum.COKTU
				if _sekil:
					_sekil.set_deferred("disabled", true)
				if is_inside_tree():
					get_tree().call_group("oyun", "iskele_coktu", self)
		Durum.COKTU:
			_dusus_hizi += Ayarlar.ISKELE_DUSUS * delta
			position.y += _dusus_hizi * delta
			modulate.a = maxf(0.0, modulate.a - delta * 1.6)
			if position.y > _ilk_y + 160.0:
				visible = false
				set_physics_process(false)


func _draw() -> void:
	var titre := Vector2.ZERO
	if durum == Durum.CATIRDIYOR:
		# Çökmeye yaklaştıkça artan sarsıntı (belirlenimci: süreye bağlı)
		var g := 0.5 + 1.5 * (_sure / Ayarlar.ISKELE_COKME)
		titre = Vector2(sin(_sure * 90.0) * g * 0.6, absf(sin(_sure * 57.0)) * g)
	var k := yukseklik
	# Tahtalar: 12 px'lik dilimler, aralarında koyu derz
	var n := int(ceil(genislik / 12.0))
	for i in n:
		var x := i * 12.0
		var w := minf(11.0, genislik - x)
		var kay := titre if i % 2 == 0 else -titre * 0.7
		var renk := Color("b86f50") if (i * 7 + int(position.x)) % 3 else Color("733e39")
		draw_rect(Rect2(Vector2(x, 0) + kay, Vector2(w, k)), renk)
		draw_rect(Rect2(Vector2(x, 0) + kay, Vector2(w, 2)), Color("d77643"))
		draw_rect(Rect2(Vector2(x, k - 2) + kay, Vector2(w, 2)), Color("3e2731"))
		# Çatlaklar (çürük olduğu önceden okunsun)
		if (i + int(position.x)) % 4 == 1:
			draw_line(Vector2(x + 3, 2) + kay, Vector2(x + 6, k - 3) + kay, Color("3e2731"), 1.0)
	# Taşıyıcı halatlar (iki uçta)
	draw_rect(Rect2(0, -14, 1, 14), Color("8b9bb4"))
	draw_rect(Rect2(genislik - 1, -14, 1, 14), Color("8b9bb4"))
	draw_rect(Rect2(-2, -15, 5, 2), Color("5a6988"))
	draw_rect(Rect2(genislik - 3, -15, 5, 2), Color("5a6988"))
