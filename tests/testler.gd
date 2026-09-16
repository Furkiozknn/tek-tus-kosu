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
	await _test_iskele()
	await _test_seri_ve_paylasim()
	await _test_kostum_izi()
	await _test_ruzgar()
	await _test_dikey_uyari()
	await _test_ritim()
	await _test_gunun_ritmi()
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


# ------------------------------------------------------------------ v0.4
func _test_iskele() -> void:
	print("[çürük iskele]")
	dogrula(Ayarlar.ISKELE_GUVENLI + Oyuncu.YARIM_GENISLIK + 6.0 < Ayarlar.HIZ_BAS * Ayarlar.RAHAT_MOD_CARPANI * Ayarlar.ISKELE_COKME,
		"iskele güvenli bölümü en yavaş hızda çökme süresinden kısa olmalı")
	var kok := Node2D.new()
	root.add_child(kok)
	var z := Zemin.new()
	z.position = Vector2(-600, Ayarlar.ZEMIN_Y)
	z.genislik = 800.0
	kok.add_child(z)
	var isk := Coken.new()
	isk.position = Vector2(200, Ayarlar.ZEMIN_Y)
	isk.genislik = 150.0
	isk.yukseklik = Ayarlar.ISKELE_KALINLIK
	kok.add_child(isk)
	var z2 := Zemin.new()
	z2.position = Vector2(350, Ayarlar.ZEMIN_Y)
	z2.genislik = 450.0
	kok.add_child(z2)
	# Havada, iskelenin üstünden atlayan oyuncu onu tetiklememeli
	await _kareler(5)
	dogrula(isk.durum == Coken.Durum.SAGLAM, "dokunulmayan iskele sağlam kalmalı")
	# Zıplamadan koşan oyuncu: iskele çatırdar, çöker, oyuncu düşer
	var o: Oyuncu = (load("res://scenes/oyuncu.tscn") as PackedScene).instantiate()
	o.position = Vector2(100, Ayarlar.ZEMIN_Y - 2)
	o.hiz = Ayarlar.HIZ_BAS
	kok.add_child(o)
	var kare := 0
	while isk.durum == Coken.Durum.SAGLAM and kare < 120:
		await physics_frame
		kare += 1
	dogrula(isk.durum == Coken.Durum.CATIRDIYOR, "üstüne basılan iskele çatırdamalı")
	dogrula(o.global_position.x < isk.position.x + 10.0, "iskele ilk temasta tetiklenmeli (x=%.0f)" % o.global_position.x)
	await _kareler(int(Ayarlar.ISKELE_COKME * 60.0) + 3)
	dogrula(isk.durum == Coken.Durum.COKTU, "iskele %.1f sn sonra çökmeli" % Ayarlar.ISKELE_COKME)
	await _kareler(60)
	dogrula(not o.canli and str(o.olum_nedeni) == "cukur", "iskeleyle düşen oyuncu çukurdan ölmeli (%s)" % str(o.olum_nedeni))
	o.queue_free()
	# Güvenli bölümde zıplayan oyuncu yaşar
	var isk2 := Coken.new()
	isk2.position = Vector2(1200, Ayarlar.ZEMIN_Y)
	isk2.genislik = 150.0
	isk2.yukseklik = Ayarlar.ISKELE_KALINLIK
	kok.add_child(isk2)
	var z3 := Zemin.new()
	z3.position = Vector2(900, Ayarlar.ZEMIN_Y)
	z3.genislik = 300.0
	kok.add_child(z3)
	var z4 := Zemin.new()
	z4.position = Vector2(1350, Ayarlar.ZEMIN_Y)
	z4.genislik = 2000.0
	kok.add_child(z4)
	var o2: Oyuncu = (load("res://scenes/oyuncu.tscn") as PackedScene).instantiate()
	o2.position = Vector2(1000, Ayarlar.ZEMIN_Y - 2)
	o2.hiz = Ayarlar.HIZ_BAS
	kok.add_child(o2)
	kare = 0
	while o2.global_position.x < isk2.position.x + Ayarlar.ISKELE_GUVENLI - 10.0 and kare < 300:
		await physics_frame
		kare += 1
	o2.zipla_bas()
	await _kareler(90)
	dogrula(o2.canli and o2.global_position.x > isk2.position.x + isk2.genislik and o2.is_on_floor(), "güvenli bölümde zıplayan oyuncu iskeleyi geçmeli")
	dogrula(isk2.durum != Coken.Durum.SAGLAM, "koşulan iskele tetiklenmiş olmalı")
	kok.queue_free()
	await process_frame
	# Parça tehlike aralığı iskelenin güvenli bölümünden sonra başlar
	var parca: Parca = (load("res://scenes/parcalar/37_curuk_iskele.tscn") as PackedScene).instantiate()
	var ar := parca.tehlike_araliklari()
	dogrula(ar.size() == 1 and is_equal_approx(ar[0].x, 320.0 + Ayarlar.ISKELE_GUVENLI) and is_equal_approx(ar[0].y, 470.0),
		"iskele tehlike aralığı yanlış: %s" % str(ar))
	parca.free()
	# Oyun içinde: bot iskeleleri geçer, sayaç artar, başarım tanımı çalışır
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.bot_modu = true
	oyun.sabit_hiz = 380.0
	oyun.kayit_yap = false
	oyun.tohum = 3
	oyun.sira_bitince_duz = true
	var sira: Array[String] = ["res://scenes/parcalar/40_uzun_iskele.tscn", "res://scenes/parcalar/38_iskele_zinciri.tscn"]
	oyun.parca_sirasi = sira
	root.add_child(oyun)
	await _kareler(60 * 9)
	dogrula(oyun.oyuncu.canli, "bot iskele parçalarında yaşamalı")
	dogrula(int(oyun.istatistik["iskele"]) >= 5, "geçilen iskeleler sayılmalı (%d)" % int(oyun.istatistik["iskele"]))
	oyun.queue_free()
	await process_frame
	dogrula(Basarimlar.saglandi_mi("iskele8", {}, {"iskele": 8}, false) and not Basarimlar.saglandi_mi("iskele8", {}, {"iskele": 7}, false),
		"iskele başarımı 8'de açılmalı")


