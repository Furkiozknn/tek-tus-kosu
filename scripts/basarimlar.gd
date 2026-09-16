class_name Basarimlar
extends RefCounted
## Başarımlar: koşu sonunda denetlenir, açılan her biri Ayarlar.BASARIM_ODULU altın verir.
## "tek" olanlar koşu sırasında da denetlenip ekranda duyurulur.

const LISTE := [
	{"id": "ilk_kosu", "ad": "İlk adım", "metin": "Bir koşuyu bitir", "tek": false},
	{"id": "m500", "ad": "Çatı yolcusu", "metin": "Tek koşuda 500 m", "tek": true},
	{"id": "m1000", "ad": "Gece kuşu", "metin": "Tek koşuda 1000 m", "tek": true},
	{"id": "m2000", "ad": "Şehrin öbür ucu", "metin": "Tek koşuda 2000 m", "tek": true},
	{"id": "altin50", "ad": "Cepler dolu", "metin": "Tek koşuda 50 altın", "tek": true},
	{"id": "yakin10", "ad": "Kıl payı ustası", "metin": "Tek koşuda 10 kıl payı kaçış", "tek": true},
	{"id": "tavan10", "ad": "Eğil ve geç", "metin": "Tek koşuda 10 alçak tavan", "tek": true},
	{"id": "piston10", "ad": "Piston dansı", "metin": "Tek koşuda 10 piston", "tek": true},
	{"id": "iskele8", "ad": "Hafif adımlar", "metin": "Tek koşuda 8 çürük iskele", "tek": true},
	{"id": "ritim20", "ad": "Vuruşu yakala", "metin": "Ritim koşusunda 20 tam vuruş", "tek": true},
	{"id": "gunluk300", "ad": "Günün koşucusu", "metin": "Günlük koşuda 300 m", "tek": true},
	{"id": "toplam10k", "ad": "Maratoncu", "metin": "Toplam 10.000 m koş", "tek": false},
	{"id": "dolap", "ad": "Gardırop", "metin": "Bütün kostümleri aç", "tek": false},
]


static func tanim(id: String) -> Dictionary:
	for b in LISTE:
		if b["id"] == id:
			return b
	return {}


## ist: koşu istatistiği (Gorevler.bos_istatistik biçimi), gunluk: bu koşu günlük mü.
static func saglandi_mi(id: String, d: Dictionary, ist: Dictionary, gunluk: bool) -> bool:
	match id:
		"ilk_kosu":
			return int(d.get("kosu_sayisi", 0)) >= 1
		"m500":
			return int(ist.get("mesafe", 0)) >= 500
		"m1000":
			return int(ist.get("mesafe", 0)) >= 1000
		"m2000":
			return int(ist.get("mesafe", 0)) >= 2000
		"altin50":
			return int(ist.get("altin", 0)) >= 50
		"yakin10":
			return int(ist.get("yakin", 0)) >= 10
		"tavan10":
			return int(ist.get("tavan", 0)) >= 10
		"piston10":
			return int(ist.get("piston", 0)) >= 10
		"iskele8":
			return int(ist.get("iskele", 0)) >= 8
		"ritim20":
			return int(ist.get("ritim", 0)) >= 20
		"gunluk300":
			return gunluk and int(ist.get("mesafe", 0)) >= 300
		"toplam10k":
			return int(d.get("toplam_mesafe", 0)) >= 10000
		"dolap":
			return (d.get("acik_kostumler", []) as Array).size() >= Kostumler.LISTE.size()
	return false


## Koşu sırasında yeni sağlanan "tek" başarımlar (henüz kayıtta olmayanlar).
static func anlik(d: Dictionary, ist: Dictionary, gunluk: bool, bildirilen: Array) -> Array:
	var sonuc := []
	var acik: Array = d.get("basarimlar", [])
	for b in LISTE:
		if b["tek"] and not acik.has(b["id"]) and not bildirilen.has(b["id"]) and saglandi_mi(b["id"], d, ist, gunluk):
			sonuc.append(b)
	return sonuc


## Kayda işler, ödülü ekler. Dönüş: bu çağrıda açılan başarımların tanımları.
static func denetle(d: Dictionary, ist: Dictionary, gunluk: bool) -> Array:
	var sonuc := []
	var acik: Array = d.get("basarimlar", [])
	for b in LISTE:
		if acik.has(b["id"]):
			continue
		if saglandi_mi(b["id"], d, ist, gunluk):
			acik.append(b["id"])
			d["toplam_altin"] = int(d.get("toplam_altin", 0)) + Ayarlar.BASARIM_ODULU
			sonuc.append(b)
	d["basarimlar"] = acik
	return sonuc
