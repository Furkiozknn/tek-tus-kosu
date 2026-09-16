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
	await _test_gorevler_ve_kostum()
	await _test_parca_sahneleri()
	await _test_ziplama()
	await _test_gecilebilirlik()
	await _test_hiz_ve_sizinti()
	await _test_menu()
	await _test_yeniden_baslat_ve_tekrar()
	await _test_tavan_ve_piston()
	await _test_hiz_egrisi_ve_belirlenimcilik()
	await _test_gunluk_ve_hayalet()
	await _test_basarimlar_ve_isaretler()
	await _test_menu_v03()
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
	_kayit_temizle()
	var d := Kayit.yukle()
	dogrula(d["rekor"] == 0 and d["toplam_altin"] == 0, "boş kayıt sıfır olmalı")
	d = Kayit.kosu_kaydet(10, 3)
	dogrula(d["rekor"] == 10 and d["toplam_altin"] == 3 and d["yeni_rekor"], "ilk koşu rekor olmalı")
	d = Kayit.kosu_kaydet(5, 2)
	dogrula(d["rekor"] == 10 and d["toplam_altin"] == 5 and not d["yeni_rekor"], "düşük skor rekoru bozmamalı, altın toplanmalı")
	d = Kayit.kosu_kaydet(50, 0, true)
	dogrula(d["rekor_rahat"] == 50 and d["rekor"] == 10, "rahat mod rekoru ayrı tutulmalı")
	# Yedek: ana dosya bozulursa yedekten okunur
	var f := FileAccess.open(Kayit.yol, FileAccess.WRITE)
	f.store_string("bozuk [[[ dosya")
	f.close()
	d = Kayit.yukle()
	dogrula(d["rekor"] == 10 and d["toplam_altin"] == 5, "bozuk kayıtta yedekten okunmalı")
	# Ayarlar
	Kayit.ayar_yaz("muzik", 0.25)
	dogrula(is_equal_approx(float(Kayit.ayar("muzik")), 0.25), "ayar yazılıp okunmalı")
	_kayit_temizle()


func _kayit_temizle() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.yol))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.yedek_yolu()))


# ------------------------------------------------------------------ görev + kostüm
func _test_gorevler_ve_kostum() -> void:
	print("[gorevler ve kostum]")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var d := Kayit.VARSAYILAN.duplicate(true)
	Gorevler.hazirla(d, rng)
	dogrula(d["gorevler"].size() == 3, "3 aktif görev olmalı")
	var sureler := []
	for g in d["gorevler"]:
		sureler.append(g["sure"])
	dogrula(sureler == ["kisa", "orta", "uzun"], "kısa/orta/uzun birer görev olmalı")
	# Her görevi tamamlayacak kadar büyük bir koşu
	var ist := {"mesafe": 100000, "altin": 100000, "ikinci": 100000, "yakin": 100000, "kosu": 100000}
	var once := int(d["toplam_altin"])
	var sonuc := Gorevler.kosu_sonu(d, ist, rng)
	dogrula(sonuc["tamamlanan"].size() == 3, "üç görev de tamamlanmalı")
	dogrula(int(d["toplam_altin"]) == once + int(sonuc["odul"]) and int(sonuc["odul"]) > 0, "ödül altına eklenmeli")
	dogrula(sonuc["seviye_atladi"] and int(d["gorev_seviyesi"]) == 2, "3 görevde seviye atlanmalı")
	dogrula(d["gorevler"].size() == 3, "tamamlananların yerine yeni görev gelmeli")
	var idler := {}
	for g in d["gorevler"]:
		idler[g["id"]] = true
		dogrula(int(g["ilerleme"]) == 0, "yeni görev sıfırdan başlamalı")
	dogrula(idler.size() == 3, "aktif görevler birbirinden farklı olmalı")
	# Birikimli görev ilerlemesi
	for g in d["gorevler"]:
		g["ilerleme"] = 0
	var kucuk := {"mesafe": 1, "altin": 1, "ikinci": 1, "yakin": 1, "kosu": 1}
	Gorevler.kosu_sonu(d, kucuk, rng)
	for g in d["gorevler"]:
		dogrula(int(g["ilerleme"]) == 1, "ilerleme koşu sonunda işlenmeli: " + str(g["id"]))
	# Kostüm
	d["toplam_altin"] = 100
	dogrula(not Kostumler.satin_al(d, "altin"), "parası yetmeyen kostüm alınmamalı")
	dogrula(Kostumler.satin_al(d, "kizil") and int(d["toplam_altin"]) == 40, "kostüm alınınca altın düşmeli")
	dogrula(Kostumler.satin_al(d, "kizil") and int(d["toplam_altin"]) == 40, "açık kostüm ikinci kez ücret almamalı")
	var sf := Kostumler.kareler("neon")
	dogrula(sf.has_animation("kos") and sf.get_frame_count("kos") == 8 and sf.has_animation("olum"), "kostüm animasyonları kurulmalı")