func _test_seri_ve_paylasim() -> void:
	print("[günlük seri ve paylaşım]")
	dogrula(Gunluk.dun("2026-03-01") == "2026-02-28" and Gunluk.dun("2027-01-01") == "2026-12-31" and Gunluk.dun("2028-03-01") == "2028-02-29",
		"dün hesabı ay/yıl/artık yıl sınırlarında doğru olmalı")
	_kayit_temizle()
	var d := Kayit.yukle()
	Gunluk.tarih_ezme = "2026-05-30"
	dogrula(Gunluk.seri(d) == 0, "hiç koşulmamışsa seri 0")
	dogrula(Gunluk.seri_isle(d) == 1, "ilk gün seri 1")
	dogrula(Gunluk.seri_isle(d) == 1, "aynı gün ikinci koşu seriyi artırmamalı")
	Gunluk.tarih_ezme = "2026-05-31"
	dogrula(Gunluk.seri(d) == 1, "dün koşulduysa seri sürer")
	Gunluk.seri_isle(d)
	Gunluk.tarih_ezme = "2026-06-01"
	dogrula(Gunluk.seri_isle(d) == 3, "art arda üç gün seri 3")
	Gunluk.tarih_ezme = "2026-06-03"
	dogrula(Gunluk.seri(d) == 0, "bir gün atlanınca seri kopmalı")
	dogrula(Gunluk.seri_isle(d) == 1 and int(d["gunluk_seri"]["en_iyi"]) == 3, "kopan seri 1'den başlamalı, en iyi seri kalmalı")
	Kayit.kaydet(d)
	dogrula(int(Kayit.yukle()["gunluk_seri"]["en_iyi"]) == 3, "seri kaydedilmeli")
	# Paylaşım metni
	var m := Gunluk.paylasim_metni("2026-09-16", 475, 3, 950, false, 4)
	var satir := m.split("\n")
	dogrula(satir.size() == 4 and satir[0] == "Tek Tuş Koşu · Günlük 16.09.2026", "paylaşım başlığı: %s" % satir[0])
	dogrula(satir[1] == "475 m · 3. deneme", "paylaşım mesafe satırı: %s" % satir[1])
	dogrula(satir[2] == "■■■■■□□□□□  rekor 950 m", "paylaşım şeridi: %s" % satir[2])
	dogrula(satir[3] == "Seri: 4 gün", "paylaşım seri satırı")
	var m2 := Gunluk.paylasim_metni("2026-09-16", 1200, 1, 0, true, 1)
	dogrula(m2.split("\n").size() == 3 and m2.contains("günün rekoru!") and m2.contains("■■■■■■■■■■") and not m2.contains("□"), "rekor koşusunun metni: %s" % m2)
	# Oyun içinde günlük sonuç paneli: Paylaş düğmesi, sığma, kopyalama
	_kayit_temizle()
	Gunluk.tarih_ezme = "2026-07-01"
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.bot_modu = true
	oyun.gunluk = true
	oyun.olum_tekrari_acik = false
	root.add_child(oyun)
	await _kareler(120)
	oyun.oyuncu.ol()
	await _kareler(3)
	var ekran: Rect2 = oyun.get_viewport().get_visible_rect()
	var pd: Button = oyun.get_node("%PaylasDugme")
	dogrula(oyun.son_paneli.visible and pd.visible, "günlük sonuç panelinde Paylaş düğmesi görünmeli")
	dogrula(ekran.encloses(oyun.son_paneli.get_global_rect()), "üç düğmeli sonuç paneli ekrana sığmalı (%s)" % oyun.son_paneli.get_global_rect())
	dogrula(int(oyun.son_sonuc["seri"]) == 1, "günlük koşu seriyi başlatmalı")
	var metin: String = oyun.paylasim_metni()
	dogrula(metin.begins_with("Tek Tuş Koşu · Günlük 01.07.2026") and metin.contains("1. deneme"), "oyun paylaşım metni: %s" % metin)
	pd.pressed.emit()
	await _kareler(1)
	dogrula(pd.text == "Kopyalandı ✓", "paylaş düğmesi geri bildirim vermeli (%s)" % pd.text)
	# Normal koşuda düğme gizli
	oyun.gunluk = false
	Gunluk.secili = false
	oyun.yeniden_baslat()
	await _kareler(30)
	oyun.oyuncu.ol()
	await _kareler(3)
	dogrula(not pd.visible, "normal koşuda Paylaş düğmesi gizli olmalı")
	oyun.queue_free()
	await process_frame
	# Menüde seri
	var dk := Kayit.yukle()
	Gunluk.tarih_ezme = "2026-07-02"
	Gunluk.seri_isle(dk)
	Gunluk.kosu_isle(dk, 1234)
	Kayit.kaydet(dk)
	var menu: Control = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _kareler(3)
	var gd: Button = menu.get_node("%GunlukDugme")
	dogrula(gd.text == "Günlük · 1234 m · 2 gün", "menü günlük düğmesi seriyi göstermeli (%s)" % gd.text)
	var yazi := gd.get_theme_font("font").get_string_size(gd.text, HORIZONTAL_ALIGNMENT_LEFT, -1, gd.get_theme_font_size("font_size"))
	dogrula(yazi.x <= gd.size.x - 4.0, "günlük düğmesi yazısı sığmalı (%.0f / %.0f)" % [yazi.x, gd.size.x])
	menu.queue_free()
	await process_frame
	Gunluk.tarih_ezme = ""
	_kayit_temizle()


