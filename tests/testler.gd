extends SceneTree
## Otomatik testler. Çalıştırma (proje kökünde):
##   godot --headless --fixed-fps 60 --path . -s res://tests/testler.gd
## Çıkış kodu 0 = hepsi geçti.

const OYUN := "res://scenes/oyun.tscn"
var hatalar := 0
var gecen := 0


func _initialize() -> void:
	_calistir.call_deferred()


func _calistir() -> void:
	Kayit.yol = "user://test_kayit.cfg"
	await _test_kayit()
	await _test_parca_sahneleri()
	await _test_ziplama()
	await _test_gecilebilirlik()
	await _test_hiz_ve_sizinti()
	await _test_menu()
	print("\n=== SONUÇ: %d geçti, %d hata ===" % [gecen, hatalar])
	quit(1 if hatalar > 0 else 0)


func dogrula(kosul: bool, mesaj: String) -> void:
	if kosul:
		gecen += 1
	else:
		hatalar += 1
		printerr("  HATA: " + mesaj)


func _kareler(n: int) -> void:
	for i in n:
		await physics_frame


# ------------------------------------------------------------------ kayıt
func _test_kayit() -> void:
	print("[kayit]")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.yol))
	var d := Kayit.yukle()
	dogrula(d["rekor"] == 0 and d["toplam_altin"] == 0, "boş kayıt sıfır olmalı")
	d = Kayit.kosu_kaydet(10, 3)
	dogrula(d["rekor"] == 10 and d["toplam_altin"] == 3 and d["yeni_rekor"], "ilk koşu rekor olmalı")
	d = Kayit.kosu_kaydet(5, 2)
	dogrula(d["rekor"] == 10 and d["toplam_altin"] == 5 and not d["yeni_rekor"], "düşük skor rekoru bozmamalı, altın toplanmalı")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.yol))


# ------------------------------------------------------------------ parçalar
func _test_parca_sahneleri() -> void:
	print("[parca sahneleri]")
	dogrula(ParcaListesi.YOLLAR.size() >= 10, "en az 10 parça olmalı")
	for yol in ParcaListesi.YOLLAR:
		var ps: PackedScene = load(yol)
		dogrula(ps != null, "yüklenemedi: " + yol)
		if ps == null:
			continue
		var p = ps.instantiate()
		root.add_child(p)
		dogrula(p is Parca, "Parca değil: " + yol)
		if p is Parca:
			dogrula(p.has_node("Giris") and p.has_node("Cikis"), "giriş/çıkış yok: " + yol)
			dogrula(p.giris() == Vector2(0, Ayarlar.ZEMIN_Y), "giriş zemin hizasında değil: " + yol)
			dogrula(p.cikis() == Vector2(p.uzunluk, Ayarlar.ZEMIN_Y), "çıkış uzunlukla uyuşmuyor: " + yol)
			dogrula(p.zorluk >= 1 and p.zorluk <= 3, "zorluk 1-3 olmalı: " + yol)
			var ilk_son_temiz := true
			for a in p.tehlike_araliklari():
				if a.x < 60.0 or a.y > p.uzunluk - 60.0:
					ilk_son_temiz = false
			dogrula(ilk_son_temiz, "parça uçlarında 60 px güvenli zemin yok: " + yol)
			var altin := 0
			for c in p.get_children():
				if c is Altin:
					altin += 1
			dogrula(altin > 0, "parçada altın yok: " + yol)
		p.queue_free()
		await process_frame