# ------------------------------------------------------------------ parçalar
func _test_parca_sahneleri() -> void:
	print("[parca sahneleri]")
	dogrula(ParcaListesi.YOLLAR.size() >= 25, "en az 25 parça olmalı")
	var nefes := 0
	for yol in ParcaListesi.YOLLAR:
		if ParcaListesi.ZORLUK[yol] == 0:
			nefes += 1
	dogrula(nefes >= 2, "en az 2 nefes parçası olmalı")
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
			dogrula(p.zorluk >= 0 and p.zorluk <= 3, "zorluk 0-3 olmalı: " + yol)
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
	var temalar := {}
	var nefes_gordu := false
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
			temalar[oyun.tema] = true
			for p in oyun.parcalar:
				if p.zorluk == 0:
					nefes_gordu = true
	var mesafe: int = oyun.mesafe()
	print("  koşulan: %d m, ölüm: %s, son hız: %.0f, en çok parça: %d, en çok düğüm: %d, altın: %d" % [
		mesafe, "yok" if oyun.oyuncu.canli else "VAR", onceki_hiz, en_cok_parca, en_cok_dugum, oyun.altin])
	if not oyun.oyuncu.canli:
		for p in oyun.parcalar:
			if oyun.oyuncu.global_position.x >= p.position.x and oyun.oyuncu.global_position.x <= p.position.x + p.uzunluk:
				print("  ölüm parçası: %s (yerel x=%.0f, hız=%.0f, neden=%s)" % [p.scene_file_path.get_file(), oyun.oyuncu.global_position.x - p.position.x, oyun.oyuncu.hiz, str(oyun.oyuncu.olum_nedeni)])
	dogrula(oyun.oyuncu.canli, "bot 3 dakika boyunca hiç ölmemeli (rastgele parça sırası)")
	dogrula(hiz_azalmadi, "hız hiç azalmamalı")
	dogrula(sinir_asilmadi, "hız üst sınırı aşılmamalı")
	dogrula(is_equal_approx(onceki_hiz, Ayarlar.HIZ_AZAMI), "3 dakikada hız üst sınıra ulaşmalı")
	dogrula(en_cok_parca <= 8, "aynı anda en fazla 8 parça olmalı (oldu: %d)" % en_cok_parca)
	dogrula(en_cok_dugum <= 8, "dünya düğüm sayısı sınırlı kalmalı (oldu: %d)" % en_cok_dugum)
	dogrula(oyun.altin > 0, "bot koşu boyunca altın toplamalı")
	dogrula(temalar.size() >= 3, "uzun koşuda tema değişmeli (görülen: %d)" % temalar.size())
	dogrula(nefes_gordu, "nefes parçası gelmeli")
	dogrula(int(oyun.istatistik["ikinci"]) >= 0 and int(oyun.istatistik["mesafe"]) == mesafe, "istatistik tutulmalı")
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

	# Menü akışı: 100 altınla Karakter paneli, satın alma, ayarlar, panel boyutları.
	_kayit_temizle()
	var kd := Kayit.yukle()
	kd["toplam_altin"] = 100
	Kayit.kaydet(kd)
	menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _kareler(3)
	var ekran: Rect2 = menu.get_viewport().get_visible_rect()
	var alt_etiket: Control = menu.get_node("%AltinEtiketi")
	dogrula(alt_etiket.get_global_rect().end.y <= 296.0,
		"menü sol sütunu çatıya taşmamalı (alt kenar %.0f)" % alt_etiket.get_global_rect().end.y)
	(menu.get_node("%KarakterDugme") as Button).pressed.emit()
	await _kareler(3)
	var kp: Control = menu.get_node("%KarakterPaneli")
	dogrula(kp.visible and not menu.get_node("%AnaPanel").visible, "Karakter düğmesi paneli açmalı")
	dogrula(not menu.get_node("%Ipucu").visible, "alt panel açıkken başlatma ipucu gizlenmeli")
	dogrula(ekran.encloses(kp.get_global_rect()), "karakter paneli ekrana sığmalı (%s / %s)" % [kp.get_global_rect(), ekran])
	var satin: Button = null
	for satir in menu.get_node("%KostumListesi").get_children():
		var b: Button = satir.get_child(2)
		if b.text == "Satın al: 60 altın":
			satin = b
	dogrula(satin != null and not satin.disabled, "60 altınlık kostüm alınabilir olmalı")
	if satin:
		satin.pressed.emit()
		await _kareler(2)
	kd = Kayit.yukle()
	dogrula(kd["kostum"] == "kizil" and int(kd["toplam_altin"]) == 40, "satın alma altını düşüp kostümü seçmeli")
	dogrula((kd["acik_kostumler"] as Array).has("kizil"), "satın alınan kostüm açık listede olmalı")
	(menu.get_node("%KarakterGeri") as Button).pressed.emit()
	(menu.get_node("%AyarlarDugme") as Button).pressed.emit()
	await _kareler(3)
	var ap: Control = menu.get_node("%AyarlarPaneli")
	dogrula(ap.visible, "Ayarlar düğmesi paneli açmalı")
	dogrula(ekran.encloses(ap.get_global_rect()), "ayarlar paneli ekrana sığmalı")
	(menu.get_node("%RahatKutu") as CheckButton).button_pressed = true
	await _kareler(1)
	dogrula(bool(Kayit.yukle()["ayarlar"]["rahat"]), "rahat mod ayarı kaydedilmeli")
	dogrula((menu.get_node("%RekorEtiketi") as Label).text.begins_with("Rahat"), "rahat modda menü rahat rekoru göstermeli")
	menu.queue_free()
	await process_frame
	_kayit_temizle()

	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.kayit_yap = false
	oyun.olum_tekrari_acik = false
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


