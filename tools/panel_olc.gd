extends SceneTree
## Geçici ölçüm: ritim sonuç paneli değişen kalabalıkta 360 px'e sığıyor mu?

func _gorevler() -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = 7
	return [Gorevler.yeni_gorev("uzun", 9, [], r), Gorevler.yeni_gorev("orta", 9, [], r), Gorevler.yeni_gorev("kisa", 9, [], r)]


func _initialize() -> void:
	_calistir.call_deferred()


func _calistir() -> void:
	var oyun: Node2D = (load("res://scenes/oyun.tscn") as PackedScene).instantiate()
	oyun.ritim = true
	oyun.kayit_yap = false
	oyun.olum_tekrari_acik = false
	root.add_child(oyun)
	await process_frame
	await process_frame
	for durum in [[0, true], [1, true], [2, true], [3, false], [3, true]]:
		var tamam_sayisi: int = durum[0]
		var histogram: bool = durum[1]
		var tamamlananlar := []
		var metinler := ["Tek koşuda 120 m koş", "Toplam 60 altın topla", "Tek koşuda 3 kez havada zıpla"]
		for i in tamam_sayisi:
			tamamlananlar.append({"metin": metinler[i]})
		oyun.son_sonuc = {
			"mesafe": 1234, "yeni_rekor": true, "rekor": 1234, "olumler": [100, 200],
			"basarimlar": [Basarimlar.LISTE[1], Basarimlar.LISTE[2], Basarimlar.LISTE[13]],
			"gorev": {"tamamlanan": tamamlananlar, "odul": 190, "seviye_atladi": tamam_sayisi > 0},
			"gorevler": _gorevler(),
			"seviye": 4, "deneme": 2, "seri": 0,
			"ritim_sapma": 42.0, "ritim_sapma_sayi": 9,
			"ritim_sapmalar": [-200.0, -90.0, -20.0, 10.0, 60.0, 100.0, 200.0, 5.0, 33.0] if histogram else [],
		}
		oyun._son_paneli_goster()
		await process_frame
		await process_frame
		var p: Control = oyun.get_node("%SonPaneli")
		var gf: Control = oyun.get_node("%SonSapma")
		var ekran: Rect2 = oyun.get_viewport().get_visible_rect()
		var r := p.get_global_rect()
		print("tamamlanan %d | histogram istendi %s -> boy %.0f gorunur %s | satir %d | panel y %.0f h %.0f | sigiyor %s" % [
			tamam_sayisi, histogram, gf.custom_minimum_size.y, gf.visible,
			(oyun.get_node("%SonGorevler") as Label).text.split("\n").size(),
			r.position.y, r.size.y, ekran.encloses(r)])
	quit()
