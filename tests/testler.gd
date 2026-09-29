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
	# Testler Türkçe metinleri doğrular: dil sabitlenir (CI'nin işletim sistemi dili İngilizce olabilir).
	Ceviri.zorla = "tr"
	Ceviri.dil_uygula()
	GecisKatmani.hizli = true
	GecisKatmani.degistir = false   # menu.basla() sahneyi değiştirip artakalan bir oyun sahnesi bırakmasın (ritim testi bundan kırılgandı)
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
	await _test_v17_histogram_ve_basarimlar()
	await _test_ritim_desen_gecilebilirligi()
	await _test_tema_ve_ceviri()
	await _test_dil_kaydi()
	await _test_yeni_menu_akisi()
	await _test_duraklat_ve_oyun_sonu()
	await _test_ilk_oyun_ogretme()
	await _test_video_gecisleri()
	await _test_his_pencereleri()
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
	# Yenileme: rekor/altın etiketleri zemin bloğunun (y >= 296) üstüne yazılır; ekran içinde kalmalı.
	dogrula(alt_etiket.get_global_rect().end.y <= ekran.end.y and alt_etiket.get_global_rect().position.y >= 290.0,
		"menü rekor/altın etiketleri zemin bloğunda ve ekran içinde olmalı (%s)" % alt_etiket.get_global_rect())
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
	# Şarkı karakteri: Çatı Neşesi'nde alçak tavan desenleri belirgin biçimde daha sık, çukur daha seyrek
	var sayim := {0: {"kisa": 0, "cukur": 0, "ikili": 0}, 1: {"kisa": 0, "cukur": 0, "ikili": 0}, 2: {"kisa": 0, "cukur": 0, "ikili": 0}}
	for sarki in [0, 1, 2]:
		var r2 := RandomNumberGenerator.new()
		r2.seed = 42
		for i in 1500:
			var d2 := Ritim.desen_sec(r2, 12 + i % 20, [-1, 0, 2][i % 3], sarki)
			var diken_sayisi := 0
			for o in d2["olaylar"]:
				if sayim[sarki].has(o[1]):
					sayim[sarki][o[1]] += 1
				if str(o[1]) == "diken":
					diken_sayisi += 1
			if diken_sayisi == 2:
				sayim[sarki]["ikili"] += 1
	dogrula(sayim[1]["kisa"] > sayim[0]["kisa"] * 1.5 and sayim[1]["cukur"] < sayim[0]["cukur"], "şarkı ağırlıkları desen dağılımını değiştirmeli (%s)" % str(sayim))
	# v1.3 Fırtına Hattı: iki dikenli ölçüler (ikili, arka_vurus) belirgin biçimde daha sık, alçak tavan daha seyrek
	dogrula(Ritim.SARKILAR.size() == 3 and sayim[2]["ikili"] > sayim[0]["ikili"] * 1.5 and sayim[2]["kisa"] < sayim[0]["kisa"], "3. şarkıda çift diken daha sık, alçak tavan daha seyrek (%s)" % str(sayim))
	var anahtarlar := {}
	for sk in Ritim.SARKILAR:
		anahtarlar[sk["rekor"]] = true
		dogrula(Kayit.VARSAYILAN.has(sk["rekor"]) and Kayit.VARSAYILAN.has(sk["olumler"]) and ResourceLoader.exists("res://assets/audio/%s.wav" % sk["muzik"]), "şarkının kayıt anahtarları ve müziği olmalı (%s)" % sk["ad"])
	dogrula(anahtarlar.size() == Ritim.SARKILAR.size(), "her şarkının rekor anahtarı ayrı")
	dogrula(is_equal_approx(Ritim.desen_agirligi(Ritim.DESENLER[0], 1), 1.0) and Ritim.desen_agirligi(Ritim.DESENLER[8], 1) > 2.0, "boş desen ağırlığı 1, kisa_diken > 2 (%.2f)" % Ritim.desen_agirligi(Ritim.DESENLER[8], 1))
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
		dogrula(oyun.ipucu.visible and oyun.ipucu.text.contains("çizgi"), "ritim koşusunda ipucu pembe çizgiyi anlatmalı")
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

	# Üçüncü şarkı (140 BPM, v1.3): vuruş aralığı 128,6 px; sık ikili dikende de kusursuz oyuncu yaşar.
	dogrula(absf(Ritim.adim(2) - 128.598) < 0.05, "140 BPM → vuruş ≈128,6 px (%.3f)" % Ritim.adim(2))
	var o3 := await _ritim_oyunu(2, 9, false)
	dogrula(is_equal_approx(o3._adim, Ritim.adim(2)), "oyun üçüncü şarkının adımını kullanmalı")
	var s3: Array = await _ritim_oyna(o3, 0.0, 60 * 60)
	print("  140 BPM kusursuz: %s" % str(s3))
	dogrula(s3[0] and s3[1] >= 20 and s3[2] == s3[1], "140 BPM'de vuruşta zıplayan yaşar, hepsi tam vuruş (%s)" % str(s3))
	var ikili_var := false
	for p in o3.parcalar:
		if p.has_meta("desenler"):
			for ad in p.get_meta("desenler"):
				if str(ad) == "ikili" or str(ad) == "arka_vurus":
					ikili_var = true
	var kalan3 := -1.0
	for p in o3.parcalar:
		if p.has_meta("desenler"):
			kalan3 = fposmod(p.position.x + p.uzunluk - o3._izgara0, Ritim.adim(2))
			break
	dogrula(kalan3 >= 0.0 and minf(kalan3, Ritim.adim(2) - kalan3) < 0.01, "140 BPM parçaları ızgarada bitmeli (%.4f)" % kalan3)
	print("  140 BPM koşusunda çift diken görüldü: %s" % str(ikili_var))
	# v1.5: Fırtına Hattı temayı Fırtına'ya kilitler (yağış açık, yıldız yok), ölçü başlarında şimşek çakar
	var firtina := -1
	for i in o3.TEMALAR.size():
		if str(o3.TEMALAR[i]["ad"]) == "Fırtına":
			firtina = i
	dogrula(firtina == o3.TEMALAR.size() - 1 and firtina >= o3.TEMA_DONGU, "Fırtına teması listenin sonunda, normal döngünün dışında")
	dogrula(o3.tema == firtina and o3.yagis.emitting and is_zero_approx(o3.katman_yildiz.modulate.a), "3. şarkı temayı Fırtına'ya kilitlemeli (tema=%d)" % o3.tema)
	dogrula(o3._simsek_sayisi > 0 and o3._simsek_rect != null and o3._simsek_rect.color.a < 0.46, "60 sn'de en az bir şimşek çakmalı (%d)" % o3._simsek_sayisi)
	o3.queue_free()
	await process_frame
	# Sarsıntı ayarı kapalıyken şimşek yok (fotosensitivite); ilk şarkıda tema kilidi yok, ilk 4 temada döner
	var kd0 := Kayit.yukle()
	kd0["ayarlar"]["sarsinti"] = false
	Kayit.kaydet(kd0)
	var o4 := await _ritim_oyunu(2, 9, false)
	var s4: Array = await _ritim_oyna(o4, 0.0, 60 * 30)
	dogrula(s4[0] and o4._simsek_sayisi == 0 and o4.tema == firtina, "sarsıntı kapalıyken şimşek çakmamalı, tema yine Fırtına (%d)" % o4._simsek_sayisi)
	o4.queue_free()
	await process_frame
	kd0["ayarlar"]["sarsinti"] = true
	Kayit.kaydet(kd0)
	var o5 := await _ritim_oyunu(0, 9, false)
	await _ritim_oyna(o5, 0.0, 60 * 5)
	dogrula(o5.tema >= 0 and o5.tema < o5.TEMA_DONGU and o5._simsek_sayisi == 0, "1. şarkıda tema kilidi ve şimşek yok (tema=%d)" % o5.tema)
	o5.queue_free()
	await process_frame

	# Vuruş ipucu sesi: zıplamadan koşan oyuncu ilk engelde ölene kadar en az bir tık duyar; ayar kapalıyken hiç
	var ipucu_sayilari := {}
	for acik in [true, false]:
		Kayit.ayar_yaz("ritim_ipucu", acik)
		var io := await _ritim_oyunu(0, 5, false)
		for kare in 60 * 30:
			await physics_frame
			if not io.oyuncu.canli:
				break
		ipucu_sayilari[acik] = io._ritim_ipucu_sayisi
		io.queue_free()
		await process_frame
	Kayit.ayar_yaz("ritim_ipucu", true)
	dogrula(int(ipucu_sayilari[true]) >= 1 and int(ipucu_sayilari[false]) == 0, "tık sesi yalnız ayar açıkken ve olay vuruşundan önce (%s)" % str(ipucu_sayilari))

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
	var sd2: Button = menu.get_node("%SarkiDugme2")
	dogrula(sd2.visible and sd2.text.begins_with("Fırtına Hattı · 140 BPM") and sd2.tooltip_text.contains("ikili diken"), "3. şarkı düğmesi (%s)" % sd2.text)
	dogrula(ekran.encloses(rp.get_global_rect()) and sd2.get_global_rect().end.y < (menu.get_node("%GunlukRitimDugme") as Control).get_global_rect().position.y + 1.0, "3 şarkı düğmesi panele sığmalı, günün ritmi altında kalmalı")
	var gk: HSlider = menu.get_node("%GecikmeKaydirici")
	gk.value = 60
	await _kareler(1)
	dogrula(int(Kayit.ayar("ritim_gecikme")) == 60 and (menu.get_node("%GecikmeDeger") as Label).text == "+60 ms", "gecikme kaydırıcısı ayarı yazmalı")
	var ik: CheckButton = menu.get_node("%IpucuSesiKutu")
	dogrula(ik.button_pressed, "tık sesi varsayılan açık")
	ik.button_pressed = false
	await _kareler(1)
	dogrula(not bool(Kayit.ayar("ritim_ipucu")), "tık sesi ayarı yazılmalı")
	ik.button_pressed = true
	await _kareler(1)
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
		o.ritim_sarki = (beklenen_sarki + 1) % Ritim.SARKILAR.size()
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
	# v1.6: günün ritmi geçmişi — bugünün koşusu yazıldı, açıklama satırı geçmişi gösteriyor
	var kd6 := Kayit.yukle()
	var gecmis: Array = kd6.get("gunluk_ritim_gecmis", [])
	dogrula(gecmis.size() == 1 and str(gecmis[0]["tarih"]) == "2026-09-16" and int(gecmis[0]["rekor"]) == int(gr["rekor"]) and int(gecmis[0]["sarki"]) == beklenen_sarki, "günün ritmi geçmişe yazılmalı (%s)" % str(gecmis))
	var aciklama: Label = menu.get_node("%RitimAciklama")
	dogrula(aciklama.text.begins_with("Son günler: 16.09 ") and aciklama.text.ends_with("%d m" % int(gr["rekor"])), "açıklama satırı son günleri göstermeli (%s)" % aciklama.text)
	for i in 9:
		Ritim.gecmis_yaz(kd6, "2026-09-%02d" % (17 + i), i % 3, 100 + i)
	Ritim.gecmis_yaz(kd6, "2026-09-25", 1, 50)
	gecmis = kd6["gunluk_ritim_gecmis"]
	dogrula(gecmis.size() == Ritim.GECMIS_GUN and str(gecmis[0]["tarih"]) == "2026-09-19" and str(gecmis[-1]["tarih"]) == "2026-09-25" and int(gecmis[-1]["rekor"]) == 108, "geçmiş 7 günle sınırlı, aynı gün en iyi kalır (%s)" % str(gecmis))
	var metin6 := Ritim.gecmis_metni(kd6)
	dogrula(metin6.begins_with("Son günler: 25.09 ") and metin6.count(" · ") == 3, "geçmiş metni en yeni önce, en çok 4 gün (%s)" % metin6)
	dogrula(Ritim.gecmis_metni({}) == "", "geçmiş yoksa metin boş")
	# v1.6: şarkı önizlemesi — panel açılınca ilk şarkı, odak değişince o şarkı, Geri'de durur ve menü müziği sürer
	dogrula(Ses.onizleme_adi() == str(Ritim.SARKILAR[0]["muzik"]), "ritim paneli açılınca 1. şarkı önizlenmeli (%s)" % Ses.onizleme_adi())
	(menu.get_node("%SarkiDugme2") as Button).grab_focus()
	await _kareler(2)
	dogrula(Ses.onizleme_adi() == "muzik_ritim3" and Ses._muzik.stream_paused, "3. düğmeye odaklanınca Fırtına Hattı önizlenmeli, menü müziği duraklamalı")
	await _kareler(int(Ritim.ONIZLEME_SN * 60) + 10)
	dogrula(Ses.onizleme_adi() == "" and not Ses._muzik.stream_paused, "önizleme süresi dolunca durmalı, menü müziği sürmeli")
	(menu.get_node("%SarkiDugme1") as Button).grab_focus()
	await _kareler(2)
	dogrula(Ses.onizleme_adi() == "muzik_ritim2", "2. düğme önizlemesi")
	(menu.get_node("%RitimGeri") as Button).pressed.emit()
	await _kareler(2)
	dogrula(Ses.onizleme_adi() == "" and not Ses._muzik.stream_paused, "Geri önizlemeyi durdurmalı")
	(menu.get_node("%BaslaDugme") as Button).grab_focus()
	await _kareler(2)
	dogrula(Ses.onizleme_adi() == "", "ana panelde odak önizleme başlatmamalı")
	(menu.get_node("%RitimDugme") as Button).pressed.emit()
	await _kareler(2)
	menu.basla(false, true, beklenen_sarki, true)
	dogrula(Ses.onizleme_adi() == "", "koşu başlayınca önizleme durmalı")
	dogrula(Ritim.secili and Ritim.gunluk_secili and not Gunluk.secili, "günün ritmi düğmesi kipi seçmeli")
	menu.queue_free()
	await process_frame
	Ritim.secili = false
	Ritim.gunluk_secili = false
	Ritim.sarki = 0
	Gunluk.tarih_ezme = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Hayalet.dosya_yolu("ritim")))
	_kayit_temizle()


