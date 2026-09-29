@tool
class_name Tehlike
extends Area2D
## Dokunan oyuncuyu öldüren engel.
## DIKEN / BLOK / PISTON: konum = sol alt köşe (üzerinde durduğu yüzey hizası).
## TAVAN: tavandan sarkan tabela; konum = tabelanın sol alt köşesi (alt kenarın y'si).

enum Tur { DIKEN, BLOK, TAVAN, PISTON }

const RENK := Tema.SARI            ## tehlike rengi (videodaki sari ucgenler)
const KOYU := Tema.MUREKKEP
const GOVDE := Color("3a3450")     ## piston govdesi

## Yüksek kontrast modu (Ayarlar ekranı): tehlikelere beyaz dış çizgi.
static var kontrast := false

@export var tur: Tur = Tur.DIKEN:
	set(v):
		tur = v
		_guncelle()
@export var genislik := 36.0:
	set(v):
		genislik = v
		_guncelle()
@export var yukseklik := 12.0:
	set(v):
		yukseklik = v
		_guncelle()
## Piston için faz kayması (0-1)
@export var faz := 0.0

var _sekil: CollisionShape2D
var _yakin: Area2D
var _yakin_sekil: CollisionShape2D
var _yakinda := false
var _zaman := 0.0
var _anlik_yukseklik := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitorable = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_anlik_yukseklik = yukseklik
	_guncelle()
	if not Engine.is_editor_hint():
		body_entered.connect(_govde_girdi)
		if tur != Tur.TAVAN:
			_yakin = Area2D.new()
			_yakin.collision_layer = 0
			_yakin.collision_mask = 2
			_yakin.monitorable = false
			_yakin_sekil = CollisionShape2D.new()
			_yakin.add_child(_yakin_sekil)
			add_child(_yakin)
			_yakin.body_entered.connect(func(b: Node2D) -> void: if b is Oyuncu: _yakinda = true)
			_yakin.body_exited.connect(_yakin_cikti)
			_guncelle()


func _physics_process(delta: float) -> void:
	if tur != Tur.PISTON or Engine.is_editor_hint():
		return
	_zaman += delta
	var t := fposmod(_zaman / Ayarlar.PISTON_PERIYOT + faz, 1.0)
	# 0-0.4 yukarıda, 0.4-0.5 iniş, 0.5-0.9 aşağıda, 0.9-1 çıkış
	var oran := 1.0
	if t < 0.4:
		oran = 1.0
	elif t < 0.5:
		oran = 1.0 - (t - 0.4) / 0.1
	elif t < 0.9:
		oran = 0.0
	else:
		oran = (t - 0.9) / 0.1
	var h := lerpf(Ayarlar.PISTON_ALCAK, yukseklik, oran)
	if absf(h - _anlik_yukseklik) > 0.01:
		_anlik_yukseklik = h
		_sekil_boyutla()
		queue_redraw()


func _guncelle() -> void:
	if not is_node_ready():
		return
	if _sekil == null:
		_sekil = CollisionShape2D.new()
		add_child(_sekil)
	_anlik_yukseklik = yukseklik
	_sekil_boyutla()
	queue_redraw()


func _sekil_boyutla() -> void:
	# Adil olsun diye isabet kutusu görselden biraz küçük.
	var pay := 3.0 if tur in [Tur.DIKEN, Tur.PISTON] else 1.0
	var r := RectangleShape2D.new()
	var h := _anlik_yukseklik
	r.size = Vector2(maxf(genislik - pay * 2.0, 2.0), maxf(h - pay, 2.0))
	_sekil.shape = r
	_sekil.position = Vector2(genislik / 2.0, -r.size.y / 2.0)
	if _yakin_sekil:
		var y := RectangleShape2D.new()
		var ust := yukseklik  # piston için en yüksek konumun üstü
		y.size = Vector2(genislik + 6.0, Ayarlar.YAKIN_KACIS_PAYI)
		_yakin_sekil.shape = y
		_yakin_sekil.position = Vector2(genislik / 2.0, -ust - Ayarlar.YAKIN_KACIS_PAYI / 2.0)


func _govde_girdi(govde: Node2D) -> void:
	if govde.has_method("ol"):
		govde.ol(self)


func _yakin_cikti(govde: Node2D) -> void:
	if not (govde is Oyuncu) or not _yakinda:
		return
	_yakinda = false
	var o := govde as Oyuncu
	# Engelin sağına geçmiş ve hâlâ canlıysa kıl payı kaçış sayılır.
	if o.canli and o.global_position.x > global_position.x + genislik:
		get_tree().call_group("oyun", "yakin_kacis", self)


## Şu anki isabet kutusu (dünya koordinatında) — ölüm tekrarında vurgulanır.
func isabet_rect() -> Rect2:
	var r := (_sekil.shape as RectangleShape2D).size
	return Rect2(global_position + _sekil.position - r / 2.0, r)


func _ucgen(x: float, w: float, h: float, taban: float, renk: Color) -> void:
	var a := Vector2(x, taban)
	var b := Vector2(x + w * 0.5, taban - h)
	var c := Vector2(x + w, taban)
	draw_colored_polygon(PackedVector2Array([a, b, c]), renk)
	draw_polyline(PackedVector2Array([a, b, c, a]), renk, 1.0, true)   # yumusak kenar


func _draw() -> void:
	match tur:
		Tur.DIKEN:
			var adet := maxi(1, int(round(genislik / 12.0)))
			var w := genislik / adet
			for i in adet:
				_ucgen(i * w, w, yukseklik, 0.0, RENK)
		Tur.BLOK:
			draw_rect(Rect2(0, -yukseklik, genislik, yukseklik), RENK)
			# Uyari isareti: koyu cubuk + nokta
			var cx := genislik * 0.5
			draw_rect(Rect2(cx - 1.5, -yukseklik + 7, 3, minf(yukseklik * 0.42, 22.0)), KOYU)
			draw_rect(Rect2(cx - 1.5, -yukseklik + 7 + minf(yukseklik * 0.42, 22.0) + 4, 3, 3), KOYU)
		Tur.TAVAN:
			var r := Rect2(0, -yukseklik, genislik, yukseklik)
			for x in [6.0, genislik - 7.0]:
				draw_line(Vector2(x, -yukseklik), Vector2(x, -yukseklik - 400.0), Color(Tema.KAGIT, 0.4), 1.0)
			draw_rect(r, RENK)
			var adet := int((genislik - 8) / 10.0)
			for i in adet:
				draw_rect(Rect2(6 + i * 10, -yukseklik + yukseklik / 2.0 - 3, 5, 6), KOYU)
		Tur.PISTON:
			var h := _anlik_yukseklik
			draw_rect(Rect2(2, -h + 7, genislik - 4, maxf(h - 7, 0)), GOVDE)
			var adet := maxi(1, int(round(genislik / 6.0)))
			var w := genislik / adet
			for i in adet:
				_ucgen(i * w, w, 8.0, -h + 8.0, RENK)
			draw_rect(Rect2(-2, -3, genislik + 4, 3), Tema.SOLUK)
	if kontrast:
		var ust := _anlik_yukseklik if tur == Tur.PISTON else yukseklik
		draw_rect(Rect2(-1, -ust - 1, genislik + 2, ust + 2), Color.WHITE, false, 2.0)
