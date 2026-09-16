extends SceneTree
## Bot stres testi: farklı tohumlarla uzun koşular; ölümleri parça adıyla raporlar.
##   godot --headless --fixed-fps 60 --path . -s res://tools/bot_stres.gd -- --tohumlar 1,2,3 --sure 180
## Ritim koşusu:  ... -- --ritim                 (bot oynar)
##                ... -- --ritim --vurus 60      (bot yerine her olay vuruşunda 60 ms geç zıplayan oyuncu;
##                                                 eksi değer erken; alçak tavanda dokunur, diğerlerinde basılı tutar)

func _initialize() -> void:
	_calistir.call_deferred()


func _calistir() -> void:
	var tohumlar: Array = [1, 2, 3, 4, 5]
	var sure := 180
	var ritim := false
	var vurus := NAN
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i] == "--ritim":
			ritim = true
		elif a[i] == "--vurus" and i + 1 < a.size():
			vurus = float(a[i + 1])
		elif a[i] == "--tohumlar" and i + 1 < a.size():
			tohumlar = Array(a[i + 1].split(",")).map(func(x: String) -> int: return int(x))
		elif a[i] == "--sure" and i + 1 < a.size():
			sure = int(a[i + 1])
	Kayit.yol = "user://stres_kayit.cfg"
	var olumler := 0
	var gorulen := {}
	for t in tohumlar:
		var oyun: Node2D = (load("res://scenes/oyun.tscn") as PackedScene).instantiate()
		oyun.bot_modu = is_nan(vurus)
		oyun.ritim = ritim
		oyun.kayit_yap = false
		oyun.olum_tekrari_acik = false
		oyun.tohum = t
		oyun.get_node("Dunya").child_entered_tree.connect(func(n: Node) -> void:
			if n is Parca:
				if n.has_meta("desenler"):
					for d in n.get_meta("desenler"):
						gorulen[d] = int(gorulen.get(d, 0)) + 1
				else:
					var ad: String = n.scene_file_path.get_file().get_basename()
					gorulen[ad] = int(gorulen.get(ad, 0)) + 1)
		root.add_child(oyun)
		await process_frame
		var ol: Oyuncu = oyun.oyuncu
		var yapilan := {}
		var birak := -1
		var kaydir := 0.0 if is_nan(vurus) else vurus / 1000.0 * Ritim.HIZ
		for kare in 60 * sure:
			await physics_frame
			if not ol.canli:
				break
			if is_nan(vurus):
				continue
			if birak == 0:
				ol.zipla_birak()
			birak -= 1
			var x := ol.global_position.x
			var k := int(round((x - kaydir - oyun._izgara0) / Ritim.ADIM))
			var kx: float = oyun._izgara0 + k * Ritim.ADIM
			if x + 2.5 >= kx + kaydir and not yapilan.has(k) and oyun._ritim_olaylar.has(k):
				yapilan[k] = true
				var tavan := false
				for tv in oyun.dunya_tavan_araliklari():
					if kx >= float(tv[0]) - 1.0 and kx <= float(tv[1]):
						tavan = true
				ol.zipla_bas()
				birak = 1 if tavan else 24
		var satir := "tohum %d: %d m" % [t, oyun.mesafe()]
		if ritim:
			satir += "  tam vuruş %d" % int(oyun.istatistik["ritim"])
		if not ol.canli:
			olumler += 1
			for p in oyun.parcalar:
				var x: float = ol.global_position.x
				if x >= p.position.x - 20 and x <= p.position.x + p.uzunluk:
					var ad: String = p.scene_file_path.get_file()
					var yer: float = x - p.position.x
					if p.has_meta("desenler"):
						var giris: float = p.uzunluk - Ritim.PARCA_OLCU * Ritim.OLCU * Ritim.ADIM
						var olcu := clampi(int(floor((yer - giris) / (Ritim.OLCU * Ritim.ADIM))), 0, Ritim.PARCA_OLCU - 1)
						ad = "ritim[%s] ölçüde %.0f px" % [str(p.get_meta("desenler")[olcu]), yer - giris - olcu * Ritim.OLCU * Ritim.ADIM]
					satir += "  ÖLÜM: %s x=%.0f hız=%.0f neden=%s" % [ad, yer, ol.hiz, str(ol.olum_nedeni)]
					break
		print(satir)
		oyun.queue_free()
		await process_frame
	var eksik := []
	if ritim:
		for d in Ritim.DESENLER:
			if not gorulen.has(d["ad"]):
				eksik.append(d["ad"])
	else:
		for yol in ParcaListesi.YOLLAR:
			if not gorulen.has(yol.get_file().get_basename()):
				eksik.append(yol.get_file().get_basename())
	var anahtarlar := gorulen.keys()
	anahtarlar.sort()
	print("parça kullanımı: " + ", ".join(anahtarlar.map(func(k: String) -> String: return "%s=%d" % [k if ritim else k.substr(0, 2), gorulen[k]])))
	print("görülmeyen parça: %s" % ("yok" if eksik.is_empty() else ", ".join(eksik)))
	print("STRES: %d koşu, %d ölüm" % [tohumlar.size(), olumler])
	quit(1 if olumler > 0 else 0)
