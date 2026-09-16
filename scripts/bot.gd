class_name Bot
extends RefCounted
## Test ve demo için otomatik oyuncu. Önündeki tehlike aralıklarına bakıp
## zıplamanın ortasını tehlikenin ortasına denk getirir; inişi kötü görünürse
## havada ikinci kez zıplar.

var oyuncu: Oyuncu
## Dünya koordinatında, x'e göre sıralı tehlike aralıklarını döndüren fonksiyon.
var araliklar: Callable

var _basili := false


func _init(o: Oyuncu, a: Callable) -> void:
	oyuncu = o
	araliklar = a


func adim() -> void:
	var p := oyuncu
	if not p.canli:
		return
	var liste: Array = araliklar.call()
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
		var menzil := p.hiz * Ayarlar.tam_ziplama_suresi()
		var kalkis := minf((hedef.x + hedef.y) / 2.0 - menzil / 2.0, hedef.x - 10.0)
		if on >= kalkis and arka < hedef.y:
			p.zipla_bas()
			_basili = true
		return

	# Havada: tepe noktasından sonra iniş yeri tehlikeye denk geliyorsa ikinci zıplama.
	if p.velocity.y > 0.0 and p.havada_ziplama_hakki_var():
		var inis := _inis_x(p)
		for a in liste:
			if a.y < arka - 4.0:
				continue
			if inis + Oyuncu.YARIM_GENISLIK > a.x - 2.0 and inis - Oyuncu.YARIM_GENISLIK < a.y + 2.0:
				p.zipla_bas()
				_basili = true
				break
			if a.x > inis + 40.0:
				break


## Oyuncunun normal zemin hizasına ineceği x (yaklaşık).
func _inis_x(p: Oyuncu) -> float:
	var dy := Ayarlar.ZEMIN_Y - p.global_position.y
	if dy <= 0.0:
		return p.global_position.x
	var g := Ayarlar.YERCEKIMI
	var vy := p.velocity.y
	var t := (-vy + sqrt(vy * vy + 2.0 * g * dy)) / g
	return p.global_position.x + p.hiz * t
