class_name Hayalet
extends RefCounted
## Günlük koşunun en iyi denemesini saniyede Ayarlar.HAYALET_HZ kez örnekler,
## kaydeder ve sonraki denemelerde yarı saydam bir rakip olarak geri oynatır.
## Günlük koşuda parça dizisi aynı olduğundan hayalet aynı çatılardan geçer.

const ANIMLER := ["kos", "zipla", "dus", "takla", "olum", "bekle"]

var tarih := ""
var mesafe := 0
var x := PackedFloat32Array()
var y := PackedFloat32Array()
var anim := PackedByteArray()


static func dosya_yolu() -> String:
	return Kayit.yol.get_basename() + ".hayalet.cfg"


func ekle(konum: Vector2, anim_adi: String) -> void:
	x.append(konum.x)
	y.append(konum.y)
	anim.append(maxi(ANIMLER.find(anim_adi), 0))


func sayi() -> int:
	return x.size()


func sure() -> float:
	return float(sayi()) / Ayarlar.HAYALET_HZ


## t saniyedeki konum (başlangıca göre). Örnekler arasında doğrusal ara değer.
func konum(t: float) -> Vector2:
	if sayi() == 0:
		return Vector2.ZERO
	var f := clampf(t * Ayarlar.HAYALET_HZ, 0.0, float(sayi() - 1))
	var i := int(f)
	var j := mini(i + 1, sayi() - 1)
	var k := f - i
	return Vector2(lerpf(x[i], x[j], k), lerpf(y[i], y[j], k))


func anim_adi(t: float) -> String:
	if sayi() == 0:
		return "kos"
	var i := clampi(int(t * Ayarlar.HAYALET_HZ), 0, sayi() - 1)
	return ANIMLER[anim[i]]


func kaydet() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("hayalet", "tarih", tarih)
	cfg.set_value("hayalet", "mesafe", mesafe)
	cfg.set_value("hayalet", "x", x)
	cfg.set_value("hayalet", "y", y)
	cfg.set_value("hayalet", "anim", anim)
	return cfg.save(dosya_yolu())


## Verilen tarihe ait kayıtlı hayalet; yoksa ya da başka güne aitse null.
static func yukle(istenen_tarih: String) -> Hayalet:
	var cfg := ConfigFile.new()
	if cfg.load(dosya_yolu()) != OK:
		return null
	if str(cfg.get_value("hayalet", "tarih", "")) != istenen_tarih:
		return null
	var h := Hayalet.new()
	h.tarih = istenen_tarih
	h.mesafe = int(cfg.get_value("hayalet", "mesafe", 0))
	var vx = cfg.get_value("hayalet", "x", PackedFloat32Array())
	var vy = cfg.get_value("hayalet", "y", PackedFloat32Array())
	var va = cfg.get_value("hayalet", "anim", PackedByteArray())
	if not (vx is PackedFloat32Array and vy is PackedFloat32Array and va is PackedByteArray):
		return null
	if vx.size() != vy.size() or vx.size() != va.size():
		return null
	h.x = vx
	h.y = vy
	h.anim = va
	return h