## v1.7: sonuç panelinde vuruş sapması histogramı; ritim koşusuna özel üç başarım; iki sütunlu başarım paneli.
func _test_v17_histogram_ve_basarimlar() -> void:
	print("[v1.7: sapma histogramı, ritim başarımları]")
	_kayit_temizle()
	# Kutulama saf hesap: sınırlar TAM_VURUS_MS (70) ve UZAK_MS (150)
	var k := SapmaGrafigi.kutula([-200.0, -151.0, -150.0, -71.0, -70.0, 0.0, 70.0, 71.0, 150.0, 151.0, 240.0])
	dogrula(k == [2, 2, 3, 2, 2], "sapmalar beş kutuya sınırlarıyla ayrılmalı (%s)" % str(k))
	dogrula(SapmaGrafigi.kutula([]) == [0, 0, 0, 0, 0], "boş sapma listesi sıfır kutular")
	# Ritim koşusu sonucu: histogram görünür, sayılar sapmalardan; sonuç paneli sığar
	var go: Node2D = await _ritim_oyunu(0, 5, true)
	await _kareler(30)
	for ms in [-180.0, -90.0, -20.0, 10.0, 60.0, 100.0, 200.0]:
		go._ritim_sapmalar.append(ms)
	go.oyuncu.ol()
	await _kareler(2)
	var grafik: SapmaGrafigi = go.get_node("%SonSapma")
	dogrula(grafik.visible and grafik.sayilar == [1, 1, 3, 1, 1] and grafik.toplam() == 7, "ritim sonucunda histogram sapmaları saymalı (%s)" % str(grafik.sayilar))
	dogrula((go.son_sonuc["ritim_sapmalar"] as Array).size() == 7, "sonuç sapma listesini taşımalı")
	dogrula(not go.get_node("%SonIpucu").visible, "histogram varken alt ipucu gizlenmeli")
	var ekr: Rect2 = go.get_viewport().get_visible_rect()
	dogrula(ekr.encloses(go.get_node("%SonPaneli").get_global_rect()), "histogramlı ritim sonuç paneli ekrana sığmalı (%s)" % go.get_node("%SonPaneli").get_global_rect())
	# Kalabalık ritim paneli: yeni başarım + görevler + histogram birlikte sığmalı
	go.son_sonuc["basarimlar"] = [Basarimlar.tanim("ritim100"), Basarimlar.tanim("m500")]
	go.son_sonuc["gorev"] = {"tamamlanan": [{"metin": "Tek koşuda 120 m koş"}], "odul": 70, "seviye_atladi": true}
	go._son_paneli_goster()
	await _kareler(2)
	dogrula(ekr.encloses(go.get_node("%SonPaneli").get_global_rect()), "kalabalık histogramlı sonuç paneli ekrana sığmalı (%s)" % go.get_node("%SonPaneli").get_global_rect())
	dogrula(grafik.visible, "orta kalabalıkta histogram görünür kalmalı")
	# En kalabalık koşu: 3 görev tamamlandı + seviye + 3 yeni görev + başarım satırı (8 satır).
	# Histogram sığmaz; panel yine de ekranda kalmalı (başlık kırpılmasın) ve grafik düşmeli.
	go.son_sonuc["gorev"] = {"tamamlanan": [{"metin": "Tek koşuda 120 m koş"}, {"metin": "Toplam 60 altın topla"},
			{"metin": "Tek koşuda 3 kez havada zıpla"}], "odul": 190, "seviye_atladi": true}
	go._son_paneli_goster()
	await _kareler(2)
	var kp: Rect2 = go.get_node("%SonPaneli").get_global_rect()
	dogrula(ekr.encloses(kp), "en kalabalık ritim sonuç paneli ekrana sığmalı (%s)" % kp)
	# Yenileme: küçük mono yazılarla 8 satırlık panel de sığıyor; kural aynı: histogram yalnız panel sığıyorsa görünür.
	dogrula(grafik.visible == (go.get_node("%SonPaneli").get_combined_minimum_size().y <= ekr.size.y), "histogram yalnız panel sığıyorsa görünmeli")
	dogrula(go.get_node("%SonGorevler").text.split("\n").size() == 8, "en kalabalık panelde 8 görev satırı")
	go.queue_free()
	await process_frame
	# Normal koşuda histogram gizli
	var no: Node2D = (load(OYUN) as PackedScene).instantiate()
	no.kayit_yap = false
	no.olum_tekrari_acik = false
	root.add_child(no)
	await _kareler(20)
	no.oyuncu.ol()
	await _kareler(2)
	dogrula(not no.get_node("%SonSapma").visible and no.get_node("%SonIpucu").visible, "normal koşuda histogram gizli, ipucu görünür")
	no.queue_free()
	await process_frame
	# Başarımlar: tanımlar ve koşullar
	for id in ["ritim100", "uc_sarki300", "gunluk_ritim5"]:
		dogrula(not Basarimlar.tanim(id).is_empty(), "başarım tanımlı: %s" % id)
	dogrula(Basarimlar.LISTE.size() == 16 and bool(Basarimlar.tanim("ritim100")["tek"]) and not bool(Basarimlar.tanim("uc_sarki300")["tek"]), "16 başarım; Metronom anlık, diğer ikisi koşu sonu")
	_kayit_temizle()
	var d := Kayit.yukle()
	var ist := Gorevler.bos_istatistik()
	ist["ritim"] = 99
	dogrula(not Basarimlar.saglandi_mi("ritim100", d, ist, false), "99 tam vuruş Metronom'u açmamalı")
	ist["ritim"] = 100
	dogrula(Basarimlar.saglandi_mi("ritim100", d, ist, false), "100 tam vuruş Metronom'u açmalı")
	dogrula(not Basarimlar.saglandi_mi("uc_sarki300", d, ist, false), "rekorsuz Üç şarkı açılmamalı")
	for s in Ritim.SARKILAR:
		d[str(s["rekor"])] = 300
	dogrula(Basarimlar.saglandi_mi("uc_sarki300", d, ist, false), "üç şarkıda 300 m rekorla Üç şarkı açılmalı")
	d[str(Ritim.SARKILAR[2]["rekor"])] = 299
	dogrula(not Basarimlar.saglandi_mi("uc_sarki300", d, ist, false), "bir şarkı 299 m ise Üç şarkı açılmamalı")
	for i in 4:
		Ritim.gecmis_yaz(d, "2026-09-%02d" % (10 + i), 0, 100)
	dogrula(not Basarimlar.saglandi_mi("gunluk_ritim5", d, ist, false), "4 günlük geçmiş Ritim müdavimi'ni açmamalı")
	Ritim.gecmis_yaz(d, "2026-09-10", 0, 150)   # aynı gün: sayı artmaz
	dogrula(not Basarimlar.saglandi_mi("gunluk_ritim5", d, ist, false), "aynı gün tekrar koşmak gün saymamalı")
	Ritim.gecmis_yaz(d, "2026-09-14", 1, 100)
	dogrula(Basarimlar.saglandi_mi("gunluk_ritim5", d, ist, false), "5 ayrı gün Ritim müdavimi'ni açmalı")
	# Koşu sonunda gerçek akış: şarkı rekoru denetimden önce yazılır → Üç şarkı açılır
	_kayit_temizle()
	var d2 := Kayit.yukle()
	for s in Ritim.SARKILAR:
		d2[str(s["rekor"])] = 300
	Kayit.kaydet(d2)
	var uo: Node2D = await _ritim_oyunu(0, 5, true)
	await _kareler(20)
	uo.istatistik["ritim"] = 100
	uo.oyuncu.ol()
	await _kareler(2)
	var acilan: Array = (uo.son_sonuc["basarimlar"] as Array).map(func(b: Dictionary) -> String: return str(b["id"]))
	dogrula(acilan.has("ritim100") and acilan.has("uc_sarki300") and not acilan.has("gunluk_ritim5"), "koşu sonunda Metronom ve Üç şarkı açılmalı (%s)" % str(acilan))
	var kd: Array = Kayit.yukle()["basarimlar"]
	dogrula(kd.has("ritim100") and kd.has("uc_sarki300"), "açılan ritim başarımları kayda yazılmalı")
	dogrula(uo.get_node("%SonGorevler").text.contains("Metronom, Üç şarkı"), "sonuç paneli yeni başarımları listelemeli (%s)" % uo.get_node("%SonGorevler").text)
	uo.queue_free()
	await process_frame
	# Anlık duyuru: Metronom "tek" → koşu içinde bildirilir (temiz kayıt: önceki koşu açmıştı)
	_kayit_temizle()
	var ao: Node2D = await _ritim_oyunu(1, 3, false)
	await _kareler(10)
	ao.istatistik["ritim"] = 100
	var anlik := Basarimlar.anlik(Kayit.yukle(), ao.istatistik, false, [])
	dogrula(anlik.map(func(b: Dictionary) -> String: return str(b["id"])).has("ritim100"), "Metronom koşu içinde anlık duyurulmalı")
	ao.queue_free()
	await process_frame
	# Menü: 16 başarım iki sütunlu ızgarada, panel 360 px'e sığar, düğme sayısı /16
	_kayit_temizle()
	var menu: Control = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _kareler(3)
	dogrula(menu.get_node("%BasarimDugme").text.ends_with("/16"), "başarım düğmesi 0/16 göstermeli (%s)" % menu.get_node("%BasarimDugme").text)
	(menu.get_node("%BasarimDugme") as Button).pressed.emit()
	await _kareler(3)
	var liste: GridContainer = menu.get_node("%BasarimListesi")
	var bp: Control = menu.get_node("%BasarimPaneli")
	dogrula(liste.columns == 2 and liste.get_child_count() == 16, "başarım listesi iki sütun, 16 satır")
	dogrula(menu.get_viewport().get_visible_rect().encloses(bp.get_global_rect()), "16 başarımlı panel ekrana sığmalı (%s)" % bp.get_global_rect())
	var son: Label = liste.get_child(15)
	dogrula(son.text.begins_with("☆ Ritim müdavimi"), "son satır yeni başarım (%s)" % son.text)
	menu.queue_free()
	await process_frame
	Ritim.secili = false
	_kayit_temizle()