# ------------------------------------------------------------------ yeniden başlatma + ölüm tekrarı
func _test_yeniden_baslat_ve_tekrar() -> void:
	print("[yeniden baslatma ve olum tekrari]")
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.kayit_yap = false
	oyun.tohum = 9
	root.add_child(oyun)
	await _kareler(150)
	oyun.altin_toplandi()
	oyun.oyuncu.ol("cukur")
	await _kareler(2)
	dogrula(oyun.bitti and oyun.tekrar_etiketi.visible, "ölünce tekrar oynatılmalı")
	dogrula(not oyun.son_paneli.visible, "tekrar sürerken panel gizli olmalı")
	var kare := 0
	while not oyun.son_paneli.visible and kare < 600:
		await physics_frame
		kare += 1
	dogrula(oyun.son_paneli.visible, "tekrar bitince panel açılmalı")
	dogrula(kare > 60 and kare < 400, "tekrar makul sürmeli (kare: %d)" % kare)
	# Atlanabilirlik
	var bas := Time.get_ticks_usec()
	oyun.yeniden_baslat()
	var gecen := (Time.get_ticks_usec() - bas) / 1000000.0
	dogrula(gecen < 1.0, "yeniden başlatma 1 sn'den kısa olmalı (%.3f sn)" % gecen)
	await _kareler(2)
	dogrula(not oyun.bitti and oyun.altin == 0 and oyun.mesafe() <= 1 and oyun.oyuncu.canli, "yeniden başlatınca durum sıfırlanmalı")
	dogrula(oyun.parcalar.size() >= 2 and oyun.parcalar[0].position.x == 0.0, "parçalar baştan kurulmalı")
	await _kareler(150)
	oyun.oyuncu.ol()
	await _kareler(3)
	oyun._tekrar_bitir()
	await _kareler(2)
	dogrula(oyun.son_paneli.visible, "tekrar atlanınca panel hemen açılmalı")
	oyun.queue_free()
	await process_frame


