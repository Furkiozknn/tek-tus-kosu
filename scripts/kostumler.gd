class_name Kostumler
extends RefCounted
## Toplam altınla açılan karakter görünümleri.

const LISTE := [
	{"ad": "klasik", "isim": "Klasik", "fiyat": 0},
	{"ad": "kizil", "isim": "Kızıl Bere", "fiyat": 60},
	{"ad": "orman", "isim": "Orman", "fiyat": 150},
	{"ad": "neon", "isim": "Neon", "fiyat": 300},
	{"ad": "altin", "isim": "Altın Taç", "fiyat": 600},
]
const KARE := Vector2i(20, 26)

static var _onbellek := {}


static func bilgi(ad: String) -> Dictionary:
	for k in LISTE:
		if k["ad"] == ad:
			return k
	return LISTE[0]


## Kostüm şeridinden animasyonlar: kos, zipla, dus, takla, bekle, olum
static func kareler(ad: String) -> SpriteFrames:
	if _onbellek.has(ad):
		return _onbellek[ad]
	var yol := "res://assets/sprites/oyuncu_%s.png" % ad
	if not ResourceLoader.exists(yol):
		yol = "res://assets/sprites/oyuncu_klasik.png"
	var doku: Texture2D = load(yol)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var tanimlar := {
		"kos": [[0, 1, 2, 3, 4, 5, 6, 7], 14.0, true],
		"zipla": [[8], 1.0, false],
		"dus": [[9], 1.0, false],
		"takla": [[10, 11], 12.0, true],
		"bekle": [[12, 13], 3.0, true],
		"olum": [[14], 1.0, false],
	}
	for anim in tanimlar:
		sf.add_animation(anim)
		sf.set_animation_speed(anim, tanimlar[anim][1])
		sf.set_animation_loop(anim, tanimlar[anim][2])
		for i in tanimlar[anim][0]:
			var at := AtlasTexture.new()
			at.atlas = doku
			at.region = Rect2(i * KARE.x, 0, KARE.x, KARE.y)
			sf.add_frame(anim, at)
	_onbellek[ad] = sf
	return sf


## Satın alma: başarılıysa true (kayıt sözlüğünü günceller, kaydetmez).
static func satin_al(d: Dictionary, ad: String) -> bool:
	var k := bilgi(ad)
	if (d["acik_kostumler"] as Array).has(ad):
		return true
	if int(d["toplam_altin"]) < int(k["fiyat"]):
		return false
	d["toplam_altin"] = int(d["toplam_altin"]) - int(k["fiyat"])
	d["acik_kostumler"].append(ad)
	return true
