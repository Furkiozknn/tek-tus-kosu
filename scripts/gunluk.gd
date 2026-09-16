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


# ------------------------------------------------------------------ v0.4: seri ve paylaşım
## Verilen tarihten ("YYYY-AA-GG") bir önceki gün. Saat dilimi kullanılmaz (UTC içinde gidip gelir).
static func dun(tarih: String) -> String:
	var t := Time.get_unix_time_from_datetime_string(tarih + "T12:00:00")
	return Time.get_date_string_from_unix_time(t - 86400)


## Bugün günlük koşu yapıldı: art arda gün serisini günceller. Dönüş: güncel seri.
static func seri_isle(d: Dictionary) -> int:
	var s: Dictionary = d.get("gunluk_seri", {})
	var bugun_ := bugun()
	var son := str(s.get("son", ""))
	if son == bugun_:
		s["seri"] = maxi(int(s.get("seri", 0)), 1)
	elif son == dun(bugun_):
		s["seri"] = int(s.get("seri", 0)) + 1
	else:
		s["seri"] = 1
	s["son"] = bugun_
	s["en_iyi"] = maxi(int(s.get("en_iyi", 0)), int(s["seri"]))
	d["gunluk_seri"] = s
	return int(s["seri"])


## Süren seri (bugün ya da dün koşulduysa); koptuysa 0.
static func seri(d: Dictionary) -> int:
	var s: Dictionary = d.get("gunluk_seri", {})
	var son := str(s.get("son", ""))
	if son == bugun() or son == dun(bugun()):
		return int(s.get("seri", 0))
	return 0


## Panoya/paylaşıma gidecek kısa sonuç metni. Şerit: bu koşunun günün rekoruna oranı.
static func paylasim_metni(tarih: String, mesafe: int, deneme: int, rekor: int, yeni_rekor: bool, seri_: int, kip := "Günlük") -> String:
	var p := tarih.split("-")
	var gun := "%s.%s.%s" % [p[2], p[1], p[0]] if p.size() == 3 else tarih
	var en := maxi(rekor, mesafe)
	var hucre := Ayarlar.PAYLAS_SERIT
	var dolu := hucre
	if en > 0:
		dolu = clampi(int(round(float(hucre) * mesafe / en)), 0, hucre)
	var satirlar: Array[String] = ["Tek Tuş Koşu · %s %s" % [kip, gun]]
	satirlar.append("%d m · %d. deneme%s" % [mesafe, deneme, "  · günün rekoru!" if yeni_rekor else ""])
	satirlar.append("■".repeat(dolu) + "□".repeat(hucre - dolu) + ("" if yeni_rekor else "  rekor %d m" % en))
	if seri_ >= 2:
		satirlar.append("Seri: %d gün" % seri_)
	if Ayarlar.ITCH_ADRESI != "":
		satirlar.append(Ayarlar.ITCH_ADRESI)
	return "\n".join(satirlar)