func _test_kostum_izi() -> void:
	print("[kostüm izi ve simge yazı tipi]")
	Simgeler.kur()
	Simgeler.kur()
	var yt := ThemeDB.fallback_font
	for ch in "★☆✓←→↓■□":
		dogrula(yt.has_char(ch.unicode_at(0)), "yazı tipi zinciri '%s' simgesini içermeli (web'de kutu çıkmasın)" % ch)
	var adet := 0
	for f in yt.fallbacks:
		if f.resource_path == Simgeler.YOL:
			adet += 1
	dogrula(adet == 1, "simge yazı tipi bir kez eklenmeli (%d)" % adet)
	var gri := Color("8b9bb4")
	dogrula(Kostumler.toz_rengi("klasik", gri) == gri, "klasik kostüm tozu değişmemeli")
	dogrula(Kostumler.toz_rengi("kizil", gri) != gri, "kızıl kostüm tozu renkli olmalı")
	for k in Kostumler.LISTE:
		dogrula(k.has("iz") and k.has("iz_surekli"), "kostümün iz bilgisi olmalı: " + str(k["ad"]))
	var kok := Node2D.new()
	root.add_child(kok)
	var z := Zemin.new()
	z.position = Vector2(-100, Ayarlar.ZEMIN_Y)
	z.genislik = 5000.0
	kok.add_child(z)
	var o: Oyuncu = (load("res://scenes/oyuncu.tscn") as PackedScene).instantiate()
	o.position = Vector2(0, Ayarlar.ZEMIN_Y - 2)
	kok.add_child(o)
	o.kostum_uygula("neon")
	await _kareler(10)
	var iz: CPUParticles2D = o.get_node_or_null("Iz")
	dogrula(iz != null and iz.emitting, "neon kostüm koşarken iz bırakmalı")
	o.zipla_bas()
	await _kareler(8)
	dogrula(iz != null and not iz.emitting, "havadayken iz durmalı")
	o.kostum_uygula("klasik")
	await _kareler(2)
	dogrula(o.get_node_or_null("Iz") == null, "klasik kostümde iz olmamalı")
	o.iz_acik = false
	o.kostum_uygula("altin")
	dogrula(o.get_node_or_null("Iz") == null, "iz kapalıyken (bot) iz düğümü kurulmamalı")
	kok.queue_free()
	await process_frame


func _test_ruzgar() -> void:
	print("[rüzgâr]")
	var kok := Node2D.new()
	root.add_child(kok)
	var z := Zemin.new()
	z.position = Vector2(-200, Ayarlar.ZEMIN_Y)
	z.genislik = 20000.0
	kok.add_child(z)
	var mesafeler := {}
	for guc in [0.0, 90.0, -80.0]:
		var o: Oyuncu = (load("res://scenes/oyuncu.tscn") as PackedScene).instantiate()
		o.position = Vector2(0, Ayarlar.ZEMIN_Y - 2)
		o.hiz = 300.0
		o.iz_acik = false
		kok.add_child(o)
		o.ruzgar = guc
		await _kareler(10)
		dogrula(is_equal_approx(o.velocity.x, 300.0), "yerde rüzgâr koşu hızını değiştirmemeli (%.0f)" % o.velocity.x)
		var bas := o.global_position.x
		o.zipla_bas()
		await _kareler(3)
		dogrula(is_equal_approx(o.velocity.x, 300.0 + guc), "havada yatay hız = hız + rüzgâr (%.0f)" % o.velocity.x)
		var kare := 0
		while not o.is_on_floor() or kare < 5:
			await physics_frame
			kare += 1
			if kare > 200:
				break
		mesafeler[guc] = o.global_position.x - bas
		o.queue_free()
		await process_frame
	dogrula(mesafeler[90.0] > mesafeler[0.0] + 40.0 and mesafeler[-80.0] < mesafeler[0.0] - 40.0,
		"arka rüzgâr zıplamayı uzatmalı, karşı rüzgâr kısaltmalı (%s)" % str(mesafeler))
	kok.queue_free()
	await process_frame
	# Parça ve oyun: bölge aralığı, rüzgâr gücü, HUD etiketi
	var parca: Parca = (load("res://scenes/parcalar/41_karsi_ruzgar.tscn") as PackedScene).instantiate()
	var ra := parca.ruzgar_araliklari()
	dogrula(ra.size() == 1 and is_equal_approx(float(ra[0][2]), -80.0), "rüzgâr aralığı okunmalı: %s" % str(ra))
	parca.free()
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.bot_modu = true
	oyun.sabit_hiz = 300.0
	oyun.kayit_yap = false
	oyun.tohum = 2
	oyun.sira_bitince_duz = true
	var sira: Array[String] = ["res://scenes/parcalar/41_karsi_ruzgar.tscn", "res://scenes/parcalar/42_arka_ruzgar.tscn", "res://scenes/parcalar/43_firtina.tscn"]
	oyun.parca_sirasi = sira
	root.add_child(oyun)
	var goruldu_karsi := false
	var goruldu_arka := false
	var etiket_dogru := true
	for i in 60 * 14:
		await physics_frame
		var r: float = oyun.oyuncu.ruzgar
		var e: Label = oyun.get_node("%RuzgarEtiketi")
		if r < 0.0:
			goruldu_karsi = true
			etiket_dogru = etiket_dogru and e.visible and e.text.contains("karşı")
		elif r > 0.0:
			goruldu_arka = true
			etiket_dogru = etiket_dogru and e.visible and e.text.contains("arka")
		else:
			etiket_dogru = etiket_dogru and not e.visible
	dogrula(goruldu_karsi and goruldu_arka, "koşuda iki yönlü rüzgâr görülmeli")
	dogrula(etiket_dogru, "rüzgâr etiketi yalnız bölgede ve doğru yönle görünmeli")
	dogrula(oyun.oyuncu.canli, "bot rüzgâr parçalarında yaşamalı")
	var t := Ruzgar.new()
	dogrula(Simgeler.YOL != "" and ThemeDB.fallback_font.has_char("←".unicode_at(0)), "rüzgâr etiketindeki ok yazı tipinde olmalı")
	t.free()
	oyun.queue_free()
	await process_frame