# ------------------------------------------------------------------ tavan + piston
func _test_tavan_ve_piston() -> void:
	print("[tavan ve piston]")
	var kok := Node2D.new()
	root.add_child(kok)
	var z := Zemin.new()
	z.position = Vector2(-1000, Ayarlar.ZEMIN_Y)
	z.genislik = 100000.0
	kok.add_child(z)
	var tv := Tehlike.new()
	tv.tur = Tehlike.Tur.TAVAN
	tv.genislik = 400.0
	tv.yukseklik = 20.0
	tv.position = Vector2(150, 212)
	kok.add_child(tv)
	var o: Oyuncu = (load("res://scenes/oyuncu.tscn") as PackedScene).instantiate()
	o.position = Vector2(0, Ayarlar.ZEMIN_Y - 2)
	o.hiz = 200.0
	kok.add_child(o)
	await _kareler(60)
	dogrula(o.canli and o.global_position.x > 160, "tavanın altından koşulabilmeli (x=%.0f)" % o.global_position.x)
	o.zipla_bas()
	await physics_frame
	o.zipla_birak()
	await _kareler(40)
	dogrula(o.canli, "tavanın altında kısa zıplama güvenli olmalı")
	await _kareler(10)
	o.zipla_bas()
	await _kareler(40)
	dogrula(not o.canli and o.olum_nedeni == tv, "tavanın altında tam zıplama öldürmeli")
	# Piston zamanla yükselip inmeli
	var ps := Tehlike.new()
	ps.tur = Tehlike.Tur.PISTON
	ps.genislik = 24.0
	ps.yukseklik = 24.0
	ps.position = Vector2(5000, Ayarlar.ZEMIN_Y)
	kok.add_child(ps)
	var yukseklikler := {}
	for i in 120:
		await physics_frame
		yukseklikler[int(ps.isabet_rect().size.y)] = true
	dogrula(yukseklikler.size() > 3, "piston yüksekliği değişmeli")
	# Kıl payı kaçış: alçak zıplamayla bloğun hemen üstünden geçen oyuncu ödül alır
	var dinleyici := YakinDinleyici.new()
	dinleyici.add_to_group("oyun")
	kok.add_child(dinleyici)
	var blok := Tehlike.new()
	blok.tur = Tehlike.Tur.BLOK
	blok.genislik = 10.0
	blok.yukseklik = 30.0
	blok.position = Vector2(9000, Ayarlar.ZEMIN_Y)
	kok.add_child(blok)
	var o2: Oyuncu = (load("res://scenes/oyuncu.tscn") as PackedScene).instantiate()
	o2.position = Vector2(8800, Ayarlar.ZEMIN_Y - 2)
	o2.hiz = 200.0
	kok.add_child(o2)
	var ziplandi := false
	for i in 200:
		await physics_frame
		if not ziplandi and o2.is_on_floor() and o2.global_position.x >= 9005.0 - 0.213 * 200.0 - 4.0:
			o2.zipla_bas()
			await physics_frame
			o2.zipla_birak()
			ziplandi = true
	dogrula(o2.canli and o2.global_position.x > 9100, "alçak zıplamayla bloğun üstünden geçilmeli")
	dogrula(dinleyici.sayi == 1, "kıl payı kaçış bir kez sayılmalı (sayı: %d)" % dinleyici.sayi)
	kok.queue_free()
	await process_frame


