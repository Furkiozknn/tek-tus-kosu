class_name Gorevler
extends RefCounted
## Görev sistemi: aynı anda 3 görev (kısa / orta / uzun). "tek_" görevler tek koşuda,
## "top_" görevler koşular boyunca birikir. Her 3 tamamlanan görevde oyuncu seviyesi artar.
## Saf fonksiyonlar: kayıt sözlüğü (Kayit.yukle()) üzerinde çalışır, testlenebilir.

const SURELER := ["kisa", "orta", "uzun"]

## anahtar: koşu istatistiği adı (mesafe, altin, ikinci, yakin, kosu)
const SABLONLAR := {
	"kisa": [
		{"id": "k_mesafe", "anahtar": "mesafe", "tek": true, "taban": 120, "artis": 60, "metin": "Tek koşuda %d m koş"},
		{"id": "k_altin", "anahtar": "altin", "tek": true, "taban": 10, "artis": 5, "metin": "Tek koşuda %d altın topla"},
		{"id": "k_ikinci", "anahtar": "ikinci", "tek": true, "taban": 3, "artis": 2, "metin": "Tek koşuda %d kez havada zıpla"},
		{"id": "k_yakin", "anahtar": "yakin", "tek": true, "taban": 2, "artis": 1, "metin": "Tek koşuda %d kez kıl payı kaç"},
	],
	"orta": [
		{"id": "o_altin", "anahtar": "altin", "tek": false, "taban": 60, "artis": 40, "metin": "Toplam %d altın topla"},
		{"id": "o_kosu", "anahtar": "kosu", "tek": false, "taban": 5, "artis": 3, "metin": "%d koşu tamamla"},
		{"id": "o_yakin", "anahtar": "yakin", "tek": false, "taban": 8, "artis": 5, "metin": "Toplam %d kıl payı kaçış"},
		{"id": "o_mesafe", "anahtar": "mesafe", "tek": true, "taban": 350, "artis": 120, "metin": "Tek koşuda %d m koş"},
	],
	"uzun": [
		{"id": "u_mesafe", "anahtar": "mesafe", "tek": false, "taban": 2500, "artis": 1500, "metin": "Toplam %d m koş"},
		{"id": "u_tek", "anahtar": "mesafe", "tek": true, "taban": 700, "artis": 250, "metin": "Tek koşuda %d m koş"},
		{"id": "u_ikinci", "anahtar": "ikinci", "tek": false, "taban": 40, "artis": 25, "metin": "Toplam %d kez havada zıpla"},
		{"id": "u_altin", "anahtar": "altin", "tek": true, "taban": 40, "artis": 15, "metin": "Tek koşuda %d altın topla"},
	],
}
const ODUL := {"kisa": 20, "orta": 50, "uzun": 120}


static func bos_istatistik() -> Dictionary:
	return {"mesafe": 0, "altin": 0, "ikinci": 0, "yakin": 0, "kosu": 0, "tavan": 0, "piston": 0, "iskele": 0, "ritim": 0}


static func yeni_gorev(sure: String, seviye: int, haric: Array, rng: RandomNumberGenerator) -> Dictionary:
	var adaylar: Array = []
	for s in SABLONLAR[sure]:
		if not haric.has(s["id"]):
			adaylar.append(s)
	if adaylar.is_empty():
		adaylar = SABLONLAR[sure].duplicate()
	var s: Dictionary = adaylar[rng.randi_range(0, adaylar.size() - 1)]
	var hedef := int(s["taban"]) + int(s["artis"]) * (seviye - 1)
	return {
		"id": s["id"], "sure": sure, "anahtar": s["anahtar"], "tek": s["tek"],
		"hedef": hedef, "ilerleme": 0, "odul": int(ODUL[sure]) * seviye,
		"metin": String(s["metin"]) % hedef,
	}


## Kayıtta eksik görev varsa tamamlar (her süreden bir tane).
static func hazirla(d: Dictionary, rng: RandomNumberGenerator) -> void:
	var liste: Array = d["gorevler"]
	for sure in SURELER:
		var var_mi := false
		for g in liste:
			if g.get("sure") == sure:
				var_mi = true
		if not var_mi:
			liste.append(yeni_gorev(sure, int(d["gorev_seviyesi"]), _idler(liste), rng))
	liste.sort_custom(func(a, b) -> bool: return SURELER.find(a["sure"]) < SURELER.find(b["sure"]))
	d["gorevler"] = liste


static func _idler(liste: Array) -> Array:
	var sonuc := []
	for g in liste:
		sonuc.append(g["id"])
	return sonuc


## Koşu sürerken görevin şu anki değeri (tamamlanma kontrolü için).
static func anlik_deger(g: Dictionary, ist: Dictionary) -> int:
	var v := int(ist.get(g["anahtar"], 0))
	return v if g["tek"] else int(g["ilerleme"]) + v


static func tamam_mi(g: Dictionary, ist: Dictionary) -> bool:
	return anlik_deger(g, ist) >= int(g["hedef"])


## Koşu bitince ilerlemeyi işler, ödülleri verir, biten görevleri yeniler.
## Dönüş: {"tamamlanan": [görev...], "odul": toplam, "seviye_atladi": bool}
static func kosu_sonu(d: Dictionary, ist: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var sonuc := {"tamamlanan": [], "odul": 0, "seviye_atladi": false}
	var yeni_liste: Array = []
	for g in d["gorevler"]:
		var deger := anlik_deger(g, ist)
		if deger >= int(g["hedef"]):
			sonuc["tamamlanan"].append(g)
			sonuc["odul"] += int(g["odul"])
		else:
			g["ilerleme"] = deger if not g["tek"] else maxi(int(g["ilerleme"]), deger)
			yeni_liste.append(g)
	d["toplam_altin"] = int(d["toplam_altin"]) + int(sonuc["odul"])
	var onceki := int(d["tamamlanan_gorev"])
	d["tamamlanan_gorev"] = onceki + sonuc["tamamlanan"].size()
	var yeni_seviye := 1 + int(d["tamamlanan_gorev"]) / 3
	if yeni_seviye > int(d["gorev_seviyesi"]):
		d["gorev_seviyesi"] = yeni_seviye
		sonuc["seviye_atladi"] = true
	d["gorevler"] = yeni_liste
	var haric := _idler(yeni_liste)
	for g in sonuc["tamamlanan"]:
		haric.append(g["id"])
	for g in sonuc["tamamlanan"]:
		var yg := yeni_gorev(g["sure"], int(d["gorev_seviyesi"]), haric, rng)
		haric.append(yg["id"])
		d["gorevler"].append(yg)
	hazirla(d, rng)
	return sonuc


static func metin(g: Dictionary, ist := {}) -> String:
	var deger := mini(anlik_deger(g, ist), int(g["hedef"]))
	return "%s  (%d/%d)" % [g["metin"], deger, int(g["hedef"])]