func _test_dikey_uyari() -> void:
	print("[dikey uyarısı]")
	dogrula(DikeyUyari.dikey_mi(Vector2(412, 915)) and not DikeyUyari.dikey_mi(Vector2(915, 412)) and not DikeyUyari.dikey_mi(Vector2(1280, 720)),
		"dikey algılama boyuta göre doğru olmalı")
	_kayit_temizle()
	DikeyUyari.zorla = 0
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.kayit_yap = false
	oyun.tohum = 4
	root.add_child(oyun)
	await _kareler(30)
	var du: DikeyUyari = oyun.get_node("DikeyUyari")
	dogrula(du != null and not du.perde.visible and not paused, "yatayda perde kapalı, oyun akıyor")
	DikeyUyari.zorla = 1
	du.denetle()
	await _kareler(2)
	dogrula(du.perde.visible and paused and oyun.duraklat_paneli.visible, "dikeyde perde açılmalı ve koşu duraklamalı")
	DikeyUyari.zorla = 0
	du.denetle()
	await _kareler(2)
	dogrula(not du.perde.visible and paused, "yataya dönünce perde kapanmalı, koşu Devam'ı beklemeli")
	oyun.devam()
	await _kareler(2)
	dogrula(not paused, "Devam ile koşu sürmeli")
	oyun.queue_free()
	await process_frame
	# Menüde de perde var, menü duraklamaz
	DikeyUyari.zorla = 1
	var menu: Control = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _kareler(3)
	var md: DikeyUyari = menu.get_node("DikeyUyari")
	dogrula(md != null and md.perde.visible and not paused, "menüde dikey perdesi görünmeli")
	menu.queue_free()
	await process_frame
	DikeyUyari.zorla = -1
	_kayit_temizle()


