class_name Oyuncu
extends CharacterBody2D
## Kendiliğinden koşan oyuncu. Tek eylem: zıpla (basılı tut = daha yüksek,
## havada bir kez daha zıplanabilir).

signal oldu

const YARIM_GENISLIK := 7.0
const BOY := 22.0

var hiz: float = Ayarlar.HIZ_BAS
var canli := true
## Testlerde ölümsüzlük: ölüm sayılır ama koşu durmaz.
var olumsuz := false
var olum_sayisi := 0

var _kullanilan_ziplama := 0   # 0: yerde, 1: ilk zıplama yapıldı, 2: hak bitti
var _kojot := 0.0
var _tampon := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 4.0


func _physics_process(delta: float) -> void:
	if not canli:
		return
	velocity.x = hiz
	if is_on_floor():
		_kojot = Ayarlar.KOJOT_SURESI
		_kullanilan_ziplama = 0
	else:
		_kojot -= delta
		velocity.y = minf(velocity.y + Ayarlar.YERCEKIMI * delta, Ayarlar.AZAMI_DUSUS)

	if _tampon > 0.0:
		_tampon -= delta
		if is_on_floor() and _zipla_dene():
			_tampon = 0.0

	move_and_slide()
	queue_redraw()

	if _duvara_carpti():
		ol()
	elif global_position.y > Ayarlar.OLUM_Y:
		ol()


## Zıplama tuşuna basıldı.
func zipla_bas() -> void:
	if not canli:
		return
	if not _zipla_dene():
		_tampon = Ayarlar.ZIPLAMA_TAMPONU


## Zıplama tuşu bırakıldı: yükseliyorsak zıplamayı kısalt.
func zipla_birak() -> void:
	if canli and velocity.y < 0.0:
		velocity.y *= Ayarlar.KISA_ZIPLAMA_CARPANI


func havada_ziplama_hakki_var() -> bool:
	return _kullanilan_ziplama < 2


func _zipla_dene() -> bool:
	if _kullanilan_ziplama == 0 and (is_on_floor() or _kojot > 0.0):
		velocity.y = Ayarlar.ZIPLAMA_HIZI
		_kullanilan_ziplama = 1
		_kojot = 0.0
		return true
	if not is_on_floor() and _kullanilan_ziplama < 2:
		# Kenardan yürüyerek düştüyse de tek hava zıplaması hakkı var.
		velocity.y = Ayarlar.IKINCI_ZIPLAMA_HIZI
		_kullanilan_ziplama = 2
		return true
	return false


## Önden bir yüzeye çarptık mı? Zemin parçaları arasındaki eklem yerlerini
## (ayak hizasındaki temasları) duvar saymaz.
func _duvara_carpti() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().x < -0.7 and c.get_position().y < global_position.y - 4.0:
			return true
	return false


func ol() -> void:
	if not canli:
		return
	olum_sayisi += 1
	if olumsuz:
		# Test modu: çukura düştüyse yukarı taşı, duvara takıldıysa üstünden aşır.
		if global_position.y > Ayarlar.OLUM_Y:
			global_position.y = Ayarlar.ZEMIN_Y - 150.0
		else:
			global_position += Vector2(24.0, -60.0)
		velocity = Vector2.ZERO
		return
	canli = false
	velocity = Vector2.ZERO
	queue_redraw()
	oldu.emit()


func _draw() -> void:
	var govde := Rect2(-YARIM_GENISLIK, -BOY, YARIM_GENISLIK * 2.0, BOY)
	var renk := Color("5fcde4") if canli else Color("847e87")
	draw_rect(govde, renk)
	draw_rect(Rect2(-YARIM_GENISLIK, -BOY, YARIM_GENISLIK * 2.0, 5.0), Color("306082"))
	draw_rect(Rect2(1.0, -17.0, 3.0, 3.0), Color("222034"))
	if not is_on_floor() and canli:
		draw_rect(Rect2(-YARIM_GENISLIK - 3.0, -8.0, 3.0, 4.0), Color("fbf236"))