# --------------------------------------------- ritim: her desen, her şarkıda
## Sonsuz koşuda her parça, en düşük ve en yüksek hızında bot ile geçiliyor
## (`_test_gecilebilirlik`). Ritim koşusunun karşılığı yoktu: bot yalnız rastgele
## üretilmiş bir akışta koşuyordu, ve rastgele seçim her deseni her şarkıda
## üretmiyor -- şarkı ağırlıkları bazılarını bilerek seyrekleştiriyor
## (Fırtına Hattı'nda alçak tavan ×0,6, Çatı Neşesi'nde çukur ×0,7).
##
## Önemli olan da tam bu: engel geometrisi mutlak piksel (diken vuruştan +99,
## çukur +40..+160, alçak tavan −60'tan 260 px), vuruş aralığı ise şarkıya göre
## değişiyor (120 / 140,6 / 128,6 px). Aynı desen dar aralıklı bir şarkıda
## geçilemez olabilir, ve o ölçü seyrek çıkıyorsa suit yeşil kalır.
func _test_ritim_desen_gecilebilirligi() -> void:
	print("[ritim: her desen, her şarkının vuruş aralığında, kusursuz bot ile]")
	for sarki in Ritim.SARKILAR.size():
		var adim: float = Ritim.adim(sarki)
		for d in Ritim.DESENLER:
			var ad := str(d["ad"])
			if (d["olaylar"] as Array).is_empty():
				continue
			# Isınma iki ölçü boş; sonra desen, arasına boş ölçü koyarak iki kez.
			# Boş ölçü, jeneratörün kendi kuralını (olaylar arası ≥ 2 vuruş,
			# alçak tavana ≥ 3) her zaman sağlıyor -- yani sınanan şey, üretimin
			# gerçekten üretebileceği bir dünya.
			var sira: Array[String] = ["bos", "bos", ad, "bos", ad, "bos", ad, "bos"]
			var oyun: Node2D = await _ritim_oyunu(sarki, 7, false, sira, true)
			var sonuc := await _ritim_oyna(oyun, 0.0, 1200)
			dogrula(bool(sonuc[0]), "%s deseni %s şarkısında (vuruş %.1f px) geçilemedi (neden %s, x %.0f, y %.0f, ızgara %.0f)"
				% [ad, Ritim.SARKILAR[sarki]["ad"], adim, str(oyun.oyuncu.olum_nedeni), oyun.oyuncu.global_position.x, oyun.oyuncu.global_position.y, oyun._izgara0])
			dogrula(int(sonuc[1]) >= 3, "%s / %s: desen en az üç kez olay vermeli (%d)"
				% [ad, Ritim.SARKILAR[sarki]["ad"], int(sonuc[1])])
			dogrula(int(sonuc[2]) == int(sonuc[1]),
				"%s / %s: vuruşta zıplayan botun her zıplaması tam vuruş olmalı (%d/%d)"
				% [ad, Ritim.SARKILAR[sarki]["ad"], int(sonuc[2]), int(sonuc[1])])
			oyun.queue_free()
			await process_frame
	_kayit_temizle()


## `desenler` verilirse ritim ölçüleri AĞACA GİRMEDEN önce kilitlenir. Sonradan
## atamak yetmiyordu: `_ready` ilk parçaları hemen üretiyor, yani koşunun ilk
## ölçüleri rastgele kalıyor ve orada gelen bir ölçüde ölüm, sınanan desene
## yazılıyordu -- negatif kontrol bunu gösterdi.
func _ritim_oyunu(sarki: int, tohum: int, kayit: bool, desenler: Array[String] = [],
		bitince_bos := false) -> Node2D:
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.ritim = true
	oyun.ritim_sarki = sarki
	oyun.kayit_yap = kayit
	oyun.olum_tekrari_acik = false
	oyun.tohum = tohum
	if not desenler.is_empty() or bitince_bos:
		oyun.ritim_desen_sirasi = desenler.duplicate()
		oyun.ritim_sira_bitince_bos = bitince_bos
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