# ------------------------------------------------------------------ v0.6
func _test_ritim() -> void:
	print("[ritim koşusu]")
	dogrula(is_equal_approx(Ritim.ADIM, 120.0) and is_equal_approx(Ritim.VURUS_SN, 0.4), "150 BPM × 300 px/sn → vuruş 120 px, 0,4 sn")
	var vk := Ritim.vurus_konumu(100.0 + 3.0 * Ritim.ADIM + 6.0, 100.0)
	dogrula(int(vk[0]) == 3 and absf(float(vk[1]) - 20.0) < 0.01, "6 px geç = 3. vuruş +20 ms (%s)" % str(vk))
	vk = Ritim.vurus_konumu(100.0 + 5.0 * Ritim.ADIM - 12.0, 100.0)
	dogrula(int(vk[0]) == 5 and absf(float(vk[1]) + 40.0) < 0.01, "12 px erken = 5. vuruş −40 ms (%s)" % str(vk))
	# Desen seçimi kuralları
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var kural := true
	var zor2_erken := false
	var zor2_gec := false
	var gorulen_desen := {}
	for i in 600:
		var olcu := i % 30
		var onceki: int = [-1, 0, 1, 2, 3][i % 5]
		var d := Ritim.desen_sec(rng, olcu, onceki)
		var olaylar: Array = d["olaylar"]
		gorulen_desen[d["ad"]] = true
		if olcu < Ritim.ISINMA_OLCU and not olaylar.is_empty():
			kural = false
		if not olaylar.is_empty() and onceki >= 0:
			var bosluk: int = Ritim.OLCU - onceki + int(olaylar[0][0])
			if bosluk < 2 or (str(olaylar[0][1]) == "kisa" and bosluk < 3):
				kural = false
		if int(d["zorluk"]) == 2:
			if olcu < 10:
				zor2_erken = true
			else:
				zor2_gec = true
		for j in olaylar.size():
			var v := int(olaylar[j][0])
			if v < 0 or v >= Ritim.OLCU or (v == 3 and str(olaylar[j][1]) != "diken"):
				kural = false
			if j > 0 and v - int(olaylar[j - 1][0]) < 2:
				kural = false
	dogrula(kural, "ısınma ölçüleri boş; olaylar arası ≥ 2 vuruş, alçak tavana ≥ 3; 3. vuruşta yalnız diken")
	dogrula(gorulen_desen.size() == Ritim.DESENLER.size(), "bütün desenler seçilebilmeli (%d/%d)" % [gorulen_desen.size(), Ritim.DESENLER.size()])
	dogrula(not zor2_erken and zor2_gec, "zor desenler ancak 10. ölçüden sonra")
	# Parça üretimi belirlenimci ve vuruşa hizalı
	var imzalar: Array = []
	for tekrar in 2:
		var r := RandomNumberGenerator.new()
		r.seed = 99
		var sonuc := Ritim.parca_uret(1234.0, 100.0, r, 12, -1)
		var p: Parca = sonuc[0]
		var imza := "%.1f|" % p.uzunluk
		for c in p.get_children():
			imza += "%s@%.1f," % [c.get_class(), c.position.x]
		imzalar.append(imza)
		var giris := p.uzunluk - Ritim.PARCA_OLCU * Ritim.OLCU * Ritim.ADIM
		dogrula(giris >= 0.0 and giris < Ritim.ADIM + 0.01, "parça girişi bir vuruştan kısa (%.1f)" % giris)
		dogrula(is_zero_approx(fposmod(1234.0 + giris - 100.0, Ritim.ADIM)) or is_equal_approx(fposmod(1234.0 + giris - 100.0, Ritim.ADIM), Ritim.ADIM),
			"parçanın ilk vuruşu ızgarada")
		var isaret: RitimIsaret = p.get_node("RitimIsaret")
		var zipla_sayisi := 0
		for z in isaret.zipla:
			zipla_sayisi += z
		dogrula(isaret.vuruslar.size() == 16 and zipla_sayisi == (sonuc[2] as Array).size() and zipla_sayisi > 0,
			"vuruş lambaları olay sayısıyla uyumlu (%d)" % zipla_sayisi)
		p.free()
	dogrula(imzalar[0] == imzalar[1], "aynı tohum aynı ritim parçasını üretmeli")
	var bist := Gorevler.bos_istatistik()
	var bkd := Kayit.yukle()
	bist["ritim"] = 19
	dogrula(not Basarimlar.saglandi_mi("ritim20", bkd, bist, false), "19 tam vuruş başarım için az")
	bist["ritim"] = 20
	dogrula(Basarimlar.saglandi_mi("ritim20", bkd, bist, false), "20 tam vuruş başarımı açmalı")

	# Kusursuz oyuncu: her olay vuruşunda zıplar (alçak tavanda dokunur) → yaşar, hepsi tam vuruş.
	_kayit_temizle()
	var sonuclar := {}
	for gecikme in [0.0, 25.0]:
		var oyun := await _ritim_oyunu(0, 5, false)
		dogrula(oyun.ritim and not oyun.gunluk and not oyun.rahat and is_equal_approx(oyun.oyuncu.hiz, Ritim.HIZ), "ritim koşusu sabit 300 px/sn")
		dogrula(oyun.ipucu.visible and oyun.ipucu.text.contains("lamba"), "ritim koşusunda ipucu lambaları anlatmalı")
		sonuclar[gecikme] = await _ritim_oyna(oyun, gecikme, 60 * 75)
		oyun.queue_free()
		await process_frame
	var s0: Array = sonuclar[0.0]
	var s1: Array = sonuclar[25.0]
	print("  kusursuz: %s  geç: %s" % [str(s0), str(s1)])
	dogrula(s0[0] and s0[1] >= 30, "vuruşta zıplayan oyuncu 75 sn yaşamalı (%s)" % str(s0))
	dogrula(s0[2] == s0[1], "vuruşta zıplamalar tam vuruş sayılmalı (%s)" % str(s0))
	dogrula(s1[0] and s1[1] >= 30, "83 ms geç zıplayan da yaşamalı (pencere geniş) (%s)" % str(s1))
	dogrula(s1[2] == 0, "83 ms geç zıplama tam vuruş sayılmamalı (%s)" % str(s1))

	# İkinci şarkı (128 BPM): vuruş aralığı 140,6 px, aynı engeller, kusursuz oyuncu yaşar.
	dogrula(absf(Ritim.adim(1) - 140.625) < 0.05, "128 BPM → vuruş ≈140,6 px (%.3f)" % Ritim.adim(1))
	var o2 := await _ritim_oyunu(1, 6, false)
	dogrula(is_equal_approx(o2._adim, Ritim.adim(1)), "oyun ikinci şarkının adımını kullanmalı")
	var s2: Array = await _ritim_oyna(o2, 0.0, 60 * 60)
	print("  128 BPM kusursuz: %s" % str(s2))
	dogrula(s2[0] and s2[1] >= 20 and s2[2] == s2[1], "128 BPM'de vuruşta zıplayan yaşar, hepsi tam vuruş (%s)" % str(s2))
	var ilk_parca: Parca = null
	for p in o2.parcalar:
		if p.has_meta("desenler"):
			ilk_parca = p
			break
	var kalan := fposmod(ilk_parca.position.x + ilk_parca.uzunluk - o2._izgara0, Ritim.adim(1)) if ilk_parca else -1.0
	dogrula(ilk_parca != null and minf(kalan, Ritim.adim(1) - kalan) < 0.01, "128 BPM parçaları ızgarada bitmeli (%.4f)" % kalan)
	o2.queue_free()
	await process_frame

	# Bot ritim koşusunda yaşar
	var bo: Node2D = (load(OYUN) as PackedScene).instantiate()
	bo.ritim = true
	bo.bot_modu = true
	bo.kayit_yap = false
	bo.olum_tekrari_acik = false
	bo.tohum = 8
	root.add_child(bo)
	await _kareler(60 * 60)
	dogrula(bo.oyuncu.canli, "bot ritim koşusunda 60 sn yaşamalı (%d m)" % bo.mesafe())
	var ritim_parca := 0
	for p in bo.parcalar:
		if p.name.begins_with("RitimParca"):
			ritim_parca += 1
	dogrula(ritim_parca >= 1, "ritim koşusu ritim parçaları üretmeli")
	bo.queue_free()
	await process_frame

	# Gecikme önerisi: 83 ms geç zıplayan oyuncuya +80 ms önerilir; uygulanınca aynı oyuncu tam vuruş yapar.
	dogrula(Ritim.gecikme_onerisi(0, [10.0, 12.0, 9.0, 11.0, 10.0, 8.0]) == null, "küçük sapmada öneri yok")
	dogrula(Ritim.gecikme_onerisi(0, [80.0, 90.0, 85.0]) == null, "az zıplamada öneri yok")
	dogrula(Ritim.gecikme_onerisi(40, [-60.0, -62.0, -58.0, -61.0, -59.0, -60.0]) == -20, "erken sapma öneriyi düşürür")
	dogrula(Ritim.gecikme_onerisi(280, [90.0, 90.0, 90.0, 90.0, 90.0, 90.0]) == Ritim.GECIKME_ARALIK.y, "öneri üst sınırda kırpılır")
	_kayit_temizle()
	var go := await _ritim_oyunu(0, 5, true)
	var sg: Array = await _ritim_oyna(go, 25.0, 60 * 30)
	go.oyuncu.ol()
	await _kareler(2)
	var gd: Button = go.get_node("%GecikmeDugme")
	dogrula(sg[1] >= 6 and absf(float(go.son_sonuc["ritim_sapma"]) - 83.3) < 5.0, "ortalama sapma ölçülmeli (%s)" % str(go.son_sonuc.get("ritim_sapma")))
	dogrula(gd.visible and gd.text.contains("+80"), "sonuç panelinde +80 ms önerisi (%s)" % gd.text)
	dogrula(go.son_altin.text.contains("Ort. sapma: +83"), "sonuç satırında ortalama sapma (%s)" % go.son_altin.text)
	var ekr: Rect2 = go.get_viewport().get_visible_rect()
	dogrula(ekr.encloses(go.get_node("%SonPaneli").get_global_rect()), "üç düğmeli ritim sonuç paneli ekrana sığmalı")
	gd.pressed.emit()
	dogrula(int(Kayit.ayar("ritim_gecikme")) == 80 and gd.disabled, "öneri uygulanınca ayar yazılmalı")
	go.queue_free()
	await process_frame
	var go2 := await _ritim_oyunu(0, 5, false)
	# Oyuncu müziğe göre (ayar olmadan ızgara = müzik başı) yine 25 px geç zıplıyor.
	dogrula(is_equal_approx(go2._izgara0 - go2._ritim_bas_x, 24.0 + Ritim.HIZ * AudioServer.get_output_latency()), "80 ms ayar ızgarayı 24 px kaydırmalı")
	var sg2: Array = await _ritim_oyna(go2, 25.0, 60 * 30, go2._ritim_bas_x + Ritim.HIZ * AudioServer.get_output_latency())
	dogrula(sg2[0] and sg2[1] >= 6 and sg2[2] == sg2[1], "gecikme ayarıyla geç oyuncu tam vuruş yapmalı (%s)" % str(sg2))
	go2.queue_free()
	await process_frame
	_kayit_temizle()

	# Ayrı rekor (şarkı başına) + menü paneli
	var kd := Kayit.yukle()
	kd["rekor"] = 500
	Kayit.kaydet(kd)
	var ro := await _ritim_oyunu(1, 3, true)
	await _kareler(90)
	ro.oyuncu.ol()
	await _kareler(2)
	kd = Kayit.yukle()
	dogrula(int(kd["rekor"]) == 500 and int(kd["rekor_ritim"]) == 0 and int(kd["rekor_ritim2"]) == ro.son_sonuc["mesafe"] and int(kd["rekor_ritim2"]) > 0,
		"ritim rekoru şarkı başına ayrı tutulmalı (%d / %d / %d)" % [kd["rekor"], kd["rekor_ritim"], kd["rekor_ritim2"]])
	dogrula((kd["olumler_ritim2"] as Array).size() == 1 and (kd["olumler_ritim"] as Array).is_empty() and (kd["olumler"] as Array).is_empty(), "ritim ölümleri şarkı başına ayrı listede")
	dogrula(ro.son_altin.text.contains("Tam vuruş"), "sonuç panelinde tam vuruş sayısı (%s)" % ro.son_altin.text)
	dogrula(ro.rekor_etiketi.text.begins_with("Çatı Neşesi rekoru"), "HUD şarkının rekorunu göstermeli (%s)" % ro.rekor_etiketi.text)
	ro.duraklat()
	ro.queue_free()
	await process_frame
	paused = false
	var menu: Control = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _kareler(3)
	var ekran: Rect2 = menu.get_viewport().get_visible_rect()
	var rd: Button = menu.get_node("%RitimDugme")
	var r2 := int(kd["rekor_ritim2"])
	dogrula(rd.visible and rd.text.begins_with("Ritim") and rd.text.contains("%d m" % r2), "menüde Ritim düğmesi en iyi ritim rekorunu göstermeli (%s)" % rd.text)
	rd.pressed.emit()
	await _kareler(3)
	var rp: Control = menu.get_node("%RitimPaneli")
	dogrula(rp.visible and not menu.get_node("%AnaPanel").visible, "Ritim düğmesi şarkı panelini açmalı")
	dogrula(ekran.encloses(rp.get_global_rect()), "ritim paneli ekrana sığmalı (%s)" % rp.get_global_rect())
	var sd0: Button = menu.get_node("%SarkiDugme0")
	var sd1: Button = menu.get_node("%SarkiDugme1")
	dogrula(sd0.text.begins_with("Gece Koşusu · 150 BPM") and not sd0.text.ends_with(" m"), "1. şarkı düğmesi (%s)" % sd0.text)
	dogrula(sd1.text.begins_with("Çatı Neşesi · 128 BPM") and sd1.text.ends_with("%d m" % r2), "2. şarkı düğmesi rekoru göstermeli (%s)" % sd1.text)
	var gk: HSlider = menu.get_node("%GecikmeKaydirici")
	gk.value = 60
	await _kareler(1)
	dogrula(int(Kayit.ayar("ritim_gecikme")) == 60 and (menu.get_node("%GecikmeDeger") as Label).text == "+60 ms", "gecikme kaydırıcısı ayarı yazmalı")
	(menu.get_node("%RitimGeri") as Button).pressed.emit()
	await _kareler(2)
	dogrula(menu.get_node("%AnaPanel").visible and not rp.visible, "Geri ana menüye dönmeli")
	var cikis: Control = menu.get_node("%CikisDugme")
	dogrula(ekran.encloses(cikis.get_global_rect()) and cikis.get_global_rect().position.y < 40.0, "Çıkış düğmesi sol üstte")
	var dugmeler: Array = []
	for ad in ["%BaslaDugme", "%GunlukDugme", "%KarakterDugme", "%BasarimDugme", "%RitimDugme", "%AyarlarDugme", "%CikisDugme"]:
		dugmeler.append(menu.get_node(ad))
	var cakisma := false
	for i in dugmeler.size():
		for j in range(i + 1, dugmeler.size()):
			if dugmeler[i].visible and dugmeler[j].visible and dugmeler[i].get_global_rect().intersects(dugmeler[j].get_global_rect()):
				cakisma = true
	dogrula(not cakisma, "menü düğmeleri üst üste binmemeli")
	# Şarkı düğmesi ritim kipini ve şarkıyı seçer
	menu.basla(false, true, 1)
	dogrula(Ritim.secili and Ritim.sarki == 1 and not Gunluk.secili, "2. şarkı düğmesi ritim kipini ve şarkıyı seçmeli")
	menu.queue_free()
	await process_frame
	Ritim.secili = false
	Ritim.sarki = 0
	_kayit_temizle()