# ------------------------------------------------------------------ v0.3
func _test_hiz_egrisi_ve_belirlenimcilik() -> void:
	print("[hız eğrisi ve parça dizisi belirlenimciliği]")
	dogrula(is_equal_approx(Ayarlar.hiz_mesafede(0.0), Ayarlar.HIZ_BAS), "başlangıç hızı HIZ_BAS olmalı")
	dogrula(is_equal_approx(Ayarlar.hiz_mesafede(1e9), Ayarlar.HIZ_AZAMI), "uzakta hız HIZ_AZAMI olmalı")
	# Sayısal tümlevle karşılaştır: t saniyede alınan yol -> o andaki hız
	var t := 0.0
	var d := 0.0
	var en_buyuk_fark := 0.0
	var tekdüze := true
	var onceki := 0.0
	while t < 70.0:
		var v := minf(Ayarlar.HIZ_BAS + Ayarlar.HIZ_ARTIS * t, Ayarlar.HIZ_AZAMI)
		var tahmin := Ayarlar.hiz_mesafede(d)
		en_buyuk_fark = maxf(en_buyuk_fark, absf(tahmin - v))
		if tahmin < onceki - 0.0001:
			tekdüze = false
		onceki = tahmin
		d += v / 60.0
		t += 1.0 / 60.0
	dogrula(en_buyuk_fark < 0.5, "mesafeye göre hız, zamana göre hızla uyuşmalı (fark %.3f)" % en_buyuk_fark)
	dogrula(tekdüze, "mesafeye göre hız azalmamalı")
	# Aynı tohum, farklı oyuncu davranışı (bot / botsuz) -> aynı parça dizisi
	var diziler := []
	for bot in [true, false]:
		var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
		oyun.bot_modu = bot
		oyun.kayit_yap = false
		oyun.olum_tekrari_acik = false
		oyun.tohum = 42
		root.add_child(oyun)
		oyun.oyuncu.olumsuz = true
		var adlar := []
		for i in 12:
			adlar.append(oyun._parca_sec())
			oyun.sonraki_x += 900.0
		diziler.append(adlar)
		oyun.queue_free()
		await process_frame
	dogrula(diziler[0] == diziler[1], "aynı tohum aynı parça dizisini vermeli")
	var farkli := false
	for i in diziler[0].size():
		if diziler[0][i] != ParcaListesi.DUZ:
			farkli = true
	dogrula(farkli, "parça dizisi yalnız düz parçalardan oluşmamalı")


