class_name Oyuncu
extends CharacterBody2D
## Kendiliğinden koşan oyuncu. Tek eylem: zıpla (basılı tut = daha yüksek,
## havada bir kez daha zıplanabilir).

signal oldu
signal ziplandi(ikinci: bool)
signal indi

const YARIM_GENISLIK := 7.0
const BOY := 22.0
const GECMIS_UZUNLUK := 120

var hiz: float = Ayarlar.HIZ_BAS
var canli := true
## Testlerde ölümsüzlük: ölüm sayılır ama koşu durmaz.
var olumsuz := false
var olum_sayisi := 0
## Ölüme yol açan şey: Tehlike düğümü, "cukur" ya da "duvar"
var olum_nedeni: Variant = null
var kostum := "klasik"
## Ölüm tekrarı için son konumlar: [Vector2, animasyon, kare]
var gecmis: Array = []

var gorsel: AnimatedSprite2D
## Kostüm izi (yalnız "iz_surekli" kostümlerde). Testlerde/botta kapatılır.
var iz_acik := true
var _iz: CPUParticles2D
var _kullanilan_ziplama := 0   # 0: yerde, 1: ilk zıplama yapıldı, 2: hak bitti
var _kojot := 0.0
var _tampon := 0.0
var _takla := 0.0
var _yerde_onceki := true
var _alt_yoklama := KinematicCollision2D.new()


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 4.0
	gorsel = AnimatedSprite2D.new()
	gorsel.name = "Gorsel"
	gorsel.centered = false
	gorsel.offset = Vector2(-10, -25)
	add_child(gorsel)
	kostum_uygula(kostum)


func kostum_uygula(ad: String) -> void:
	kostum = ad
	if gorsel:
		gorsel.sprite_frames = Kostumler.kareler(ad)
		gorsel.play("kos")
	var bilgi := Kostumler.bilgi(ad)
	if bool(bilgi.get("iz_surekli", false)) and iz_acik:
		if _iz == null:
			_iz = CPUParticles2D.new()
			_iz.name = "Iz"
			_iz.local_coords = false
			_iz.amount = 14
			_iz.lifetime = 0.35
			_iz.position = Vector2(-5, -5)
			_iz.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			_iz.emission_rect_extents = Vector2(1, 4)
			_iz.direction = Vector2(-1, 0)
			_iz.spread = 20.0
			_iz.gravity = Vector2.ZERO
			_iz.initial_velocity_min = 5.0
			_iz.initial_velocity_max = 20.0
			_iz.scale_amount_min = 1.0
			_iz.scale_amount_max = 2.0
			_iz.show_behind_parent = true
			add_child(_iz)
		var r := Color(str(bilgi["iz"]))
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(r, 0.8), Color(r, 0.0)])
		_iz.color_ramp = g
		_iz.emitting = false
	elif _iz:
		_iz.queue_free()
		_iz = null


func sifirla(konum: Vector2) -> void:
	global_position = konum
	velocity = Vector2.ZERO
	canli = true
	olum_nedeni = null
	gecmis.clear()
	_kullanilan_ziplama = 0
	_kojot = 0.0
	_tampon = 0.0
	_takla = 0.0
	_yerde_onceki = true
	if gorsel:
		gorsel.scale = Vector2.ONE
		gorsel.modulate = Color.WHITE
		gorsel.play("kos")


func _physics_process(delta: float) -> void:
	if not canli:
		return
	velocity.x = hiz
	# Aynı karede zıplanmışsa (yukarı hız) "yerde" sayma: hak sayacı sıfırlanmasın.
	if is_on_floor() and velocity.y >= 0.0:
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
	_zemine_bildir()

	var yerde := is_on_floor()
	if yerde and not _yerde_onceki:
		_ezil(Vector2(1.25, 0.8))
		indi.emit()
	_yerde_onceki = yerde
	_takla = maxf(_takla - delta, 0.0)
	_gorsel_guncelle(delta)
	gecmis.append([global_position, gorsel.animation, gorsel.frame])
	if gecmis.size() > GECMIS_UZUNLUK:
		gecmis.pop_front()

	if _iz:
		_iz.emitting = canli and yerde and visible

	var duvar := _duvara_carpti()
	if duvar:
		# Çatı hizasının altındaysak bir boşluğa düşmüşüzdür: karşı duvar değil çukur ölümü.
		ol("cukur" if global_position.y > Ayarlar.ZEMIN_Y + 8.0 else duvar)
	elif global_position.y > Ayarlar.OLUM_Y:
		ol("cukur")


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
		_ezil(Vector2(0.8, 1.25))
		ziplandi.emit(false)
		return true
	if not is_on_floor() and _kullanilan_ziplama < 2:
		# Kenardan yürüyerek düştüyse de tek hava zıplaması hakkı var.
		velocity.y = Ayarlar.IKINCI_ZIPLAMA_HIZI
		_kullanilan_ziplama = 2
		_takla = 0.3
		_ezil(Vector2(0.85, 1.2))
		ziplandi.emit(true)
		return true
	return false


func _ezil(olcek: Vector2) -> void:
	if gorsel:
		gorsel.scale = olcek


func _gorsel_guncelle(delta: float) -> void:
	if gorsel == null:
		return
	gorsel.scale = gorsel.scale.lerp(Vector2.ONE, minf(1.0, delta * 12.0))
	var anim := "kos"
	if not is_on_floor():
		if _takla > 0.0:
			anim = "takla"
		elif velocity.y < 0.0:
			anim = "zipla"
		else:
			anim = "dus"
	if gorsel.animation != anim:
		gorsel.play(anim)
	if anim == "kos":
		gorsel.speed_scale = clampf(hiz / 300.0, 0.6, 1.8)


## Basılan zemin bunu bilmek istiyorsa (çürük iskele) haber ver. Yerde dururken
## kayma çarpışması oluşmadığı için ayağın 2 px altı ayrıca yoklanır.
func _zemine_bildir() -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().y < -0.7 and c.get_collider() is Coken:
			(c.get_collider() as Coken).basildi()
	if is_on_floor() and test_move(global_transform, Vector2(0, 2), _alt_yoklama):
		var o := _alt_yoklama.get_collider()
		if o is Coken:
			(o as Coken).basildi()


## Önden bir yüzeye çarptık mı? Zemin parçaları arasındaki eklem yerlerini
## (ayak hizasındaki temasları) duvar saymaz. Çarpılan düğümü döndürür.
func _duvara_carpti() -> Object:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().x < -0.7 and c.get_position().y < global_position.y - 4.0:
			var o := c.get_collider()
			# Tek yönlü (hareketli ya da sabit) kirişlerin yanına çarpmak öldürmez.
			if o is Hareketli or (o is Zemin and (o as Zemin).tek_yonlu):
				continue
			return o
	return null


func ol(neden: Variant = null) -> void:
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
	olum_nedeni = neden
	velocity = Vector2.ZERO
	if _iz:
		_iz.emitting = false
	if gorsel:
		gorsel.play("olum")
		gorsel.scale = Vector2.ONE
	oldu.emit()
