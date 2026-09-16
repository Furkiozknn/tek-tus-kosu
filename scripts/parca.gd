class_name Parca
extends Node2D
## Sonsuz koşunun bir parçası. Sol kenar x=0, sağ kenar x=uzunluk.
## Giriş ve çıkış noktaları zemin hizasındadır; parçalar uç uca eklenir.

## 0 = nefes parçası (tehlikesi az), 1-3 = zorluk
@export_range(0, 3) var zorluk := 1
@export var uzunluk := 640.0


func giris() -> Vector2:
	return ($Giris as Marker2D).position


func cikis() -> Vector2:
	return ($Cikis as Marker2D).position


## Oyuncunun üzerinden atlaması gereken yatay aralıklar (parçanın yerel x'i):
## tehlikeler, çukurlar ve yükselen basamak yüzleri. Bot ve testler kullanır.
func tehlike_araliklari() -> Array[Vector2]:
	var ham: Array[Vector2] = []
	var zeminler: Array[Zemin] = []
	for c in get_children():
		if c is Tehlike:
			if c.tur != Tehlike.Tur.TAVAN:
				ham.append(Vector2(c.position.x, c.position.x + c.genislik))
		elif c is Zemin:
			zeminler.append(c)

	# Çukurlar: hiçbir zeminin (platform dahil) desteklemediği yerler.
	var destek: Array[Vector2] = []
	for z in zeminler:
		destek.append(Vector2(z.position.x, z.position.x + z.genislik))
	destek.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var x := 0.0
	for d in destek:
		if d.x > x + 0.5:
			ham.append(Vector2(x, d.x))
		x = maxf(x, d.y)
	if x < uzunluk - 0.5:
		ham.append(Vector2(x, uzunluk))

	# Basamak yüzleri: solundaki yüzeyden daha yüksekte başlayan katı zemin.
	for z in zeminler:
		if z.tek_yonlu:
			continue
		var onceki := _yuzey_y(zeminler, z.position.x - 1.0)
		if onceki < INF and z.position.y < onceki - 2.0:
			ham.append(Vector2(z.position.x - 2.0, z.position.x + 10.0))

	return birlestir(ham)


## Tavandan sarkan engeller: [x0, x1, alt_y] (parçanın yerel koordinatında).
## Bunların altında yalnızca kısa zıplama güvenlidir.
func tavan_araliklari() -> Array:
	var sonuc := []
	for c in get_children():
		if c is Tehlike and c.tur == Tehlike.Tur.TAVAN:
			sonuc.append([c.position.x, c.position.x + c.genislik, c.position.y])
	return sonuc


static func birlestir(araliklar: Array[Vector2], bosluk := 8.0) -> Array[Vector2]:
	var s := araliklar.duplicate()
	s.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var sonuc: Array[Vector2] = []
	for a in s:
		if not sonuc.is_empty() and a.x <= sonuc[-1].y + bosluk:
			sonuc[-1].y = maxf(sonuc[-1].y, a.y)
		else:
			sonuc.append(a)
	return sonuc


func _yuzey_y(zeminler: Array[Zemin], x: float) -> float:
	var y := INF
	for z in zeminler:
		if not z.tek_yonlu and x >= z.position.x and x <= z.position.x + z.genislik:
			y = minf(y, z.position.y)
	return y