# ------------------------------------------------------------------ yenileme: tema, dil, menü, duraklat, oyun sonu, öğretme
func _metin_dosyalari(klasor: String = "res://") -> Array[String]:
	var sonuc: Array[String] = []
	for ad in DirAccess.get_directories_at(klasor):
		if ad.begins_with(".") or ad in ["build", "_eski", "dev"]:
			continue
		sonuc.append_array(_metin_dosyalari(klasor.path_join(ad)))
	for ad in DirAccess.get_files_at(klasor):
		if ad.ends_with(".gd") or ad.ends_with(".tscn"):
			sonuc.append(klasor.path_join(ad))
	return sonuc


func _test_tema_ve_ceviri() -> void:
	print("[tema ve çeviri]")
	# Proje teması: yazı tipleri ve varyasyonlar
	var tema := ThemeDB.get_project_theme()
	dogrula(tema != null, "proje teması (assets/tema.tres) yüklü olmalı")
	if tema:
		for v in ["Govde", "Baslik", "Etiket", "EtiketKalin", "KartBaslik", "KartYazi", "KartEtiket"]:
			dogrula(String(tema.get_type_variation_base(v)) == "Label", "tema Label varyasyonu: " + v)
		for v in ["Birincil", "KartDugme", "Kucuk"]:
			dogrula(String(tema.get_type_variation_base(v)) == "Button", "tema Button varyasyonu: " + v)
		dogrula(String(tema.get_type_variation_base("KagitKart")) == "PanelContainer", "tema KagitKart varyasyonu")
		var f: Font = tema.get_font("font", "Baslik")
		dogrula(f != null and f.get_font_name() != "", "başlık yazı tipi tanımlı (Instrument Sans)")
	dogrula(Tema.buyuk("işık") == "İŞIK" and Tema.buyuk("ıslak") == "ISLAK", "Türkçe büyük harf: i→İ, ı→I (%s)" % Tema.buyuk("işık"))
	# Düz renk dünya: temalarda degrade yok (ust == alt), siluet katmanları renkleniyor
	var oyun_betik: GDScript = load("res://scripts/oyun.gd")
	var temalar: Array = oyun_betik.get_script_constant_map()["TEMALAR"]
	var duz := true
	for t in temalar:
		duz = duz and t["ust"] == t["alt"]
	dogrula(duz and temalar.size() == 5, "5 dünya teması, hepsi tek renk gökyüzü (degradesiz)")
	# Çeviri: koddaki her tr()/Ceviri.t() anahtarı EN tablosunda; biçim belirteçleri aynı
	var eksik := PackedStringArray()
	var bicim := PackedStringArray()
	var r := RegEx.new()
	r.compile("(?<![A-Za-z_])(?:Ceviri\\.t|tr)\\(\\s*\"((?:[^\"\\\\]|\\\\.)*)\"")
	var kaynak := 0
	for yol in _metin_dosyalari():
		if not yol.ends_with(".gd") or yol.ends_with("ceviri.gd") or yol.contains("/tests/"):
			continue
		for m in r.search_all(FileAccess.get_file_as_string(yol)):
			var k: String = m.get_string(1)
			kaynak += 1
			if not Ceviri.EN.has(k):
				eksik.append("%s: %s" % [yol.get_file(), k])
	dogrula(kaynak > 40 and eksik.is_empty(), "koddaki %d tr() metninin hepsi İngilizce tabloda (%s)" % [kaynak, "; ".join(eksik)])
	# Sahnelerdeki düğme/etiket metinleri de anahtar
	var sahne_eksik := PackedStringArray()
	var rs := RegEx.new()
	rs.compile("\\ntext = \"((?:[^\"\\\\]|\\\\.)*)\"")
	for yol in ["res://scenes/menu.tscn", "res://scenes/oyun.tscn"]:
		for m in rs.search_all(FileAccess.get_file_as_string(yol)):
			var k: String = m.get_string(1).replace("\\n", "\n")
			if k == "" or k.is_valid_int() or k in ["II", "TR", "0 m"] or not Ceviri.EN.has(k) and _sahne_metni_calisma_aninda(k):
				continue
			if not Ceviri.EN.has(k):
				sahne_eksik.append(k)
	dogrula(sahne_eksik.is_empty(), "sahne metinlerinin çevirisi var (%s)" % "; ".join(sahne_eksik))
	# Veri kaynaklı metinler: görev şablonları, başarımlar, şarkılar, kostümler, temalar, histogram
	var veri_eksik := PackedStringArray()
	for sure in Gorevler.SABLONLAR:
		for sb in Gorevler.SABLONLAR[sure]:
			if not Ceviri.EN.has(String(sb["metin"])):
				veri_eksik.append(String(sb["metin"]))
	for b in Basarimlar.LISTE:
		for alan in ["ad", "metin"]:
			if not Ceviri.EN.has(String(b[alan])):
				veri_eksik.append(String(b[alan]))
	for sk in Ritim.SARKILAR:
		for alan in ["ad", "aciklama"]:
			if not Ceviri.EN.has(String(sk[alan])):
				veri_eksik.append(String(sk[alan]))
	for k in Kostumler.LISTE:
		if not Ceviri.EN.has(String(k["isim"])):
			veri_eksik.append(String(k["isim"]))
	for t in temalar:
		if not Ceviri.EN.has(String(t["ad"])) and String(t["ad"]) != "Gece":
			veri_eksik.append(String(t["ad"]))
	for ad in SapmaGrafigi.KUTU_ADLARI:
		if not Ceviri.EN.has(ad):
			veri_eksik.append(ad)
	dogrula(veri_eksik.is_empty(), "görev/başarım/şarkı/kostüm/tema/histogram metinlerinin çevirisi var (%s)" % "; ".join(veri_eksik))
	var uyusmaz := PackedStringArray()
	for k in Ceviri.EN:
		if Ceviri.belirtecler(k) != Ceviri.belirtecler(Ceviri.EN[k]):
			uyusmaz.append(k)
	dogrula(uyusmaz.is_empty(), "çeviride biçim belirteçleri kaynakla aynı (%s)" % "; ".join(uyusmaz))
	dogrula(not Ceviri.EN.has("") and Ceviri.EN.size() > 100, "çeviri tablosu dolu (%d anahtar)" % Ceviri.EN.size())


## Sahne .tscn'lerinde varsayılan metni çalışma anında ezilen düğmeler (yer tutucu) çeviri istemez.
func _sahne_metni_calisma_aninda(k: String) -> bool:
	return k.begins_with("Mesafe: ") or k.begins_with("Rekor: ") or k.begins_with("Altın: ") or k == "GÖREVLER" \
		or k.begins_with("Şarkı ") or k in ["Dil: Türkçe", "Türkçe", "Gecikme"] or k.ends_with(" ms") or k == "Zıpla: Boşluk ya da dokun"


func _test_dil_kaydi() -> void:
	print("[dil seçimi ve kayıt uyumu]")
	_kayit_temizle()
	Ceviri.zorla = ""
	# Kayıtlı seçim yoksa işletim sistemi dili: yalnız "tr" Türkçe, gerisi İngilizce
	var beklenen := "tr" if OS.get_locale_language() == "tr" else "en"
	dogrula(Ceviri.dil_etkin("") == beklenen, "varsayılan dil işletim sistemi/tarayıcı diline bağlı (%s)" % beklenen)
	dogrula(Ceviri.dil_etkin("en") == "en" and Ceviri.dil_etkin("tr") == "tr", "kayıtlı dil tercihi önceliklidir")
	dogrula(Ceviri.dil_etkin("fr") == beklenen, "geçersiz kayıtlı dil yok sayılır")
	# Eski kayıt (dil anahtarı yok) bozulmadan yüklenir, yeni anahtar varsayılanla gelir
	var eski := ConfigFile.new()
	eski.set_value("oyuncu", "rekor", 412)
	eski.set_value("oyuncu", "toplam_altin", 77)
	eski.set_value("oyuncu", "ayarlar", {"muzik": 0.4, "efekt": 0.5, "tam_ekran": false, "sarsinti": true, "kontrast": false, "rahat": false})
	eski.save(Kayit.yol)
	var d := Kayit.yukle()
	dogrula(int(d["rekor"]) == 412 and int(d["toplam_altin"]) == 77 and is_equal_approx(float(d["ayarlar"]["muzik"]), 0.4), "eski kayıt (dil yok) bozulmadan yüklenmeli")
	dogrula(String(d["ayarlar"]["dil"]) == "", "yeni 'dil' anahtarı varsayılan boş (otomatik)")
	# Dil değiştir: tercih kaydedilir, rekor korunur, metinler değişir
	Ceviri.zorla = "tr"
	Ceviri.dil_uygula()
	dogrula(tr("Oyna") == "Oyna" and Ceviri.t("Paylaş") == "Paylaş", "Türkçede anahtar aynen döner")
	Ceviri.dil_degistir()
	dogrula(Ceviri.dil_kodu() == "en" and tr("Oyna") == "Play" and Ceviri.t("Rekor: %d m") == "Best: %d m", "İngilizceye geçince metinler değişmeli")
	dogrula(String(Kayit.yukle()["ayarlar"]["dil"]) == "en" and int(Kayit.yukle()["rekor"]) == 412, "dil tercihi kaydedilmeli, rekor bozulmamalı")
	# Görev metni kayıtlı Türkçe metinden değil şablondan çevrilir
	var g := {"id": "k_mesafe", "hedef": 120, "metin": "Tek koşuda 120 m koş"}
	dogrula(Gorevler.metin_ad(g) == "Run 120 m in one run", "görev metni şablondan çevrilmeli (%s)" % Gorevler.metin_ad(g))
	Ceviri.dil_degistir()
	dogrula(Ceviri.dil_kodu() == "tr" and Gorevler.metin_ad(g) == "Tek koşuda 120 m koş", "Türkçeye dönünce görev metni aynı")
	_kayit_temizle()