func _test_gunun_ritmi() -> void:
	print("[günün ritmi]")
	_kayit_temizle()
	for tur in ["", "ritim"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Hayalet.dosya_yolu(tur)))
	Gunluk.tarih_ezme = "2026-09-16"
	var beklenen_sarki := Ritim.gunun_sarkisi("2026-09-16")
	dogrula(Ritim.gunun_tohumu("2026-09-16") == Ritim.gunun_tohumu("2026-09-16") and Ritim.gunun_tohumu("2026-09-16") != Ritim.gunun_tohumu("2026-09-17"),
		"günün ritmi tohumu tarihe bağlı ve belirlenimci")
	dogrula(Ritim.gunun_tohumu("2026-09-16") != Gunluk.tohum("2026-09-16"), "günün ritmi günlük koşudan ayrı tohum kullanmalı")
	var desenler: Array = []
	for t in [3, 11]:
		var o: Node2D = (load(OYUN) as PackedScene).instantiate()
		o.ritim = true
		o.ritim_gunluk = true
		o.ritim_sarki = 1 - beklenen_sarki
		o.kayit_yap = false
		o.olum_tekrari_acik = false
		o.tohum = t
		root.add_child(o)
		await _kareler(60 * 6)
		dogrula(o.ritim_sarki == beklenen_sarki and is_equal_approx(o._adim, Ritim.adim(beklenen_sarki)), "günün şarkısı tarihten seçilmeli")
		var d0: Array = []
		for p in o.parcalar:
			if p.has_meta("desenler"):
				d0.append(p.get_meta("desenler"))
		desenler.append(str(d0))
		o.queue_free()
		await process_frame
	dogrula(desenler[0] == desenler[1] and desenler[0] != "[]", "günün ritmi herkes için aynı dizi (%s)" % desenler[0])
	# Kayıt, rekor yazısı, paylaşım
	var go: Node2D = (load(OYUN) as PackedScene).instantiate()
	go.ritim = true
	go.ritim_gunluk = true
	go.kayit_yap = true
	go.olum_tekrari_acik = false
	root.add_child(go)
	await _kareler(60)
	dogrula(go.rekor_etiketi.text.begins_with("Günün ritmi rekoru"), "HUD günün ritmi rekorunu göstermeli (%s)" % go.rekor_etiketi.text)
	for i in 8:
		go._ritim_sapmalar.append(70.0)
	go.oyuncu.ol()
	await _kareler(2)
	var kd := Kayit.yukle()
	var gr: Dictionary = kd["gunluk_ritim"]
	dogrula(gr["tarih"] == "2026-09-16" and int(gr["deneme"]) == 1 and int(gr["rekor"]) == go.son_sonuc["mesafe"], "günün ritmi kaydı (%s)" % str(gr))
	dogrula(int(kd["gunluk"]["deneme"]) == 0, "günlük koşu kaydına dokunulmamalı")
	dogrula(go.get_node("%PaylasDugme").visible and go.get_node("%GecikmeDugme").visible, "günün ritminde Paylaş ve gecikme önerisi")
	var ekr: Rect2 = go.get_viewport().get_visible_rect()
	dogrula(ekr.encloses(go.get_node("%SonPaneli").get_global_rect()), "dört düğmeli sonuç paneli ekrana sığmalı (%s)" % go.get_node("%SonPaneli").get_global_rect())
	var metin: String = go.paylasim_metni()
	dogrula(metin.begins_with("Tek Tuş Koşu · Günün ritmi (%s) 16.09.2026" % Ritim.SARKILAR[beklenen_sarki]["ad"]) and metin.contains("1. deneme"),
		"günün ritmi paylaşım metni (%s)" % metin)
	dogrula(Gunluk.paylasim_metni("2026-09-16", 10, 1, 10, true, 0).begins_with("Tek Tuş Koşu · Günlük 16.09.2026"), "günlük paylaşım metni değişmemeli")
	go.queue_free()
	await process_frame
	# Hayalet: günün rekoru ayrı dosyaya yazılır, ikinci denemede ızgaraya hizalı geri oynar
	var hr := Hayalet.yukle("2026-09-16", "ritim")
	dogrula(hr != null and hr.sayi() >= 5 and hr.mesafe == int(gr["rekor"]), "günün ritmi hayaleti kaydedilmeli")
	dogrula(Hayalet.yukle("2026-09-16") == null, "günlük koşu hayaleti yazılmamalı")
	var g2: Node2D = (load(OYUN) as PackedScene).instantiate()
	g2.ritim = true
	g2.ritim_gunluk = true
	g2.kayit_yap = false
	g2.olum_tekrari_acik = false
	root.add_child(g2)
	await _kareler(30)
	var hs: AnimatedSprite2D = g2._hayalet_sprite
	dogrula(g2._hayalet_rakip != null and hs != null and hs.visible, "ikinci denemede günün ritmi hayaleti görünmeli")
	if hs:
		var fark := absf(hs.global_position.x - g2.oyuncu.global_position.x)
		dogrula(fark < 40.0, "hayalet oyuncuyla yan yana olmalı (fark %.1f)" % fark)
	await _kareler(60)
	var isaret_var := false
	for c in g2.get_children():
		if c is Isaret and c.metin == "HAYALET":
			isaret_var = true
	dogrula(g2._hayalet_bitti and isaret_var, "hayalet kaydı bitince işaret konmalı")
	g2.queue_free()
	await process_frame
	# Menü düğmesi
	var menu: Control = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _kareler(3)
	var gd: Button = menu.get_node("%GunlukRitimDugme")
	dogrula(gd.text == "Günün ritmi · %s · %d m" % [Ritim.SARKILAR[beklenen_sarki]["ad"], int(gr["rekor"])], "günün ritmi düğmesi (%s)" % gd.text)
	(menu.get_node("%RitimDugme") as Button).pressed.emit()
	await _kareler(3)
	dogrula(menu.get_viewport().get_visible_rect().encloses(menu.get_node("%RitimPaneli").get_global_rect()), "üç düğmeli ritim paneli ekrana sığmalı")
	menu.basla(false, true, beklenen_sarki, true)
	dogrula(Ritim.secili and Ritim.gunluk_secili and not Gunluk.secili, "günün ritmi düğmesi kipi seçmeli")
	menu.queue_free()
	await process_frame
	Ritim.secili = false
	Ritim.gunluk_secili = false
	Ritim.sarki = 0
	Gunluk.tarih_ezme = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Hayalet.dosya_yolu("ritim")))
	_kayit_temizle()


