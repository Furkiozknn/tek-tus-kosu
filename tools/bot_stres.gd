extends SceneTree
## Bot stres testi: farklı tohumlarla uzun koşular; ölümleri parça adıyla raporlar.
##   godot --headless --fixed-fps 60 --path . -s res://tools/bot_stres.gd -- --tohumlar 1,2,3 --sure 180

func _initialize() -> void:
	_calistir.call_deferred()


func _calistir() -> void:
	var tohumlar: Array = [1, 2, 3, 4, 5]
	var sure := 180
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i] == "--tohumlar" and i + 1 < a.size():
			tohumlar = Array(a[i + 1].split(",")).map(func(x: String) -> int: return int(x))
		elif a[i] == "--sure" and i + 1 < a.size():
			sure = int(a[i + 1])
	Kayit.yol = "user://stres_kayit.cfg"
	var olumler := 0
	var gorulen := {}
	for t in tohumlar:
		var oyun: Node2D = (load("res://scenes/oyun.tscn") as PackedScene).instantiate()
		oyun.bot_modu = true
		oyun.kayit_yap = false
		oyun.tohum = t
		oyun.get_node("Dunya").child_entered_tree.connect(func(n: Node) -> void:
			if n is Parca:
				var ad: String = n.scene_file_path.get_file().get_basename()
				gorulen[ad] = int(gorulen.get(ad, 0)) + 1)
		root.add_child(oyun)
		await process_frame
		for kare in 60 * sure:
			await physics_frame
			if not oyun.oyuncu.canli:
				break
		var satir := "tohum %d: %d m" % [t, oyun.mesafe()]
		if not oyun.oyuncu.canli:
			olumler += 1
			for p in oyun.parcalar:
				var x: float = oyun.oyuncu.global_position.x
				if x >= p.position.x - 20 and x <= p.position.x + p.uzunluk:
					satir += "  ÖLÜM: %s x=%.0f hız=%.0f neden=%s" % [p.scene_file_path.get_file(), x - p.position.x, oyun.oyuncu.hiz, str(oyun.oyuncu.olum_nedeni)]
					break
		print(satir)
		oyun.queue_free()
		await process_frame
	var eksik := []
	for yol in ParcaListesi.YOLLAR:
		if not gorulen.has(yol.get_file().get_basename()):
			eksik.append(yol.get_file().get_basename())
	var anahtarlar := gorulen.keys()
	anahtarlar.sort()
	print("parça kullanımı: " + ", ".join(anahtarlar.map(func(k: String) -> String: return "%s=%d" % [k.substr(0, 2), gorulen[k]])))
	print("görülmeyen parça: %s" % ("yok" if eksik.is_empty() else ", ".join(eksik)))
	print("STRES: %d koşu, %d ölüm" % [tohumlar.size(), olumler])
	quit(1 if olumler > 0 else 0)