func _test_yeni_menu_akisi() -> void:
	print("[yeni menü: OYNA, dil, paneller, geçiş]")
	_kayit_temizle()
	var menu: Control = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _kareler(4)
	var oyna: Button = menu.get_node("%BaslaDugme")
	dogrula(oyna.theme_type_variation == &"Birincil" and oyna.custom_minimum_size.y >= 40.0 and tr(oyna.text) == "Oyna", "büyük birincil OYNA düğmesi")
	dogrula(oyna.has_focus() or menu.get_viewport().gui_get_focus_owner() == oyna, "açılışta odak OYNA'da")
	var nasil: Label = menu.get_node("%Nasil")
	dogrula(nasil.visible and not nasil.text.contains("\n") and nasil.text.contains("zıpla"), "tek satır nasıl oynanır")
	var ekran: Rect2 = menu.get_viewport().get_visible_rect()
	for ad in ["BaslaDugme", "RitimDugme", "GunlukDugme", "KarakterDugme", "BasarimDugme", "AyarlarDugme", "DilDugme"]:
		dogrula(ekran.encloses((menu.get_node("%" + ad) as Control).get_global_rect()), "menü düğmesi ekrana sığmalı: " + ad)
	# Dil düğmesi: TR -> EN, metinler değişir, kayıt yazılır
	var dd: Button = menu.get_node("%DilDugme")
	dogrula(dd.text == "TR", "dil düğmesi etkin dili gösterir")
	dd.pressed.emit()
	await _kareler(2)
	dogrula(dd.text == "EN" and tr(oyna.text) == "Play" and (menu.get_node("%RitimDugme") as Button).text == "Rhythm", "dil düğmesi menüyü İngilizceye çevirmeli (%s / %s)" % [tr(oyna.text), (menu.get_node("%RitimDugme") as Button).text])
	dogrula((menu.get_node("%RekorEtiketi") as Label).text.begins_with("Best"), "rekor etiketi çevrilmeli (%s)" % (menu.get_node("%RekorEtiketi") as Label).text)
	dogrula(String(Kayit.yukle()["ayarlar"]["dil"]) == "en", "menüden seçilen dil kaydedilmeli")
	# Ayarlar panelindeki dil düğmesi de aynı işi yapar
	(menu.get_node("%AyarlarDugme") as Button).pressed.emit()
	await _kareler(3)
	var adb: Button = menu.get_node("%AyarDilDugme")
	dogrula(adb.text == "English", "ayarlar dil düğmesi etkin dilin adını yazmalı (%s)" % adb.text)
	adb.pressed.emit()
	await _kareler(2)
	dogrula(adb.text == "Türkçe" and dd.text == "TR" and tr(oyna.text) == "Oyna", "ayarlardan Türkçeye dönülebilmeli")
	# Esc panelden ana menüye döner; alt paneller açıkken dil/alt satır gizli
	dogrula(not menu.get_node("%Alt").visible and not dd.visible, "ayarlar açıkken alt satır ve dil düğmesi gizli")
	var ev := InputEventAction.new()
	ev.action = &"duraklat"
	ev.pressed = true
	menu._unhandled_input(ev)
	await _kareler(2)
	dogrula(menu.get_node("%AnaPanel").visible and menu.get_node("%Alt").visible and dd.visible, "Esc ayarlardan ana menüye döndürmeli")
	# Görev listesi küçük etiket ve başlık çevirisi
	dogrula((menu.get_node("%GorevListesi") as Label).text.begins_with("GÖREVLER"), "görev listesi başlığı büyük harf (%s)" % (menu.get_node("%GorevListesi") as Label).text.get_slice("\n", 0))
	menu.queue_free()
	await process_frame
	# Geçiş katmanı: kapat -> örter, ac -> açılır (gerçek süreyle; ayrıntı _test_video_gecisleri'nde)
	var gecis: CanvasLayer = root.get_node("Gecis")
	dogrula(gecis != null and gecis.layer == 100, "Gecis autoload'u var")
	GecisKatmani.hizli = false
	await gecis.kapat(&"iris", 0, 0.05)
	dogrula(gecis._kaplama.visible and is_equal_approx(float(gecis._mat.get_shader_parameter("p")), 1.0), "geçiş ekranı örtmeli")
	await gecis.ac(0.05)
	dogrula(not gecis._kaplama.visible and not gecis.mesgul_mu(), "geçiş açılınca kapanmalı")
	GecisKatmani.hizli = true
	_kayit_temizle()
	Ceviri.zorla = "tr"
	Ceviri.dil_uygula()


func _test_duraklat_ve_oyun_sonu() -> void:
	print("[duraklat kartı ve oyun sonu kartı]")
	_kayit_temizle()
	var d := Kayit.yukle()
	d["rekor"] = 100
	Kayit.kaydet(d)
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.kayit_yap = true
	oyun.olum_tekrari_acik = false
	oyun.tohum = 5
	root.add_child(oyun)
	await _kareler(20)
	var perde: Control = oyun.get_node("%DuraklatPerde")
	dogrula(not oyun.duraklat_paneli.visible and not perde.visible, "koşarken duraklat kartı gizli")
	(oyun.get_node("%DuraklatDugme") as Button).pressed.emit()
	await _kareler(2)
	dogrula(paused and oyun.duraklat_paneli.visible and perde.visible, "duraklat düğmesi kartı ve perdeyi açmalı")
	dogrula((oyun.get_node("%DevamDugme") as Button).has_focus(), "duraklat kartında odak Devam'da")
	for ad in ["DevamDugme", "BastanDugme", "DurAyarDugme", "MenuDugme"]:
		dogrula((oyun.get_node("%" + ad) as Button).visible, "duraklat kartında düğme: " + ad)
	dogrula(not oyun.get_node("%DurAyarlar").visible, "ayar bölümü kapalı başlar")
	(oyun.get_node("%DurAyarDugme") as Button).pressed.emit()
	dogrula(oyun.get_node("%DurAyarlar").visible, "Ayarlar düğmesi ses ve dil bölümünü açmalı")
	(oyun.get_node("%DurMuzik") as HSlider).value = 35.0
	await _kareler(1)
	dogrula(is_equal_approx(float(Kayit.yukle()["ayarlar"]["muzik"]), 0.35), "duraklattaki müzik kaydırıcısı kaydetmeli")
	(oyun.get_node("%DurDilDugme") as Button).pressed.emit()
	await _kareler(1)
	dogrula(Ceviri.dil_kodu() == "en" and tr((oyun.get_node("%DevamDugme") as Button).text) == "Resume" and (oyun.get_node("%DurDilDugme") as Button).text == "Language: English",
		"duraklattaki dil düğmesi oyunu İngilizceye çevirmeli (%s)" % tr((oyun.get_node("%DevamDugme") as Button).text))
	(oyun.get_node("%DurDilDugme") as Button).pressed.emit()
	await _kareler(1)
	dogrula(Ceviri.dil_kodu() == "tr" and tr((oyun.get_node("%DevamDugme") as Button).text) == "Devam", "dil geri Türkçe")
	var kesit: float = oyun.sure
	await _kareler(10)
	dogrula(is_equal_approx(oyun.sure, kesit), "duraklatılınca oyun zamanı akmamalı")
	(oyun.get_node("%DevamDugme") as Button).pressed.emit()
	await _kareler(3)
	dogrula(not paused and not oyun.duraklat_paneli.visible and not perde.visible and oyun.sure > kesit, "Devam koşuyu sürdürmeli")
	# Esc ile de duraklat / devam
	var ev := InputEventAction.new()
	ev.action = &"duraklat"
	ev.pressed = true
	oyun._unhandled_input(ev)
	dogrula(paused and oyun.duraklat_paneli.visible, "Esc/P duraklatır")
	oyun._unhandled_input(ev)
	dogrula(not paused and not oyun.duraklat_paneli.visible, "Esc/P tekrar basınca devam eder")
	# Baştan: koşu sıfırlanır
	await _kareler(30)
	oyun.duraklat()
	(oyun.get_node("%BastanDugme") as Button).pressed.emit()
	await _kareler(2)
	dogrula(not paused and oyun.sure < 0.2 and oyun.mesafe() <= 1 and not oyun.duraklat_paneli.visible, "Baştan duraklatmayı kapatıp koşuyu sıfırlamalı")
	# Oyun sonu: yeni rekor kartı, tek dokunuşla tekrar
	oyun.baslangic_x -= 150.0 * Ayarlar.PIKSEL_METRE
	oyun.oyuncu.ol()
	await _kareler(3)
	var sp: Control = oyun.get_node("%SonPaneli")
	dogrula(oyun.bitti and sp.visible, "ölünce oyun sonu kartı açılmalı")
	dogrula(oyun.get_node("%SonSkor").text.begins_with("Mesafe: 15"), "büyük skor (%s)" % oyun.get_node("%SonSkor").text)
	dogrula(oyun.get_node("%SonRekor").text == "YENİ REKOR!", "rekor aşılınca YENİ REKOR damgası (%s)" % oyun.get_node("%SonRekor").text)
	dogrula((oyun.get_node("%TekrarDugme") as Button).has_focus() and (oyun.get_node("%TekrarDugme") as Button).theme_type_variation == &"Birincil", "ilk odak birincil TEKRAR düğmesinde")
	dogrula(int(Kayit.yukle()["rekor"]) >= 150, "rekor kaydedilmeli")
	dogrula(oyun.get_viewport().get_visible_rect().encloses(sp.get_global_rect()), "oyun sonu kartı ekrana sığmalı")
	oyun._yeniden_baslat_izni = 0.0
	# Tek dokunuş: sol tık / Boşluk kartı kapatıp yeniden başlatır
	var dokun := InputEventAction.new()
	dokun.action = &"zipla"
	dokun.pressed = true
	oyun._unhandled_input(dokun)
	await _kareler(2)
	dogrula(not oyun.bitti and not sp.visible and oyun.oyuncu.canli, "tek dokunuş oyunu yeniden başlatmalı")
	# İngilizce oyun sonu kartı
	Ceviri.zorla = "en"
	Ceviri.dil_uygula()
	oyun.baslangic_x -= 400.0 * Ayarlar.PIKSEL_METRE
	oyun.oyuncu.ol()
	await _kareler(3)
	dogrula(oyun.get_node("%SonSkor").text.begins_with("Distance: 4") and oyun.get_node("%SonRekor").text == "NEW RECORD!", "İngilizce oyun sonu kartı (%s / %s)" % [oyun.get_node("%SonSkor").text, oyun.get_node("%SonRekor").text])
	dogrula(tr(oyun.get_node("%SonBaslik").text) == "RUN OVER" and tr((oyun.get_node("%TekrarDugme") as Button).text) == "Retry", "İngilizce kart başlığı ve düğmesi")
	Ceviri.zorla = "tr"
	Ceviri.dil_uygula()
	oyun.queue_free()
	await process_frame
	_kayit_temizle()


