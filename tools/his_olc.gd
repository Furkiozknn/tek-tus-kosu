extends SceneTree
## Oyun hissi ölçümü (girdi gecikmesi, kojot, tampon). PENCERELİ ve gerçek zamanlı koşar
## (headless'ta Input.parse_input_event düğümlere ulaşmıyor; --fixed-fps verme):
##   godot --path . -s res://tools/his_olc.gd -- [deneme_sayisi]
## Çıktı satırları "HIS_OLCUM ..." ile başlar; sonuçlar docs/TASARIM.md'de.
##
## 1. GECIKME: tuş olayı -> zıplama sinyali (oyun mantığı) ve -> oyuncunun ilk hareketli karesi.
##    Olay Input.parse_input_event ile gönderilir (gerçek klavye gibi _unhandled_input'a ulaşır);
##    her denemede basış, fizik adımına göre rastgele bir fazda yapılır.
## 2. KOJOT: çatı kenarından düştükten k fizik karesi sonra basılırsa TAM güçte (ilk) zıplama mı,
##    havadaki (zayıf) ikinci zıplama mı? En büyük k * 16,67 ms = tam güç penceresi.
## 3. TAMPON: iki zıplama hakkı bitmişken yere değmeden k kare önce basılan zıplama, inişte
##    çalışıyor mu? En büyük k * 16,67 ms = tampon penceresi.

const OYUNCU_SAHNE := preload("res://scenes/oyuncu.tscn")
const KARE_MS := 1000.0 / 60.0

var _t0 := 0
var _yakalandi := false   ## lambda ilkel değişkeni değer olarak yakalar: üye değişken şart
var _sinyal_ms: Array[float] = []
var _hareket_ms: Array[float] = []


func _initialize() -> void:
	_kos.call_deferred()


func _kos() -> void:
	Kayit.yol = "user://his_kayit.cfg"
	var arg := OS.get_cmdline_user_args()
	var n := int(arg[0]) if arg.size() > 0 else 60
	await _gecikme(n)
	await _kojot()
	await _tampon()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.yol))
	quit(0)


func _zemin(x0: float, x1: float, dunya: Node) -> void:
	var z := Zemin.new()
	z.position = Vector2(x0, Ayarlar.ZEMIN_Y)
	z.genislik = x1 - x0
	z.yukseklik = 120.0
	dunya.add_child(z)


func _oyuncu(x: float, dunya: Node) -> Oyuncu:
	var o: Oyuncu = OYUNCU_SAHNE.instantiate()
	o.iz_acik = false
	dunya.add_child(o)
	o.sifirla(Vector2(x, Ayarlar.ZEMIN_Y))
	return o