func _test_gunluk_ve_hayalet() -> void:
	print("[günlük koşu ve hayalet]")
	_kayit_temizle()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Hayalet.dosya_yolu()))
	dogrula(Gunluk.tohum("2026-01-02") == Gunluk.tohum("2026-01-02"), "aynı tarih aynı tohum")
	dogrula(Gunluk.tohum("2026-01-02") != Gunluk.tohum("2026-01-03"), "farklı tarih farklı tohum")
	Gunluk.tarih_ezme = "2026-01-02"
	var d := Kayit.yukle()
	dogrula(Gunluk.kosu_isle(d, 120), "ilk günlük koşu rekor olmalı")
	dogrula(not Gunluk.kosu_isle(d, 80), "daha kısa koşu rekor değil")
	var g := Gunluk.durum(d)
	dogrula(int(g["rekor"]) == 120 and int(g["deneme"]) == 2 and (g["olumler"] as Array) == [120, 80], "günlük rekor/deneme/ölümler tutulmalı")
	for i in 20:
		Gunluk.kosu_isle(d, i)
	dogrula((Gunluk.durum(d)["olumler"] as Array).size() == Ayarlar.OLUM_ISARETI_SAYISI, "ölüm listesi sınırlı olmalı")
	Gunluk.tarih_ezme = "2026-01-03"
	dogrula(int(Gunluk.durum(d)["deneme"]) == 0 and int(Gunluk.durum(d)["rekor"]) == 0, "gün değişince günlük sıfırlanmalı")
	# Hayalet: ekle / ara değer / kaydet / yükle
	var h := Hayalet.new()
	h.tarih = "2026-01-03"
	h.mesafe = 5
	h.ekle(Vector2(0, 280), "kos")
	h.ekle(Vector2(20, 260), "zipla")
	h.ekle(Vector2(40, 280), "dus")
	dogrula(h.konum(0.5 / Ayarlar.HAYALET_HZ).is_equal_approx(Vector2(10, 270)), "hayalet örnekler arası ara değer vermeli")
	dogrula(h.anim_adi(1.0 / Ayarlar.HAYALET_HZ) == "zipla", "hayalet animasyonu örnekten okunmalı")
	dogrula(h.kaydet() == OK, "hayalet kaydedilmeli")
	var h2 := Hayalet.yukle("2026-01-03")
	dogrula(h2 != null and h2.sayi() == 3 and h2.mesafe == 5 and h2.konum(2.0 / Ayarlar.HAYALET_HZ).is_equal_approx(Vector2(40, 280)), "hayalet geri yüklenmeli")
	dogrula(Hayalet.yukle("2026-01-04") == null, "başka günün hayaleti yüklenmemeli")
	# Oyun içinde günlük koşu
	_kayit_temizle()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Hayalet.dosya_yolu()))
	Gunluk.tarih_ezme = "2026-02-10"
	var kayit_ilk := Kayit.yukle()
	kayit_ilk["ayarlar"]["rahat"] = true
	Kayit.kaydet(kayit_ilk)
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.bot_modu = true
	oyun.gunluk = true
	oyun.olum_tekrari_acik = false
	root.add_child(oyun)
	await process_frame
	dogrula(not oyun.rahat, "günlük koşuda rahat mod kapalı olmalı")
	var dizi1 := []
	for p in oyun.parcalar:
		dizi1.append(p.scene_file_path)
	await _kareler(300)
	dogrula(oyun.oyuncu.canli, "bot günlük koşuda 5 sn yaşamalı")
	oyun.oyuncu.ol()
	await _kareler(2)
	var kd := Kayit.yukle()
	var gd := Gunluk.durum(kd)
	dogrula(int(gd["deneme"]) == 1 and int(gd["rekor"]) == oyun.son_sonuc["mesafe"] and int(gd["rekor"]) > 0, "günlük sonuç kayda işlenmeli")
	dogrula(int(kd["rekor"]) == int(gd["rekor"]), "günlük koşu genel rekoru da güncellemeli")
	dogrula((kd["olumler"] as Array).is_empty(), "günlük ölüm normal ölüm listesine yazılmamalı")
	var kayitli := Hayalet.yukle("2026-02-10")
	dogrula(kayitli != null and kayitli.sayi() >= 5 * Ayarlar.HAYALET_HZ, "günün rekoru hayalet olarak kaydedilmeli")
	dogrula(oyun.son_rekor.text.begins_with("GÜNÜN REKORU"), "sonuç panelinde günlük rekor yazmalı")
	oyun.yeniden_baslat()
	await _kareler(2)
	var dizi2 := []
	for p in oyun.parcalar:
		dizi2.append(p.scene_file_path)
	dogrula(dizi1 == dizi2, "günlük koşu her denemede aynı parçalarla başlamalı")
	var hs: AnimatedSprite2D = oyun.get_node_or_null("HayaletRakip")
	dogrula(hs != null and hs.visible, "ikinci denemede hayalet rakip görünmeli")
	await _kareler(60)
	if hs:
		var fark: float = absf(hs.global_position.x - oyun.oyuncu.global_position.x)
		dogrula(fark < 40.0, "aynı hızda koşan hayalet oyuncuyla yan yana olmalı (fark %.1f)" % fark)
	await _kareler(300)
	dogrula(oyun._hayalet_bitti and not hs.visible, "hayalet kaydı bitince hayalet kaybolmalı")
	var isaret_var := false
	for c in oyun.get_children():
		if c is Isaret and c.metin == "HAYALET":
			isaret_var = true
	dogrula(isaret_var, "hayaletin bittiği yere işaret konmalı")
	oyun.queue_free()
	await process_frame
	Gunluk.tarih_ezme = ""
	_kayit_temizle()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Hayalet.dosya_yolu()))


