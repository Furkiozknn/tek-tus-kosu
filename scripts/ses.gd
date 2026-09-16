class_name Ses
extends RefCounted
## Ses efektleri ve müzik. Sahne ağacında kendi düğümünü tembel olarak oluşturur;
## böylece otomatik yükleme (autoload) gerektirmez ve testlerde de çalışır.

const EFEKTLER := ["zipla", "ikinci", "indi", "altin", "yakin", "olum", "rekor", "gorev", "tik", "satin", "hata", "catirti"]
const HAVUZ := 6

static var _kok: Node
static var _oynaticilar: Array[AudioStreamPlayer] = []
static var _muzik: AudioStreamPlayer
static var _akislar := {}
static var _sira := 0


static func _hazirla() -> bool:
	if is_instance_valid(_kok):
		return true
	var agac := Engine.get_main_loop() as SceneTree
	if agac == null or agac.root == null:
		return false
	_veriyollari()
	_kok = Node.new()
	_kok.name = "SesYoneticisi"
	_kok.process_mode = Node.PROCESS_MODE_ALWAYS
	agac.root.add_child.call_deferred(_kok)
	_oynaticilar.clear()
	for i in HAVUZ:
		var o := AudioStreamPlayer.new()
		o.bus = "Efekt"
		_kok.add_child(o)
		_oynaticilar.append(o)
	_muzik = AudioStreamPlayer.new()
	_muzik.bus = "Muzik"
	_muzik.finished.connect(func() -> void: _muzik.play())
	_kok.add_child(_muzik)
	ses_duzeyi_uygula()
	return true


static func _veriyollari() -> void:
	for ad in ["Muzik", "Efekt"]:
		if AudioServer.get_bus_index(ad) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, ad)
			AudioServer.set_bus_send(i, "Master")


static func ses_duzeyi_uygula() -> void:
	_veriyollari()
	var a: Dictionary = Kayit.yukle()["ayarlar"]
	for cift in [["Muzik", float(a["muzik"])], ["Efekt", float(a["efekt"])]]:
		var i := AudioServer.get_bus_index(cift[0])
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(cift[1], 0.0001)))
		AudioServer.set_bus_mute(i, cift[1] <= 0.001)


static func _akis(ad: String) -> AudioStream:
	if not _akislar.has(ad):
		var yol := "res://assets/audio/%s.wav" % ad
		_akislar[ad] = load(yol) if ResourceLoader.exists(yol) else null
	return _akislar[ad]


static func cal(ad: String, perde := 1.0) -> void:
	if not _hazirla():
		return
	var akis := _akis(ad)
	if akis == null:
		return
	var o := _oynaticilar[_sira % HAVUZ]
	_sira += 1
	if not o.is_inside_tree():
		return
	o.stream = akis
	o.pitch_scale = perde
	o.play()


## bastan: çalıyor olsa da baştan başlat (ritim koşusu vuruş ızgarasını müziğin başına hizalar).
static func muzik(ad: String, bastan := false) -> void:
	if not _hazirla():
		return
	var akis := _akis(ad)
	if akis == null:
		return
	if not _muzik.is_inside_tree():
		(func() -> void: muzik(ad, bastan)).call_deferred()
		return
	_dongu_yap(akis)
	_muzik.stream_paused = false
	if _muzik.stream == akis and _muzik.playing and not bastan:
		return
	_muzik.stream = akis
	_muzik.play()


## Müziği duraklat / sürdür (ritim koşusunda duraklatınca vuruş kaymasın diye).
static func muzik_duraklat(dur: bool) -> void:
	if is_instance_valid(_muzik):
		_muzik.stream_paused = dur


## Çalan müziğin şu an karıştırılan konumu (sn); çalmıyorsa -1. Döngü başa sarınca küçülür.
static func muzik_konumu() -> float:
	if not is_instance_valid(_muzik) or not _muzik.playing or _muzik.stream_paused or _muzik.stream == null:
		return -1.0
	return _muzik.get_playback_position() + AudioServer.get_time_since_last_mix()


static func muzik_uzunlugu() -> float:
	if not is_instance_valid(_muzik) or _muzik.stream == null:
		return 0.0
	return _muzik.stream.get_length()


## Müziği verilen konuma sar (ritim koşusunda oyun zamanıyla yeniden hizalamak için).
static func muzik_sar(saniye: float) -> void:
	if is_instance_valid(_muzik) and _muzik.playing:
		_muzik.seek(maxf(saniye, 0.0))


## WAV'ı örnek düzeyinde kesintisiz döngüye al ("finished → play" her turda bir kare kaydırıyordu).
static func _dongu_yap(akis: AudioStream) -> void:
	var w := akis as AudioStreamWAV
	if w == null or w.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		return
	# İçe aktarılan müzik QOA sıkıştırmalı: veri boyutu örnek sayısı değil, uzunluktan hesapla.
	w.loop_begin = 0
	w.loop_end = int(floor(w.get_length() * w.mix_rate))
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
