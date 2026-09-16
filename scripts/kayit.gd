class_name Kayit
extends RefCounted
## Rekor ve toplam altını user://kayit.cfg dosyasında tutar.

static var yol := "user://kayit.cfg"


static func yukle() -> Dictionary:
	var sonuc := {"rekor": 0, "toplam_altin": 0}
	var cfg := ConfigFile.new()
	if cfg.load(yol) == OK:
		sonuc["rekor"] = int(cfg.get_value("skor", "rekor", 0))
		sonuc["toplam_altin"] = int(cfg.get_value("skor", "toplam_altin", 0))
	return sonuc


## Bir koşunun sonucunu kaydeder. Dönüş: güncel kayıt + "yeni_rekor".
static func kosu_kaydet(mesafe: int, altin: int) -> Dictionary:
	var d := yukle()
	var yeni_rekor: bool = mesafe > int(d["rekor"])
	d["rekor"] = maxi(int(d["rekor"]), mesafe)
	d["toplam_altin"] = int(d["toplam_altin"]) + altin
	var cfg := ConfigFile.new()
	cfg.set_value("skor", "rekor", d["rekor"])
	cfg.set_value("skor", "toplam_altin", d["toplam_altin"])
	cfg.save(yol)
	d["yeni_rekor"] = yeni_rekor
	return d
