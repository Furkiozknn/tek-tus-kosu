class_name Gunluk
extends RefCounted
## Günlük koşu: tarihten türeyen tohumla o gün herkes aynı parça dizisini koşar.
## Günün rekoru, deneme sayısı ve ölüm yerleri kayıtta ayrı tutulur (kayıt anahtarı "gunluk").
## Gün değişince bu bilgiler sıfırlanır.

## Menüden oyuna geçerken seçilen kip (true = günlük koşu).
static var secili := false
## Testler tarihi sabitleyebilsin diye; boşsa sistem tarihi kullanılır.
static var tarih_ezme := ""


static func bugun() -> String:
	if tarih_ezme != "":
		return tarih_ezme
	var t := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [t["year"], t["month"], t["day"]]


## Aynı tarih her platformda aynı tohumu verir (String.hash belirlenimcidir).
static func tohum(tarih: String) -> int:
	return absi(("tek-tus-kosu/" + tarih).hash())


## Kayıttaki günlük bölümünü döndürür; tarih eskiyse önce sıfırlar.
static func durum(d: Dictionary) -> Dictionary:
	var g: Dictionary = d.get("gunluk", {})
	if str(g.get("tarih", "")) != bugun():
		g = {"tarih": bugun(), "rekor": 0, "deneme": 0, "olumler": []}
		d["gunluk"] = g
	return g


## Bir günlük koşunun sonucunu işler. Dönüş: günün yeni rekoru mu?
static func kosu_isle(d: Dictionary, mesafe: int) -> bool:
	var g := durum(d)
	g["deneme"] = int(g["deneme"]) + 1
	var olumler: Array = g.get("olumler", [])
	olumler.append(mesafe)
	while olumler.size() > Ayarlar.OLUM_ISARETI_SAYISI:
		olumler.pop_front()
	g["olumler"] = olumler
	var yeni := mesafe > int(g["rekor"])
	if yeni:
		g["rekor"] = mesafe
	return yeni
