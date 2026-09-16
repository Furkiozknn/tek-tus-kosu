extends SceneTree
## Ses efekti üretici (sfxr benzeri küçük sentezleyici). Harici araç gerekmez.
##   godot --headless --path . -s res://tools/ses_uret.gd
## Çıktı: assets/audio/<ad>.wav (22050 Hz, 16 bit, mono). Sabit tohum → her seferinde aynı ses.

const HZ := 22050

## dalga: kare | testere | sinus | gurultu
## f: başlangıç frekansı, kayma: saniyede frekans çarpanı (1 = sabit)
## arp: [[saniye, carpan], ...] belirli anda frekansı çarpar
const EFEKTLER := {
	"zipla":  {"dalga": "kare", "duty": 0.5, "f": 290.0, "kayma": 3.4, "atak": 0.004, "surdur": 0.05, "sonum": 0.11, "ses": 0.55},
	"ikinci": {"dalga": "kare", "duty": 0.25, "f": 520.0, "kayma": 4.5, "atak": 0.003, "surdur": 0.04, "sonum": 0.10, "ses": 0.5, "vib": [0.04, 30.0]},
	"indi":   {"dalga": "gurultu", "f": 180.0, "kayma": 0.5, "atak": 0.001, "surdur": 0.01, "sonum": 0.06, "ses": 0.35, "lp": 0.2},
	"altin":  {"dalga": "kare", "duty": 0.5, "f": 988.0, "kayma": 1.0, "atak": 0.002, "surdur": 0.05, "sonum": 0.16, "ses": 0.45, "arp": [[0.05, 1.335]]},
	"yakin":  {"dalga": "kare", "duty": 0.25, "f": 1320.0, "kayma": 1.6, "atak": 0.002, "surdur": 0.03, "sonum": 0.07, "ses": 0.4, "arp": [[0.035, 1.5]]},
	"olum":   {"dalga": "gurultu", "f": 520.0, "kayma": 0.12, "atak": 0.002, "surdur": 0.06, "sonum": 0.45, "ses": 0.7, "lp": 0.5, "ek": "olum_ton"},
	"olum_ton": {"dalga": "kare", "duty": 0.5, "f": 420.0, "kayma": 0.2, "atak": 0.002, "surdur": 0.05, "sonum": 0.35, "ses": 0.35},
	"rekor":  {"dalga": "kare", "duty": 0.5, "f": 523.0, "kayma": 1.0, "atak": 0.003, "surdur": 0.3, "sonum": 0.25, "ses": 0.45, "arp": [[0.08, 1.26], [0.16, 1.19], [0.24, 1.335]]},
	"gorev":  {"dalga": "kare", "duty": 0.25, "f": 392.0, "kayma": 2.6, "atak": 0.005, "surdur": 0.18, "sonum": 0.2, "ses": 0.45, "vib": [0.05, 18.0]},
	"tik":    {"dalga": "kare", "duty": 0.5, "f": 880.0, "kayma": 1.0, "atak": 0.001, "surdur": 0.015, "sonum": 0.03, "ses": 0.35},
	"satin":  {"dalga": "kare", "duty": 0.5, "f": 660.0, "kayma": 1.0, "atak": 0.002, "surdur": 0.06, "sonum": 0.2, "ses": 0.45, "arp": [[0.06, 1.5], [0.12, 1.335]]},
	"hata":   {"dalga": "testere", "f": 180.0, "kayma": 0.8, "atak": 0.002, "surdur": 0.08, "sonum": 0.08, "ses": 0.4},
}

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	rng.seed = 7
	var klasor := ProjectSettings.globalize_path("res://assets/audio")
	DirAccess.make_dir_recursive_absolute(klasor)
	var sayi := 0
	for ad in EFEKTLER:
		if ad.ends_with("_ton"):
			continue
		var t := EFEKTLER[ad] as Dictionary
		var ornek := _sentez(t)
		if t.has("ek"):
			var ek := _sentez(EFEKTLER[t["ek"]])
			for i in mini(ek.size(), ornek.size()):
				ornek[i] += ek[i]
		var w := _wav(ornek)
		var e := w.save_to_wav(klasor.path_join(ad + ".wav"))
		if e != OK:
			push_error("Kaydedilemedi: " + ad)
		sayi += 1
	print("Ses efektleri üretildi: %d" % sayi)
	quit(0)


func _sentez(t: Dictionary) -> PackedFloat32Array:
	var sure: float = t["atak"] + t["surdur"] + t["sonum"]
	var n := int(sure * HZ)
	var out := PackedFloat32Array()
	out.resize(n)
	var f: float = t["f"]
	var faz := 0.0
	var lp := 0.0
	var arp: Array = t.get("arp", [])
	var arp_i := 0
	var kayma_adim := pow(float(t["kayma"]), 1.0 / HZ)
	var vib: Array = t.get("vib", [0.0, 0.0])
	for i in n:
		var zaman := float(i) / HZ
		while arp_i < arp.size() and zaman >= float(arp[arp_i][0]):
			f *= float(arp[arp_i][1])
			arp_i += 1
		f *= kayma_adim
		var fv := f * (1.0 + float(vib[0]) * sin(TAU * float(vib[1]) * zaman))
		faz = fposmod(faz + fv / HZ, 1.0)
		var x := 0.0
		match t["dalga"]:
			"kare":
				x = 1.0 if faz < float(t.get("duty", 0.5)) else -1.0
			"testere":
				x = 2.0 * faz - 1.0
			"sinus":
				x = sin(TAU * faz)
			"gurultu":
				x = rng.randf_range(-1.0, 1.0)
		if t.has("lp"):
			lp = lerpf(lp, x, float(t["lp"]))
			x = lp
		var zarf := 1.0
		if zaman < t["atak"]:
			zarf = zaman / t["atak"]
		elif zaman > t["atak"] + t["surdur"]:
			zarf = 1.0 - (zaman - t["atak"] - t["surdur"]) / t["sonum"]
		out[i] = x * zarf * zarf * float(t["ses"])
	return out


func _wav(ornek: PackedFloat32Array) -> AudioStreamWAV:
	var veri := PackedByteArray()
	veri.resize(ornek.size() * 2)
	for i in ornek.size():
		veri.encode_s16(i * 2, int(clampf(ornek[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = HZ
	w.stereo = false
	w.data = veri
	return w