# ------------------------------------------------------------------ zıplama
func _test_ziplama() -> void:
	print("[ziplama]")
	var kok := Node2D.new()
	root.add_child(kok)
	var z := Zemin.new()
	z.position = Vector2(-1000, Ayarlar.ZEMIN_Y)
	z.genislik = 100000.0
	z.yukseklik = 120.0
	kok.add_child(z)
	var o: Oyuncu = (load("res://scenes/oyuncu.tscn") as PackedScene).instantiate()
	o.position = Vector2(0, Ayarlar.ZEMIN_Y - 30)
	kok.add_child(o)
	await _kareler(40)
	dogrula(o.is_on_floor(), "oyuncu zemine oturmalı")
	dogrula(o.velocity.x > 0.0, "oyuncu kendiliğinden koşmalı")

	o.zipla_bas()
	dogrula(is_equal_approx(o.velocity.y, Ayarlar.ZIPLAMA_HIZI), "yerdeyken zıplamalı")
	await _kareler(6)
	dogrula(not o.is_on_floor(), "zıpladıktan sonra havada olmalı")
	o.zipla_bas()
	dogrula(is_equal_approx(o.velocity.y, Ayarlar.IKINCI_ZIPLAMA_HIZI), "havada ikinci kez zıplamalı")
	await _kareler(4)
	var onceki := o.velocity.y
	o.zipla_bas()
	dogrula(o.velocity.y >= onceki, "üçüncü zıplama olmamalı")
	dogrula(not o.havada_ziplama_hakki_var(), "hava hakkı bitmiş olmalı")

	# Değişken yükseklik: erken bırakınca daha alçak zıplar.
	await _kareler(90)
	dogrula(o.is_on_floor(), "yere geri inmeli")
	var tam := await _tepe_yuksekligi(o, 99)
	await _kareler(90)
	var kisa := await _tepe_yuksekligi(o, 3)
	dogrula(kisa < tam * 0.7, "erken bırakılan zıplama daha alçak olmalı (%.0f / %.0f)" % [kisa, tam])

	# Tampon: yere değmeden hemen önce basılan zıplama iniş anında gerçekleşir.
	await _kareler(90)
	o.zipla_bas()
	o.zipla_bas()  # ikinci hak da kullanıldı
	var inis_bekle := 0
	while inis_bekle < 200:
		await physics_frame
		inis_bekle += 1
		if o.velocity.y > 0.0 and o.global_position.y > Ayarlar.ZEMIN_Y - 8.0:
			break
	o.zipla_bas()  # henüz havada, hak yok -> tampona girer
	await _kareler(8)
	dogrula(o.velocity.y < 0.0 or not o.is_on_floor(), "tampondaki zıplama inişte çalışmalı")

	# Diken teması ölüm getirir.
	await _kareler(120)
	var t := Tehlike.new()
	t.genislik = 40.0
	t.yukseklik = 12.0
	t.position = Vector2(o.global_position.x + 60.0, Ayarlar.ZEMIN_Y)
	kok.add_child(t)
	var oldu := [false]
	o.oldu.connect(func() -> void: oldu[0] = true)
	await _kareler(60)
	dogrula(oldu[0] and not o.canli, "dikene değince ölmeli")
	kok.queue_free()
	await process_frame


func _tepe_yuksekligi(o: Oyuncu, birakma_karesi: int) -> float:
	var y0 := o.global_position.y
	var en := y0
	o.zipla_bas()
	for i in 80:
		await physics_frame
		if i == birakma_karesi:
			o.zipla_birak()
		en = minf(en, o.global_position.y)
	return y0 - en


# ------------------------------------------------------------------ geçilebilirlik
func _test_gecilebilirlik() -> void:
	print("[gecilebilirlik: her parça, en düşük ve en yüksek hızında, bot ile]")
	for yol in ParcaListesi.YOLLAR:
		var z: int = ParcaListesi.ZORLUK[yol]
		var hizlar := [maxf(Ayarlar.zorluk_esigi(z), Ayarlar.HIZ_BAS), Ayarlar.HIZ_AZAMI]
		for hiz in hizlar:
			var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
			oyun.bot_modu = true
			oyun.sabit_hiz = hiz
			oyun.kayit_yap = false
			oyun.tohum = 1
			oyun.sira_bitince_duz = true
			var sira: Array[String] = [yol]
			oyun.parca_sirasi = sira
			root.add_child(oyun)
			var hedef: Parca = null
			for bekle in 600:
				await physics_frame
				for p in oyun.parcalar:
					if p.scene_file_path == yol and p.position.x > 1000.0:
						hedef = p
				if hedef:
					break
			dogrula(hedef != null, "parça dünyaya eklenmedi: " + yol)
			var bitis := (hedef.position.x + hedef.uzunluk + 100.0) if hedef else 0.0
			var kare := 0
			while oyun.oyuncu.canli and oyun.oyuncu.global_position.x < bitis and kare < 3000:
				await physics_frame
				kare += 1
			var ad := yol.get_file().get_basename()
			dogrula(oyun.oyuncu.canli and oyun.oyuncu.global_position.x >= bitis,
				"%s %.0f px/sn hızda geçilemedi (x=%.0f, bitiş=%.0f)" % [ad, hiz, oyun.oyuncu.global_position.x, bitis])
			oyun.queue_free()
			await process_frame