func _test_basarimlar_ve_isaretler() -> void:
	print("[başarımlar, geçiş sayacı, işaretler, sonuç haritası]")
	_kayit_temizle()
	var d := Kayit.yukle()
	var ist := Gorevler.bos_istatistik()
	ist["mesafe"] = 600
	var acilan := Basarimlar.denetle(d, ist, false)
	var idler := acilan.map(func(b: Dictionary) -> String: return b["id"])
	dogrula(idler.has("m500") and not idler.has("m1000") and not idler.has("ilk_kosu"), "yalnız sağlanan başarımlar açılmalı (%s)" % str(idler))
	dogrula(int(d["toplam_altin"]) == Ayarlar.BASARIM_ODULU * acilan.size(), "başarım ödülü verilmeli")
	dogrula(Basarimlar.denetle(d, ist, false).is_empty(), "başarım iki kez açılmamalı")
	ist["mesafe"] = 350
	dogrula(not Basarimlar.saglandi_mi("gunluk300", d, ist, false) and Basarimlar.saglandi_mi("gunluk300", d, ist, true), "günlük başarımı yalnız günlük koşuda")
	d["acik_kostumler"] = Kostumler.LISTE.map(func(k: Dictionary) -> String: return k["ad"])
	dogrula(Basarimlar.saglandi_mi("dolap", d, ist, false), "tüm kostümler açılınca gardırop başarımı")
	var ids := {}
	for b in Basarimlar.LISTE:
		ids[b["id"]] = true
	dogrula(ids.size() == Basarimlar.LISTE.size() and Basarimlar.LISTE.size() >= 10, "en az 10 benzersiz başarım olmalı")
	# Geçiş sayacı: alçak geçit + piston
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.bot_modu = true
	oyun.kayit_yap = false
	oyun.olum_tekrari_acik = false
	oyun.sabit_hiz = 300.0
	oyun.parca_sirasi = ["res://scenes/parcalar/16_alcak_gecit.tscn", "res://scenes/parcalar/17_piston.tscn"] as Array[String]
	oyun.sira_bitince_duz = true
	root.add_child(oyun)
	await _kareler(60 * 9)
	dogrula(oyun.oyuncu.canli, "bot tavan ve pistonu geçmeli")
	dogrula(int(oyun.istatistik["tavan"]) == 1 and int(oyun.istatistik["piston"]) == 1, "tavan ve piston geçişleri sayılmalı (%d, %d)" % [oyun.istatistik["tavan"], oyun.istatistik["piston"]])
	oyun.queue_free()
	await process_frame
	# İşaretler: rekor + son ölüm
	_kayit_temizle()
	var k := Kayit.yukle()
	k["rekor"] = 100
	k["olumler"] = [20, 55]
	Kayit.kaydet(k)
	oyun = (load(OYUN) as PackedScene).instantiate()
	oyun.kayit_yap = true
	oyun.olum_tekrari_acik = false
	root.add_child(oyun)
	await process_frame
	var isaretler := {}
	for c in oyun.get_children():
		if c is Isaret:
			isaretler[c.metin] = c.position.x
	dogrula(isaretler.has("REKOR") and is_equal_approx(isaretler["REKOR"], oyun.baslangic_x + 100 * Ayarlar.PIKSEL_METRE), "rekor işareti doğru yerde olmalı")
	dogrula(isaretler.has("SON") and is_equal_approx(isaretler["SON"], oyun.baslangic_x + 55 * Ayarlar.PIKSEL_METRE), "son ölüm işareti doğru yerde olmalı")
	await _kareler(30)
	oyun.oyuncu.ol()
	await _kareler(2)
	var k2 := Kayit.yukle()
	dogrula((k2["olumler"] as Array).size() == 3 and int(k2["olumler"][-1]) == oyun.son_sonuc["mesafe"], "ölüm yeri kayda eklenmeli")
	dogrula(oyun.son_sonuc["olumler"] == [20, 55], "sonuç haritası önceki ölümleri almalı")
	var harita: MiniHarita = oyun.get_node("%SonHarita")
	dogrula(harita.rekor == 100 and harita.olumler == [20, 55], "sonuç haritası doldurulmalı")
	# Kalabalık sonuç paneli ekrana sığmalı
	oyun.son_sonuc["basarimlar"] = [Basarimlar.LISTE[1], Basarimlar.LISTE[2]]
	oyun.son_sonuc["gorev"] = {"tamamlanan": [{"metin": "Tek koşuda 120 m koş"}, {"metin": "Toplam 60 altın topla"}], "odul": 70, "seviye_atladi": true}
	oyun._son_paneli_goster()
	await _kareler(2)
	var ekran: Rect2 = oyun.get_viewport().get_visible_rect()
	var sp: Control = oyun.get_node("%SonPaneli")
	dogrula(ekran.encloses(sp.get_global_rect()), "kalabalık sonuç paneli ekrana sığmalı (%s)" % sp.get_global_rect())
	oyun.queue_free()
	await process_frame
	_kayit_temizle()


