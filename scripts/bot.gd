class_name Bot
extends RefCounted
## Test ve demo için otomatik oyuncu. Önündeki tehlike aralıklarına bakıp
## zıplamanın ortasını tehlikenin ortasına denk getirir; inişi kötü görünürse
## havada ikinci kez zıplar. Tavandan sarkan engelin altındaysa kısa zıplar.

var oyuncu: Oyuncu
## Dünya koordinatında, x'e göre sıralı tehlike aralıklarını döndüren fonksiyon.
var araliklar: Callable
## Dünya koordinatında tavan aralıkları [x0, x1, alt_y] döndüren fonksiyon (isteğe bağlı).
var tavanlar: Callable

var _basili := false
var _kisa := false


func _init(o: Oyuncu, a: Callable, t: Callable = Callable()) -> void:
	oyuncu = o
	araliklar = a
	tavanlar = t


func adim() -> void:
	var p := oyuncu
	if not p.canli:
		return
	# Kısa zıplama: basıldıktan bir kare sonra bırak.
	if _kisa and _basili and not p.is_on_floor():
		p.zipla_birak()
		_basili = false
		_kisa = false
	var liste: Array = araliklar.call()
	var tavan: Array = tavanlar.call() if tavanlar.is_valid() else []
	var on := p.global_position.x + Oyuncu.YARIM_GENISLIK
	var arka := p.global_position.x - Oyuncu.YARIM_GENISLIK
	var hedef = null
	for a in liste:
		if a.y > arka:
			hedef = a
			break

	if p.is_on_floor():
		if _basili and p.velocity.y >= 0.0:
			p.zipla_birak()
			_basili = false
		if hedef == null:
			return
		var tam_menzil := p.hiz * Ayarlar.tam_ziplama_suresi()
		var kisa_menzil := p.hiz * (Ayarlar.kisa_ziplama_suresi() + 0.03)
		var orta: float = (hedef.x + hedef.y) / 2.0
		# Tam zıplamanın yayı bir tavanın altına giriyorsa kısa zıpla.
		var tam_kalkis: float = minf(orta - tam_menzil / 2.0, hedef.x - 10.0)
		var kisa_gerek := _tavan_var(tavan, tam_kalkis - 10.0, tam_kalkis + tam_menzil + 10.0, p)
		var menzil := kisa_menzil if kisa_gerek else tam_menzil
		var kalkis: float = minf(orta - menzil / 2.0, hedef.x - 6.0)
		if on >= kalkis and arka < hedef.y:
			p.zipla_bas()
			_basili = true
			_kisa = kisa_gerek
		return

	# Havada: tepe noktasından sonra iniş yeri tehlikeye denk geliyorsa ikinci zıplama
	# (tavanın altında değilsek).
	if p.velocity.y > 0.0 and p.havada_ziplama_hakki_var():
		var inis := _inis_x(p)
		if _tavan_var(tavan, p.global_position.x - 10.0, inis + 120.0, p):
			return
		for a in liste:
			if a.y < arka - 4.0:
				continue
			if inis + Oyuncu.YARIM_GENISLIK > a.x - 2.0 and inis - Oyuncu.YARIM_GENISLIK < a.y + 2.0:
				p.zipla_bas()
				_basili = true
				break
			if a.x > inis + 40.0:
				break


## [x0, x1] aralığında, tam zıplamada kafanın değeceği yükseklikte tavan var mı?
func _tavan_var(tavan: Array, x0: float, x1: float, p: Oyuncu) -> bool:
	for t in tavan:
		if t[1] < x0 or t[0] > x1:
			continue
		var tam_tepe: float = p.global_position.y - Oyuncu.BOY - (Ayarlar.ZIPLAMA_HIZI * Ayarlar.ZIPLAMA_HIZI) / (2.0 * Ayarlar.YERCEKIMI)
		if t[2] > tam_tepe - 4.0:
			return true
	return false


## Oyuncunun normal zemin hizasına ineceği x (yaklaşık).
func _inis_x(p: Oyuncu) -> float:
	var dy := Ayarlar.ZEMIN_Y - p.global_position.y
	if dy <= 0.0:
		return p.global_position.x
	var g := Ayarlar.YERCEKIMI
	var vy := p.velocity.y
	var t := (-vy + sqrt(vy * vy + 2.0 * g * dy)) / g
	return p.global_position.x + p.hiz * t