# ------------------------------------------------------------------ hız + sızıntı
func _test_hiz_ve_sizinti() -> void:
	print("[hiz ve bellek: 3 dakikalık hızlandırılmış koşu, bot ile]")
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.bot_modu = true
	oyun.kayit_yap = false
	oyun.tohum = 7
	root.add_child(oyun)
	await process_frame
	var onceki_hiz := 0.0
	var hiz_azalmadi := true
	var sinir_asilmadi := true
	var en_cok_parca := 0
	var en_cok_dugum := 0
	var dugum_baslangic := 0
	for kare in 60 * 180:
		await physics_frame
		if not oyun.oyuncu.canli:
			break
		var h: float = oyun.oyuncu.hiz
		if h < onceki_hiz - 0.001:
			hiz_azalmadi = false
		if h > Ayarlar.HIZ_AZAMI + 0.001:
			sinir_asilmadi = false
		onceki_hiz = h
		en_cok_parca = maxi(en_cok_parca, oyun.parcalar.size())
		if kare == 600:
			dugum_baslangic = oyun.dunya.get_child_count()
		if kare % 60 == 0:
			en_cok_dugum = maxi(en_cok_dugum, oyun.dunya.get_child_count())
	var mesafe: int = oyun.mesafe()
	print("  koşulan: %d m, ölüm: %s, son hız: %.0f, en çok parça: %d, en çok düğüm: %d, altın: %d" % [
		mesafe, "yok" if oyun.oyuncu.canli else "VAR", onceki_hiz, en_cok_parca, en_cok_dugum, oyun.altin])
	dogrula(oyun.oyuncu.canli, "bot 3 dakika boyunca hiç ölmemeli (rastgele parça sırası)")
	dogrula(hiz_azalmadi, "hız hiç azalmamalı")
	dogrula(sinir_asilmadi, "hız üst sınırı aşılmamalı")
	dogrula(is_equal_approx(onceki_hiz, Ayarlar.HIZ_AZAMI), "3 dakikada hız üst sınıra ulaşmalı")
	dogrula(en_cok_parca <= 8, "aynı anda en fazla 8 parça olmalı (oldu: %d)" % en_cok_parca)
	dogrula(en_cok_dugum <= 8, "dünya düğüm sayısı sınırlı kalmalı (oldu: %d)" % en_cok_dugum)
	dogrula(oyun.altin > 0, "bot koşu boyunca altın toplamalı")
	oyun.queue_free()
	await process_frame


# ------------------------------------------------------------------ menü
func _test_menu() -> void:
	print("[menu ve oyun sonu]")
	var menu: Control = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	dogrula(menu.get_node("%BaslaDugme") is Button, "menüde Başla düğmesi olmalı")
	menu.queue_free()
	await process_frame

	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.kayit_yap = false
	oyun.tohum = 3
	root.add_child(oyun)
	await _kareler(10)
	oyun.oyuncu.ol()
	await _kareler(2)
	dogrula(oyun.bitti, "ölünce koşu bitmeli")
	dogrula(oyun.get_node("%SonPaneli").visible, "oyun sonu paneli görünmeli")
	dogrula(oyun.get_node("%SonSkor").text.begins_with("Mesafe"), "oyun sonunda skor yazmalı")
	oyun.duraklat()
	dogrula(not paused, "bitmiş koşu duraklatılmamalı")
	oyun.queue_free()
	await process_frame