func _test_menu_v03() -> void:
	print("[menü: günlük, başarımlar, titreşim]")
	_kayit_temizle()
	var menu: Control = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _kareler(3)
	var ekran: Rect2 = menu.get_viewport().get_visible_rect()
	dogrula(menu.get_node("%GunlukDugme").text == "Günlük koşu", "günlük düğmesi görünmeli")
	dogrula(menu.get_node("%BasarimDugme").text.contains("/%d" % Basarimlar.LISTE.size()), "başarım düğmesi sayıyı göstermeli")
	(menu.get_node("%BasarimDugme") as Button).pressed.emit()
	await _kareler(3)
	var bp: Control = menu.get_node("%BasarimPaneli")
	dogrula(bp.visible and menu.get_node("%BasarimListesi").get_child_count() == Basarimlar.LISTE.size(), "başarım paneli listeyi göstermeli")
	dogrula(ekran.encloses(bp.get_global_rect()), "başarım paneli ekrana sığmalı (%s)" % bp.get_global_rect())
	(menu.get_node("%BasarimGeri") as Button).pressed.emit()
	(menu.get_node("%AyarlarDugme") as Button).pressed.emit()
	await _kareler(3)
	dogrula(ekran.encloses(menu.get_node("%AyarlarPaneli").get_global_rect()), "titreşimli ayarlar paneli ekrana sığmalı")
	(menu.get_node("%TitresimKutu") as CheckButton).button_pressed = false
	await _kareler(1)
	dogrula(not bool(Kayit.yukle()["ayarlar"]["titresim"]), "titreşim ayarı kaydedilmeli")
	menu.queue_free()
	await process_frame
	Gunluk.secili = false
	_kayit_temizle()


class YakinDinleyici extends Node:
	var sayi := 0

	func yakin_kacis(_t: Node2D) -> void:
		sayi += 1

	func altin_toplandi(_k: Vector2 = Vector2.INF) -> void:
		pass
