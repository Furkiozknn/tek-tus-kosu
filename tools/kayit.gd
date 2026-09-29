extends Node
## Ham oynanış kaydı için bot koşusu (sosyal medya klibi): arayüz gizli, ekranda yazı yok.
## tools/kayit.ps1 bunu --write-movie ile çalıştırır. --fixed-fps 60 ile kare sayısı süreyi belirler.
##
## Bu bir BOT kaydıdır: tepki gecikmesi 0,04-0,12 sn'dir (insan bandı). Akış:
##   koşu -> (HATA_KARESI'nde) bilerek geç bir zıplama -> ölüm (pembe flaş + sarsıntı)
##   -> geçiş ailesi -> yeniden başlama -> koşu sürer -> SON_KARE'de çıkış.
## Geçiş çeşitliliği: her ARALIK karede bir, sırayla sekiz aile (Tema.GECIS_TURLERI: iris, glitch,
## bloklar, itme, flaş, perde, kararma, zoom) ve üç palet (neon / arcade / uzay) görünür.

const HATA_KARESI := 60 * 8        ## bu andan sonraki ilk engelde bilerek geç zıplanır
const SON_KARE := 60 * 18
const INSAN := Vector2(0.04, 0.12)
const HATA := Vector2(0.30, 0.34)

var _oyun: Node2D
var _bot: Bot
var _kare := 0
var _hatali := false
var _bitis_kare := -1
var _bant := false
var _gecis_i := 0
## Sekiz ailenin hepsi, palet dizinleriyle (docs/TASARIM.md §7).
const PLAN := [[&"iris", 0], [&"glitch", 0], [&"bloklar", 1], [&"itme", 1], [&"flas", 1], [&"perde", 2], [&"kararma", 2], [&"zoom", 0]]
const ARALIK := 130                ## kare: canlıyken geçişler bu aralıkla (2,2 sn)
const ILK := 100


func _ready() -> void:
	Kayit.yol = "user://kayit_video.cfg"
	var d := Kayit.yukle()
	d["rekor"] = 640
	d["kosu_sayisi"] = 5     # ilk oyun öğretme ipucu çıkmasın (arayüz zaten gizli)
	Kayit.kaydet(d)
	Ceviri.zorla = "tr"
	Ceviri.dil_uygula()
	_oyun = (load("res://scenes/oyun.tscn") as PackedScene).instantiate()
	_oyun.kayit_yap = false
	_oyun.olum_tekrari_acik = false
	_oyun.tohum = 12
	add_child(_oyun)
	_oyun.get_node("Arayuz").visible = false
	await get_tree().process_frame
	_bot_kur()


func _bot_kur() -> void:
	_bot = Bot.new(_oyun.oyuncu, _oyun.dunya_tehlike_araliklari, _oyun.dunya_tavan_araliklari)
	_bot.ruzgar = _oyun.ruzgar_gucu
	_bot.gecikme_aralik = INSAN
	_bot._rng.seed = 4


func _physics_process(_delta: float) -> void:
	if _bot == null:
		return
	_kare += 1
	if _kare >= SON_KARE:
		get_tree().quit()
		return
	if _oyun.bitti:
		if _bitis_kare < 0:
			_bitis_kare = _kare
		# Ölümden ~0,9 sn sonra sıradaki geçiş: örter, koşu yeniden kurulur, açılır
		if _kare - _bitis_kare == 54 and not _bant:
			_bant = true
			_gecis.call_deferred()
		return
	if _kare >= ILK and (_kare - ILK) % ARALIK == 0 and not _bant and _kare < SON_KARE - 40:
		_bant = true
		_gecis.call_deferred()
	if not _hatali and _kare >= HATA_KARESI:
		_hatali = true
		_bot.gecikme_aralik = HATA
	_bot.adim()


func _gecis() -> void:
	var g: GecisKatmani = get_tree().root.get_node("Gecis")
	var f: Array = PLAN[_gecis_i % PLAN.size()]
	_gecis_i += 1
	print("KAYIT gecis %d: %s palet %d kare %d" % [_gecis_i, f[0], f[1], _kare])
	await g.ara(f[0], f[1], func() -> void:
		_oyun.yeniden_baslat()
		_bot_kur()
		_bitis_kare = -1)
	_bant = false
