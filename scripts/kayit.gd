class_name Kayit
extends RefCounted
## Kalıcı oyuncu verisi (user://kayit.cfg) + otomatik yedek (kayit.yedek.cfg).
## Ana dosya bozulursa yedekten okunur.

static var yol := "user://kayit.cfg"

const VARSAYILAN := {
	"rekor": 0,
	"rekor_rahat": 0,
	"rekor_ritim": 0,
	"rekor_ritim2": 0,
	"rekor_ritim3": 0,
	"toplam_altin": 0,
	"kostum": "klasik",
	"acik_kostumler": ["klasik"],
	"gorevler": [],
	"gorev_seviyesi": 1,
	"tamamlanan_gorev": 0,
	"kosu_sayisi": 0,
	"toplam_mesafe": 0,
	"basarimlar": [],
	"olumler": [],
	"olumler_rahat": [],
	"olumler_ritim": [],
	"olumler_ritim2": [],
	"olumler_ritim3": [],
	"gunluk": {"tarih": "", "rekor": 0, "deneme": 0, "olumler": []},
	"gunluk_seri": {"son": "", "seri": 0, "en_iyi": 0},
	"gunluk_ritim": {"tarih": "", "rekor": 0, "deneme": 0, "olumler": []},
	"gunluk_ritim_gecmis": [],
	"ayarlar": {"muzik": 0.7, "efekt": 0.9, "tam_ekran": false, "sarsinti": true, "kontrast": false, "rahat": false, "titresim": true, "ritim_gecikme": 0, "ritim_ipucu": true},
}


static func yedek_yolu() -> String:
	return yol.get_basename() + ".yedek.cfg"


static func yukle() -> Dictionary:
	var d := VARSAYILAN.duplicate(true)
	var cfg := ConfigFile.new()
	var e := cfg.load(yol)
	if e != OK or not cfg.has_section("oyuncu"):
		cfg = ConfigFile.new()
		if cfg.load(yedek_yolu()) != OK:
			return d
	for k in d:
		if cfg.has_section_key("oyuncu", k):
			var v = cfg.get_value("oyuncu", k)
			if typeof(v) == typeof(d[k]) or (typeof(d[k]) == TYPE_INT and typeof(v) == TYPE_FLOAT):
				if d[k] is Dictionary:
					for alt in v:
						d[k][alt] = v[alt]
				else:
					d[k] = v
	# Eski (prototip) biçimi: [skor] bölümü
	if cfg.has_section("skor"):
		d["rekor"] = maxi(int(d["rekor"]), int(cfg.get_value("skor", "rekor", 0)))
		d["toplam_altin"] = maxi(int(d["toplam_altin"]), int(cfg.get_value("skor", "toplam_altin", 0)))
	return d


static func kaydet(d: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for k in d:
		if VARSAYILAN.has(k):
			cfg.set_value("oyuncu", k, d[k])
	cfg.save(yol)
	cfg.save(yedek_yolu())


## Bir koşunun sonucunu kaydeder. Dönüş: güncel kayıt + "yeni_rekor".
static func kosu_kaydet(mesafe: int, altin: int, rahat := false) -> Dictionary:
	var d := yukle()
	var anahtar := "rekor_rahat" if rahat else "rekor"
	var yeni_rekor: bool = mesafe > int(d[anahtar])
	d[anahtar] = maxi(int(d[anahtar]), mesafe)
	d["toplam_altin"] = int(d["toplam_altin"]) + altin
	d["kosu_sayisi"] = int(d["kosu_sayisi"]) + 1
	d["toplam_mesafe"] = int(d["toplam_mesafe"]) + mesafe
	kaydet(d)
	d["yeni_rekor"] = yeni_rekor
	return d


static func ayar(ad: String):
	return yukle()["ayarlar"].get(ad, VARSAYILAN["ayarlar"].get(ad))


static func ayar_yaz(ad: String, deger) -> void:
	var d := yukle()
	d["ayarlar"][ad] = deger
	kaydet(d)