func _test_ilk_oyun_ogretme() -> void:
	print("[ilk oyunda öğretme]")
	_kayit_temizle()
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.kayit_yap = false
	oyun.olum_tekrari_acik = false
	oyun.tohum = 2
	root.add_child(oyun)
	await _kareler(10)
	dogrula(oyun.ipucu.visible and oyun.ipucu.text == "Zıpla: Boşluk ya da dokun", "ilk oyunda 1. adım: zıpla (%s)" % oyun.ipucu.text)
	oyun.oyuncu.zipla_bas()
	await _kareler(4)
	dogrula(oyun.ipucu.text.contains("Basılı tut"), "zıpladıktan sonra 2. adım: basılı tut + havada bir kez daha (%s)" % oyun.ipucu.text)
	oyun.oyuncu.zipla_birak()
	await _kareler(60 * 4)
	dogrula(oyun.ipucu.text == "" or not oyun.ipucu.visible, "2. adım birkaç saniye sonra kapanır (%s)" % oyun.ipucu.text)
	oyun.queue_free()
	await process_frame
	# Tavan yaklaşınca 3. adım
	var sira: Array[String] = ["res://scenes/parcalar/01_duz.tscn", "res://scenes/parcalar/16_alcak_gecit.tscn"]
	var o2: Node2D = (load(OYUN) as PackedScene).instantiate()
	o2.kayit_yap = false
	o2.olum_tekrari_acik = false
	o2.parca_sirasi = sira
	o2.sabit_hiz = 220.0
	root.add_child(o2)
	await _kareler(5)
	o2.oyuncu.olumsuz = true
	o2.oyuncu.zipla_bas()
	await _kareler(30)
	var gordu := false
	for i in 60 * 20:
		await physics_frame
		if o2.ipucu.text.contains("KISA"):
			gordu = true
			break
	dogrula(gordu, "alçak tavan yaklaşınca 3. adım: kısa dokun")
	o2.queue_free()
	await process_frame
	# İkinci oyundan itibaren yalnız 4 sn'lik tek satır
	var kd := Kayit.yukle()
	kd["kosu_sayisi"] = 3
	Kayit.kaydet(kd)
	var o3: Node2D = (load(OYUN) as PackedScene).instantiate()
	o3.kayit_yap = false
	o3.tohum = 2
	root.add_child(o3)
	await _kareler(10)
	dogrula(o3.ipucu.visible and not o3._ogretme_ilk, "sonraki oyunlarda kısa ipucu var, öğretme dizisi yok")
	await _kareler(60 * 5)
	dogrula(not o3.ipucu.visible, "sonraki oyunlarda ipucu 4 sn sonra gizlenir")
	o3.queue_free()
	await process_frame
	_kayit_temizle()


## Oyun hissi (tools/his_olc.gd ile aynı ölçüm, headless): kojot ve tampon pencereleri.
func _test_his_pencereleri() -> void:
	print("[oyun hissi: kojot ve tampon]")
	var kare_ms := 1000.0 / 60.0
	dogrula(is_equal_approx(Ayarlar.KOJOT_SURESI, 0.08) and is_equal_approx(Ayarlar.ZIPLAMA_TAMPONU, 0.12), "kojot 80 ms, tampon 120 ms (ritim penceresi bu değerlerle ölçüldü)")
	var enbuyuk := -1
	for k in range(0, 12):
		var dunya := Node2D.new()
		root.add_child(dunya)
		var z := Zemin.new()
		z.position = Vector2(0, Ayarlar.ZEMIN_Y)
		z.genislik = 300.0
		z.yukseklik = 120.0
		dunya.add_child(z)
		var o: Oyuncu = (load("res://scenes/oyuncu.tscn") as PackedScene).instantiate()
		o.iz_acik = false
		dunya.add_child(o)
		o.sifirla(Vector2(240.0, Ayarlar.ZEMIN_Y))
		o.hiz = 300.0
		o.olumsuz = true
		var havada := -1
		for kare in 200:
			await physics_frame
			if not o.is_on_floor() and havada < 0:
				havada = 0
			elif havada >= 0:
				havada += 1
			if havada == k:
				o.zipla_bas()
				await physics_frame
				if o.velocity.y < (Ayarlar.ZIPLAMA_HIZI + Ayarlar.IKINCI_ZIPLAMA_HIZI) / 2.0:
					enbuyuk = k
				break
		dunya.queue_free()
		await physics_frame
	var pencere_ms := (enbuyuk + 1) * kare_ms
	dogrula(pencere_ms >= 67.0 and pencere_ms <= 100.0, "kenardan sonra tam güç zıplama penceresi ≈ 83 ms (ölçülen %.0f ms, %d kare)" % [pencere_ms, enbuyuk + 1])
	# Kojot dışında (kenardan çok sonra) basış zayıf ikinci zıplamaya döner: yine de zıplar
	dogrula(enbuyuk < 11, "kojot penceresi sonsuz değil")