func _ritim_oyunu(sarki: int, tohum: int, kayit: bool) -> Node2D:
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.ritim = true
	oyun.ritim_sarki = sarki
	oyun.kayit_yap = kayit
	oyun.olum_tekrari_acik = false
	oyun.tohum = tohum
	root.add_child(oyun)
	await process_frame
	return oyun


## Her olay vuruşunda (gecikme px kaydırarak) zıplayan oyuncu. Dönüş: [canlı, olay sayısı, tam vuruş, mesafe].
## taban: oyuncunun duyduğu vuruş ızgarasının başı (varsayılan: oyunun ızgarası).
func _ritim_oyna(oyun: Node2D, gecikme: float, kare_sayisi: int, taban := NAN) -> Array:
	var o: Oyuncu = oyun.oyuncu
	var adim: float = oyun._adim
	var t0: float = oyun._izgara0 if is_nan(taban) else taban
	var yapilan := {}
	var olay_sayisi := 0
	var birak := -1
	for kare in kare_sayisi:
		await physics_frame
		if not o.canli:
			break
		if birak == 0:
			o.zipla_birak()
		birak -= 1
		var x := o.global_position.x
		var k := int(round((x - gecikme - t0) / adim))
		var kx: float = t0 + k * adim + gecikme
		if x + 2.5 >= kx and not yapilan.has(k) and oyun._ritim_olaylar.has(k):
			yapilan[k] = true
			olay_sayisi += 1
			var tavan := false
			var olay_x: float = oyun._izgara0 + k * adim
			for t in oyun.dunya_tavan_araliklari():
				if olay_x >= float(t[0]) - 1.0 and olay_x <= float(t[1]):
					tavan = true
			o.zipla_bas()
			birak = 1 if tavan else 24
	return [o.canli, olay_sayisi, int(oyun.istatistik["ritim"]), oyun.mesafe()]

class YakinDinleyici extends Node:
	var sayi := 0

	func yakin_kacis(_t: Node2D) -> void:
		sayi += 1

	func altin_toplandi(_k: Vector2 = Vector2.INF) -> void:
		pass