func _olay(basildi: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = &"zipla"
	ev.pressed = basildi
	Input.parse_input_event(ev)


## Gerçek oyun sahnesi: _unhandled_input -> Oyuncu.zipla_bas yolunun tamamı.
func _gecikme(n: int) -> void:
	var oyun: Node2D = (load("res://scenes/oyun.tscn") as PackedScene).instantiate()
	oyun.kayit_yap = false
	oyun.olum_tekrari_acik = false
	oyun.sabit_hiz = 240.0
	var sira: Array[String] = ["res://scenes/parcalar/01_duz.tscn", "res://scenes/parcalar/01_duz.tscn", "res://scenes/parcalar/01_duz.tscn"]
	oyun.parca_sirasi = sira
	oyun.tohum = 1
	root.add_child(oyun)
	await process_frame
	await create_timer(0.6).timeout
	var o: Oyuncu = oyun.oyuncu
	o.olumsuz = true
	o.ziplandi.connect(func(_ik: bool) -> void:
		if _t0 > 0 and not _yakalandi:
			_yakalandi = true
			_sinyal_ms.append(float(Time.get_ticks_usec() - _t0) / 1000.0))
	for i in n:
		# yere in, rastgele fizik fazında bas
		while not o.is_on_floor():
			await physics_frame
		await create_timer(0.05 + randf() * 0.0167).timeout
		_yakalandi = false
		var y0 := o.global_position.y
		_t0 = Time.get_ticks_usec()
		_olay(true)
		var kalan := 0
		while o.global_position.y >= y0 - 0.01 and kalan < 30:
			await process_frame
			kalan += 1
		if o.global_position.y < y0 - 0.01 and _yakalandi:
			_hareket_ms.append(float(Time.get_ticks_usec() - _t0) / 1000.0)
		_olay(false)
		_t0 = 0
		await create_timer(0.35).timeout
	_yaz("GECIKME_SINYAL", _sinyal_ms)
	_yaz("GECIKME_HAREKET", _hareket_ms)
	oyun.queue_free()
	await process_frame


func _yaz(ad: String, olcu: Array[float]) -> void:
	if olcu.is_empty():
		print("HIS_OLCUM %s deneme=0" % ad)
		return
	olcu.sort()
	var top := 0.0
	for x in olcu:
		top += x
	print("HIS_OLCUM %s deneme=%d ort_ms=%.1f p95_ms=%.1f en_yuksek_ms=%.1f en_dusuk_ms=%.1f" % [
		ad, olcu.size(), top / olcu.size(), olcu[int(olcu.size() * 0.95)], olcu[olcu.size() - 1], olcu[0]])


func _kojot() -> void:
	var enbuyuk := -1
	var satir := ""
	for k in range(0, 14):
		var dunya := Node2D.new()
		root.add_child(dunya)
		_zemin(0.0, 300.0, dunya)
		var o := _oyuncu(240.0, dunya)
		o.hiz = 300.0
		o.olumsuz = true
		var havada := -1
		var tam := false
		for kare in 200:
			await physics_frame
			if not o.is_on_floor() and havada < 0:
				havada = 0
			elif havada >= 0:
				havada += 1
			if havada == k:
				o.zipla_bas()
				await physics_frame
				# ilk zıplama: hız ZIPLAMA_HIZI civarı (yerçekimi bir adım uygular); ikinci: IKINCI_ZIPLAMA_HIZI
				tam = o.velocity.y < (Ayarlar.ZIPLAMA_HIZI + Ayarlar.IKINCI_ZIPLAMA_HIZI) / 2.0
				break
		satir += "%d:%s " % [k, "TAM" if tam else "zayif"]
		if tam:
			enbuyuk = k
		dunya.queue_free()
		await physics_frame
	print("HIS_OLCUM KOJOT karelere_gore %s" % satir)
	print("HIS_OLCUM KOJOT tam_guc_penceresi_kare=%d ms=%.0f (ayar %.0f ms)" % [enbuyuk, (enbuyuk + 1) * KARE_MS, Ayarlar.KOJOT_SURESI * 1000.0])


func _tampon() -> void:
	# Önce inişin kaçıncı karede olduğunu bul (iki hak bitmiş, 60 px yükseklikten serbest düşüş).
	var inis := -1
	var dunya0 := Node2D.new()
	root.add_child(dunya0)
	_zemin(0.0, 900.0, dunya0)
	var o0 := _oyuncu(100.0, dunya0)
	o0.olumsuz = true
	o0.global_position.y = Ayarlar.ZEMIN_Y - 60.0
	o0._kullanilan_ziplama = 2
	o0.velocity = Vector2.ZERO
	for kare in 120:
		await physics_frame
		if o0.is_on_floor():
			inis = kare
			break
	dunya0.queue_free()
	await physics_frame
	var enbuyuk := -1
	var satir := ""
	for k in range(0, 14):
		var dunya := Node2D.new()
		root.add_child(dunya)
		_zemin(0.0, 900.0, dunya)
		var o := _oyuncu(100.0, dunya)
		o.olumsuz = true
		o.global_position.y = Ayarlar.ZEMIN_Y - 60.0
		o._kullanilan_ziplama = 2
		o.velocity = Vector2.ZERO
		var calisti := false
		for kare in 120:
			await physics_frame
			if kare == inis - k:
				o.zipla_bas()
			if kare > inis and o.velocity.y < 0.0:
				calisti = true
				break
			if kare > inis + 3:
				break
		satir += "%d:%s " % [k, "VAR" if calisti else "yok"]
		if calisti:
			enbuyuk = k
		dunya.queue_free()
		await physics_frame
	print("HIS_OLCUM TAMPON karelere_gore %s" % satir)
	print("HIS_OLCUM TAMPON penceresi_kare=%d ms=%.0f (ayar %.0f ms)" % [enbuyuk, (enbuyuk + 1) * KARE_MS, Ayarlar.ZIPLAMA_TAMPONU * 1000.0])