# ------------------------------------------------------------------ günlük video imkanları
## Renk akışı paleti (okunurluk >= 4,5:1), geçiş aileleri (shader), tekrarsız seçim, sade geçiş,
## menü açılışı, dil glitch'i, duraklat perdesi, ölüm flaşı, mesafe rozeti, rekor damgası, ritimde
## fizik etkilenmez.
func _test_video_gecisleri() -> void:
	print("[gunluk video gecisleri ve renk akisi]")
	_kayit_temizle()
	GecisKatmani.hizli = false
	GecisKatmani.sade_ayar = false
	var g: GecisKatmani = root.get_node("Gecis")
	# --- palet: her vurgu üstünde yazı >= 4,5:1 (kodla seçilir) ---
	var en_dusuk := 99.0
	var kaynaklar := {}
	for t in Tema.AKIS.size():
		var a: Dictionary = Tema.AKIS[t]
		kaynaklar[a["kaynak"]] = true
		dogrula(a["vurgu"].size() >= 5 and String(a["kaynak"]) != "", "palet %d akış renkleri (%s, %d renk)" % [t, a["kaynak"], a["vurgu"].size()])
		dogrula(a["vurgu"][0] in [Tema.PEMBE, Tema.SARI, Tema.MOR], "palet %d oyunun kendi rengiyle başlıyor" % t)
		for v in a["vurgu"]:
			en_dusuk = minf(en_dusuk, Tema.kontrast(v, Tema.yazi_rengi(v, t)))
		dogrula(Tema.kontrast(a["acik"], a["koyu"]) >= 10.0, "palet %d açık/koyu yazı çifti" % t)
	dogrula(en_dusuk >= Tema.ESIK, "akış renkleri üzerinde yazı en az %.1f:1 (en düşük %.2f)" % [Tema.ESIK, en_dusuk])
	dogrula(kaynaklar.size() == 3, "üç ayrı video teması (neon, arcade, uzay)")
	dogrula(is_equal_approx(Tema.kontrast(Color.BLACK, Color.WHITE), 21.0), "kontrast hesabı: siyah/beyaz 21:1")
	dogrula(Tema.akis_rengi(0, 0).is_equal_approx(Tema.akis_rengi(0, 5)), "akış rengi sarmal döner")
	var dunya_sayisi: int = ((load("res://scripts/oyun.gd") as GDScript).get_script_constant_map()["TEMALAR"] as Array).size()
	dogrula(Tema.PALET_ESLEME.size() == dunya_sayisi and Tema.palet(-1) == 0 and Tema.palet(99) == Tema.PALET_ESLEME[-1], "her dünya teması bir palete eşli, sınır dışı güvenli (%d dünya)" % dunya_sayisi)
	for i in Tema.PALET_ESLEME.size():
		dogrula(Tema.PALET_ESLEME[i] >= 0 and Tema.PALET_ESLEME[i] < Tema.AKIS.size(), "dünya teması %d geçerli palete gidiyor" % i)
	# --- aileler shader'da, havuzlar geçerli, art arda tekrar yok, sekiz ailenin hepsi kullanılıyor ---
	var shader_ad: Array = []
	for u in GecisKatmani.SHADER.get_shader_uniform_list():
		shader_ad.append(String(u["name"]))
	dogrula("tur" in shader_ad and "p" in shader_ad and "renk" in shader_ad and "renk2" in shader_ad and "oran" in shader_ad, "geçiş shader'ı uniform'ları var")
	dogrula(Tema.GECIS_TURLERI.size() == 8, "sekiz geçiş ailesi")
	var birlesim := {}
	for t in Tema.AKIS.size():
		var havuz: Array = Tema.AKIS[t]["gecis"]
		var hepsi := true
		for f in havuz:
			hepsi = hepsi and f in Tema.GECIS_TURLERI
			birlesim[f] = true
		dogrula(hepsi and havuz.size() >= 4, "palet %d geçiş havuzu shader ailesinden (%s)" % [t, havuz])
		var onceki: StringName = &""
		var tekrar := 0
		var disari := 0
		var gorulen := {}
		for i in 40:
			var f: StringName = g.sec(t)
			if f == onceki:
				tekrar += 1
			if not f in havuz:
				disari += 1
			gorulen[f] = true
			onceki = f
			g.son_tur = f
		dogrula(tekrar == 0 and disari == 0 and gorulen.size() == havuz.size(), "palet %d: 40 seçimde tekrar yok, hepsi havuzda, hepsi kullanıldı" % t)
	dogrula(birlesim.size() == Tema.GECIS_TURLERI.size(), "havuzların birleşimi sekiz ailenin hepsi (%d)" % birlesim.size())
	# --- her aile örtüyor ve açılıyor ---
	for f in Tema.GECIS_TURLERI:
		await g.kapat(f, 0, 0.05)
		var p: float = g._mat.get_shader_parameter("p")
		dogrula(g._kaplama.visible and is_equal_approx(p, 1.0) and g.son_tur == f, "%s: tam örtüyor (p=%.2f)" % [f, p])
		await g.ac(0.05)
		dogrula(not g._kaplama.visible, "%s: açılıyor, kaplama gizli" % f)
	# --- renk: flaş açık, kararma koyu, özel renk ---
	await g.kapat(&"flas", 1, 0.05)
	dogrula((g._mat.get_shader_parameter("renk") as Color).is_equal_approx(Tema.KAGIT), "flaş rengi paletin açığı (kâğıt)")
	await g.ac(0.05)
	await g.kapat(&"kararma", 2, 0.05)
	dogrula((g._mat.get_shader_parameter("renk") as Color).is_equal_approx(Tema.MUREKKEP), "kararma rengi paletin koyusu (mürekkep)")
	await g.ac(0.05)
	await g.acilis(&"flas", 0, 0.05, 0.3, Tema.PEMBE)
	dogrula(g.son_tur == &"flas" and not g._kaplama.visible, "acilis(): özel renkli flaş oynadı ve kapandı")
	# --- süre: örtme ~260 ms ---
	var kare_n := 0
	g.kapat(&"itme", 1)
	while not is_equal_approx(float(g._mat.get_shader_parameter("p")), 1.0) and kare_n < 200:
		await process_frame
		kare_n += 1
	var ms := kare_n * 1000.0 / 60.0            # --fixed-fps 60: süre kare sayısından
	dogrula(ms >= 220.0 and ms < 500.0, "örtme %.0f ms (%d kare; rehber ~260)" % [ms, kare_n])
	await g.ac()
	# --- ara(): değişim örtünün altında, sonra kapanır; ikinci çağrı bantta yok sayılır ---
	var cagri := [0]
	g.ara(&"bloklar", 1, func() -> void: cagri[0] += 1)
	g.ara(&"bloklar", 1, func() -> void: cagri[0] += 100)
	await create_timer(0.8).timeout
	dogrula(cagri[0] == 1 and not g.mesgul_mu() and not g._kaplama.visible, "ara(): değiştir bir kez çağrıldı (%d), geçiş bitti" % cagri[0])
	# --- git(): sahne değişmeden oynar (test kipi), çift tık yok sayılır ---
	var sahne_once := current_scene
	g.git("res://scenes/menu.tscn", 2)
	dogrula(g.mesgul_mu(), "git(): geçiş sürerken meşgul")
	g.git("res://scenes/oyun.tscn", 2)
	await create_timer(0.9).timeout
	dogrula(not g.mesgul_mu() and not g._kaplama.visible and current_scene == sahne_once, "git(): bant oynadı, sahne değişmedi (test kipi)")
	# --- meşgulken acilis() yok sayılır (sahne geçişini bozmasın) ---
	g._mesgul = true
	await g.acilis(&"iris", 0, 0.05)
	dogrula(not g._kaplama.visible, "meşgulken acilis() yok sayılır")
	g._mesgul = false
	# --- hareket azaltma: anında, bekleme yok (test kipi, ayar ve tarayıcı aynı yol) ---
	for kip in ["ayar", "test"]:
		GecisKatmani.sade_ayar = kip == "ayar"
		GecisKatmani.hizli = kip == "test"
		dogrula(g.sade(), "sade kip (%s): sade() doğru" % kip)
		var ilk_kare := Engine.get_process_frames()
		await g.kapat(&"iris", 0)
		await g.ara(&"bloklar", 1, func() -> void: cagri[0] += 1)
		await g.acilis(&"perde", 2)
		dogrula(Engine.get_process_frames() - ilk_kare <= 1 and not g._kaplama.visible, "sade kip (%s): geçiş anında, kaplama hiç açılmadı (%d kare)" % [kip, Engine.get_process_frames() - ilk_kare])
	dogrula(cagri[0] == 3, "sade kipte ara() değişikliği yine yaptı")
	GecisKatmani.sade_ayar = false
	GecisKatmani.hizli = false
	# --- ayar: kayıt varsayılanı kapalı, menü anahtarı sade_gecis'i yazar ve katmana bildirir ---
	dogrula(Kayit.VARSAYILAN["ayarlar"].has("sade_gecis") and not bool(Kayit.VARSAYILAN["ayarlar"]["sade_gecis"]), "kayıt varsayılanı: sade geçiş kapalı")
	g.acilis_yapildi = true
	var menu: Control = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _kareler(3)
	var kutu: Button = menu.get_node("%SadeGecisKutu")
	dogrula(kutu != null and not kutu.button_pressed and tr(kutu.text) == "Sade geçişler (hareket azaltma)", "ayarlar: Sade geçişler anahtarı var, kapalı başlar")
	kutu.button_pressed = true
	await _kareler(2)
	dogrula(bool(Kayit.yukle()["ayarlar"]["sade_gecis"]) and GecisKatmani.sade_ayar and g.sade(), "anahtar kayda yazıldı ve geçişi sadeleştirdi")
	kutu.button_pressed = false
	await _kareler(2)
	dogrula(not bool(Kayit.yukle()["ayarlar"]["sade_gecis"]) and not g.sade(), "anahtar kapanınca geçişler geri geldi")
	# --- menü dil düğmesi: glitch örtüsünün altında dil değişir ---
	g.son_tur = &""
	var dd: Button = menu.get_node("%DilDugme")
	dd.pressed.emit()
	await _kareler(2)
	dogrula(g.son_tur == &"glitch" and g._kaplama.visible, "menü dil değişimi: glitch örtüsü başladı")
	await create_timer(0.7).timeout
	dogrula(dd.text == "EN" and not g._kaplama.visible and not g.mesgul_mu(), "glitch bitti, dil İngilizce, kaplama kapandı")
	dd.pressed.emit()
	await create_timer(0.7).timeout
	dogrula(dd.text == "TR", "dil geri Türkçe")
	menu.queue_free()
	await process_frame
	# --- menü açılışı: ilk açılışta iris, sonrasında yok ---
	g.acilis_yapildi = false
	g.son_tur = &""
	menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _kareler(3)
	dogrula(g.son_tur == &"iris" and g._kaplama.visible and g.acilis_yapildi, "menü ilk açılışta iris ile açılıyor")
	await create_timer(0.7).timeout
	dogrula(not g._kaplama.visible, "menü açılış iris'i bitti")
	menu.queue_free()
	await process_frame
	g.son_tur = &""
	menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _kareler(3)
	dogrula(g.son_tur == &"" and not g._kaplama.visible, "ikinci menü açılışında iris tekrarlanmıyor")
	menu.queue_free()
	await process_frame
	# --- oyun: mesafe rozeti, damga, flaş, duraklat, oyun sonu, dil ---
	var d := Kayit.yukle()
	d["rekor"] = 10
	Kayit.kaydet(d)
	var oyun: Node2D = (load(OYUN) as PackedScene).instantiate()
	oyun.kayit_yap = false
	oyun.olum_tekrari_acik = false
	oyun.tohum = 5
	root.add_child(oyun)
	await _kareler(4)
	oyun.oyuncu.olumsuz = true
	dogrula(g.son_tur == &"kararma", "koşu başı: kararma ailesiyle açılıyor")
	# Mesafe rozeti: 100 m'de paletin renk akışı, yazı okunur, sonunda şeffaf + eski yazı rengi
	oyun._rekor_asildi = true                    # rozet sınaması rekor damgasına karışmasın
	var yazi0: Color = oyun._rozet_yazi
	oyun._mesafe_vurgusu(99)
	dogrula(oyun._rozet_kalan <= 0.0 and oyun._rozet.bg_color.a == 0.0, "99 m: rozet vurgulanmıyor")
	oyun._mesafe_vurgusu(100)
	dogrula(oyun._rozet_kalan > 0.0, "100 m: rozet akışı başladı")
	await create_timer(0.25).timeout
	var v: Color = oyun._rozet.bg_color
	var yz: Color = oyun.mesafe_etiketi.get_theme_color("font_color")
	dogrula(v.a == 1.0 and Tema.kontrast(v, yz) >= Tema.ESIK, "rozet rengi paletten, yazısı %.2f:1" % Tema.kontrast(v, yz))
	var farkli := {}
	for i in 5:
		farkli[oyun._rozet.bg_color.to_html()] = true
		await create_timer(0.1).timeout
	dogrula(farkli.size() >= 2, "rozet rengi akıyor (%d ayrı renk)" % farkli.size())
	await create_timer(0.3).timeout
	dogrula(oyun._rozet.bg_color.a == 0.0 and oyun.mesafe_etiketi.get_theme_color("font_color").is_equal_approx(yazi0), "akış bitti: rozet şeffaf, yazı eski renkte")
	oyun._mesafe_vurgusu(150)
	dogrula(oyun._rozet_kalan <= 0.0, "aynı yüz metrede ikinci tetik yok")
	oyun._mesafe_vurgusu(200)
	dogrula(oyun._rozet_kalan > 0.0, "200 m: rozet yine akıyor")
	GecisKatmani.sade_ayar = true
	oyun._rozet_sifirla()
	oyun._mesafe_vurgusu(300)
	dogrula(oyun._rozet_kalan <= 0.0, "sade geçişte rozet akışı kapalı")
	GecisKatmani.sade_ayar = false
	# Rekor anı: rekor (10 m) aşılınca bir kez damga + flaş
	oyun._rekor_asildi = false
	oyun._damga_hud.gizle()
	g.son_tur = &""
	oyun._mesafe_vurgusu(10)
	dogrula(not oyun._damga_hud.visible, "rekora eşitken damga yok")
	oyun._mesafe_vurgusu(11)
	dogrula(oyun._damga_hud.visible and oyun._damga_hud.yazi.text == "YENİ REKOR!", "rekor aşıldı: damga (%s)" % oyun._damga_hud.yazi.text)
	dogrula(g.son_tur == &"flas", "rekor aşıldı: flaş vuruşu")
	var dv: Color = oyun._damga_hud.rengi()
	dogrula(Tema.kontrast(dv, oyun._damga_hud.yazi.get_theme_color("font_color")) >= Tema.ESIK, "damga yazısı okunuyor (%.2f:1)" % Tema.kontrast(dv, oyun._damga_hud.yazi.get_theme_color("font_color")))
	var ekran: Rect2 = oyun.get_viewport().get_visible_rect()
	dogrula(ekran.encloses(Rect2(oyun._damga_hud.position, oyun._damga_hud.size)), "damga ekrana sığıyor")
	g.son_tur = &""
	oyun._mesafe_vurgusu(12)
	dogrula(g.son_tur == &"", "damga ve flaş bir koşuda bir kez")
	await create_timer(0.9).timeout
	dogrula(oyun._damga_hud.rengi().is_equal_approx(Tema.akis_rengi(oyun._palet(), 0)), "damga renk akışından sonra ilk renkte durdu")
	await create_timer(1.1).timeout
	dogrula(not oyun._damga_hud.visible, "damga 1,8 sn sonra kayboldu")
	# Ölüm flaşı: pembe, yalnız sarsıntı ayarı açıkken
	g.son_tur = &""
	oyun.sarsinti_acik = false
	oyun._flas()
	dogrula(g.son_tur == &"", "sarsıntı kapalı: ölüm flaşı yok")
	oyun.sarsinti_acik = true
	oyun._flas()
	dogrula(g.son_tur == &"flas" and (g._mat.get_shader_parameter("renk") as Color).is_equal_approx(Tema.PEMBE), "ölüm flaşı pembe (oyuncu rengi)")
	await create_timer(0.3).timeout
	# Duraklat: perde açılır, oyun durmuşken de çalışır
	oyun.duraklat()
	dogrula(paused and g._kaplama.visible and g.son_tur == &"perde", "duraklat: perde geçişi başladı")
	await create_timer(0.45).timeout
	dogrula(not g._kaplama.visible, "duraklat: perde açıldı (oyun durmuşken de çalışıyor)")
	# Duraklattaki dil düğmesi: glitch
	oyun._dil_degistir()
	await create_timer(0.1).timeout
	dogrula(g.son_tur == &"glitch", "duraklatta dil değişimi glitch ile")
	await create_timer(0.7).timeout
	dogrula(Ceviri.dil_kodu() == "en" and not g.mesgul_mu(), "duraklatta dil İngilizceye döndü")
	oyun._dil_degistir()
	await create_timer(0.7).timeout
	dogrula(Ceviri.dil_kodu() == "tr", "duraklatta dil geri Türkçe")
	oyun.devam()
	# Oyun sonu: kart palet ailesiyle açılır; rekorda köşe damgası
	oyun.baslangic_x -= 150.0 * Ayarlar.PIKSEL_METRE
	oyun.oyuncu.olumsuz = false
	g.son_tur = &""
	oyun.oyuncu.ol()
	await _kareler(3)
	dogrula(oyun.son_paneli.visible and g.son_tur in Tema.AKIS[oyun._palet()]["gecis"], "oyun sonu: kart palet havuzundan bir aileyle açılıyor (%s)" % g.son_tur)
	dogrula(oyun._damga_son.visible and oyun._damga_son.yazi.text == "YENİ REKOR!", "oyun sonu: rekorda köşe damgası")
	var kart: Rect2 = oyun.son_paneli.get_global_rect()
	dogrula(kart.grow(20).encloses(Rect2(oyun._damga_son.position, oyun._damga_son.size)) and oyun._damga_son.position.y < kart.position.y + 4.0, "damga kartın üst köşesinde")
	await create_timer(0.6).timeout
	dogrula(not g._kaplama.visible, "oyun sonu geçişi bitti")
	oyun._yeniden_baslat_izni = 0.0
	oyun.yeniden_baslat()
	await _kareler(2)
	dogrula(not oyun._damga_son.visible and not oyun.son_paneli.visible, "yeniden başlayınca damga kalkıyor")
	oyun.baslangic_x -= 2.0 * Ayarlar.PIKSEL_METRE
	oyun.oyuncu.ol()
	await _kareler(3)
	dogrula(oyun.son_paneli.visible and not oyun._damga_son.visible, "rekor yoksa köşe damgası yok")
	oyun.queue_free()
	await create_timer(0.7).timeout
	# --- ritim: geçiş katmanı fiziği ve vuruş ızgarasını etkilemez ---
	var rit: Node2D = (load(OYUN) as PackedScene).instantiate()
	rit.kayit_yap = false
	rit.olum_tekrari_acik = false
	rit.bot_modu = true
	rit.ritim = true
	rit.tohum = 3
	root.add_child(rit)
	await _kareler(3)
	var izgara := float(rit._izgara0)
	g.acilis(&"zoom", 0, 0.5)
	await _kareler(10)
	dogrula(g._kaplama.visible, "ritim: geçiş oynarken koşu sürüyor")
	await _kareler(300)
	dogrula(not rit.bitti and float(rit._izgara0) == izgara, "ritim: geçiş katmanı vuruş ızgarasını ve koşuyu bozmadı")
	dogrula(rit._damga_hud != null and not rit._damga_hud.visible, "ritimde koşarken damga yok (rekor 0)")
	rit.queue_free()
	await create_timer(0.6).timeout
	GecisKatmani.hizli = true
	GecisKatmani.sade_ayar = false
	paused = false
	Ceviri.zorla = "tr"
	Ceviri.dil_uygula()
	_kayit_temizle()


class YakinDinleyici extends Node:
	var sayi := 0

	func yakin_kacis(_t: Node2D) -> void:
		sayi += 1

	func altin_toplandi(_k: Vector2 = Vector2.INF) -> void:
		pass
