extends SceneTree
## Ölçüm aracı: oyunu bot ile gerçek render'da koşturur, kare süresini ölçer (yenileme öncesi/sonrası).
##   godot --rendering-driver opengl3 --resolution 1280x720 --path . -s res://tools/fps.gd -- [kare_sayisi] [ritim] [gecis]
## "gecis" verilirse sekiz geçiş ailesi (Gecis autoload) sırayla oynatılır; örtü görünürken ölçülen
## kareler ayrı satırda basılır (FPS_GECIS).
## Vsync kapalı, 90 kare ısınma. Sonuç: ortalama ms, %99 ms, FPS. Kayıt dosyasına dokunmaz.
## Bot ölmesin diye ölümsüz mod; parça dizisi tohumlu (aynı yük iki sürümde de aynı).

func _initialize() -> void:
	_kos.call_deferred()


func _kos() -> void:
	var arg := OS.get_cmdline_user_args()
	var kare_n := int(arg[0]) if arg.size() > 0 else 900
	var ritim := arg.has("ritim")
	var gecis_ac := arg.has("gecis")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	Kayit.yol = "user://fps_kayit.cfg"
	var oyun: Node2D = (load("res://scenes/oyun.tscn") as PackedScene).instantiate()
	oyun.kayit_yap = false
	oyun.olum_tekrari_acik = false
	oyun.bot_modu = true
	oyun.tohum = 7
	oyun.ritim = ritim
	root.add_child(oyun)
	await process_frame
	oyun.oyuncu.olumsuz = true
	var sureler: Array[float] = []
	var gecis_sureler: Array[float] = []
	var g: GecisKatmani = root.get_node("Gecis")
	var k := 0
	var son := Time.get_ticks_usec()
	for i in kare_n + 90:
		await process_frame
		var s := Time.get_ticks_usec()
		if i >= 90:
			if gecis_ac and g._kaplama.visible:
				gecis_sureler.append(float(s - son) / 1000.0)
			else:
				sureler.append(float(s - son) / 1000.0)
		if gecis_ac and i >= 90 and (i - 90) % 42 == 21 and not g._kaplama.visible:
			g.acilis(Tema.GECIS_TURLERI[k % Tema.GECIS_TURLERI.size()], k % Tema.AKIS.size(), 0.46, 1.0)   # örtü tam kapalı başlar, açılır
			k += 1
		son = s
	sureler.sort()
	var top := 0.0
	for x in sureler:
		top += x
	var ort := top / float(sureler.size())
	var p99 := sureler[int(sureler.size() * 0.99)]
	print("FPS_OLCUM kip=%s kare=%d ort_ms=%.2f p99_ms=%.2f fps=%.1f renderer=%s" % [
		"ritim" if ritim else "normal", sureler.size(), ort, p99, 1000.0 / ort,
		RenderingServer.get_video_adapter_name()])
	if gecis_ac and not gecis_sureler.is_empty():
		gecis_sureler.sort()
		var gt := 0.0
		for x in gecis_sureler:
			gt += x
		var gort := gt / float(gecis_sureler.size())
		print("FPS_GECIS kare=%d ort_ms=%.2f p99_ms=%.2f en_kotu_ms=%.2f fps=%.1f gecis_sayisi=%d" % [
			gecis_sureler.size(), gort, gecis_sureler[int(gecis_sureler.size() * 0.99)], gecis_sureler[-1], 1000.0 / gort, k])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.yol))
	quit(0)
