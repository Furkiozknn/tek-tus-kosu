class_name Tema
extends RefCounted
## Tanitim videosundaki dunya: DUZ renk, golgesiz, disi cizgisiz. Renkler
## tek-tus-kosu'nun KENDI videosundan (docs/TASARIM.md) piksel ornekleyerek alindi.
## Rol dagilimi: oyuncu PEMBE, tehlike SARI, altin CAMGOBEGI, arayuz birincil
## dugmesi MOR (videodaki "Tarayicida oyna" dugmesi), zemin cizgisi KAGIT.

const MUREKKEP := Color("120d1f")   ## panel / zemin blogu / kagit uzerindeki yazi
const GOK := Color("201b2d")        ## video gece gokyuzu
const SILUET := Color("2a2636")     ## video sehir siluetleri
const KAGIT := Color("f5edfe")      ## video acik yuzey / metin / zemin cizgisi
const PEMBE := Color("fd2c88")      ## oyuncu, vurgu, secili
const SARI := Color("ffc21a")       ## tehlike (dikenler, tabela, piston)
const CAM := Color("22e4ff")        ## altin, kil payi
const MOR := Color("b399ff")        ## birincil dugme (CTA)
const SARAP := Color("6b0017")      ## videodaki koyu sarap zemini
const PANEL := Color("1a1430")      ## kart / perde yuzeyi
const SOLUK := Color("8d84a6")      ## ikincil metin

## Oyun ici dunya temalari (oyun.gd TEMALAR bunlari kullanir).
const F_GOVDE := "res://assets/fonts/InstrumentSans-Regular.ttf"
const F_KALIN := "res://assets/fonts/InstrumentSans-Bold.ttf"
const F_MONO := "res://assets/fonts/JetBrainsMono-Regular.ttf"
const F_MONO_KALIN := "res://assets/fonts/JetBrainsMono-Bold.ttf"
const F_SIMGE := "res://assets/fonts/simgeler.ttf"
const TEMA_YOLU := "res://assets/tema.tres"


## Turkce duyarli buyuk harf: i -> İ, ı -> I. Ingilizcede duz to_upper.
static func buyuk(s: String) -> String:
	if TranslationServer.get_locale().begins_with("tr"):
		return s.replace("i", "İ").replace("ı", "I").to_upper()
	return s.to_upper()


static func etiket_rengi(renk: Color) -> Color:
	return Color(renk, 0.7)


## Duz dolgulu kutu (kart, rozet).
static func kutu(dolgu: Color, yaricap: int = 3, yatay: int = 0, dikey: int = 0,
		cerceve: Color = Color(0, 0, 0, 0), kalinlik: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = dolgu
	s.border_color = cerceve
	s.set_border_width_all(kalinlik)
	s.set_corner_radius_all(yaricap)
	s.content_margin_left = yatay
	s.content_margin_right = yatay
	s.content_margin_top = dikey
	s.content_margin_bottom = dikey
	s.anti_aliasing = true
	return s


## Etiket: mono ya da govde, boyut/renk burada, yazi tipi temada.
static func etiket(metin: String, boyut: int, renk: Color, mono := true, kalin := false) -> Label:
	var e := Label.new()
	e.text = metin
	if mono:
		e.theme_type_variation = &"EtiketKalin" if kalin else &"Etiket"
	else:
		e.theme_type_variation = &"Baslik" if kalin else &"Govde"
	e.add_theme_font_size_override("font_size", boyut)
	e.add_theme_color_override("font_color", renk)
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return e


## --- Günlük video imkânlarından alınan renk akışı ve geçiş aileleri ---
## Kaynak: sosyal/uret/tema.mjs TEMALAR (neon, arcade, uzay). Oyunun kendi videosundaki renkler
## (pembe / sarı / cam göbeği / mor / kâğıt) her paletin ilk sırasında; kaynak temanın yardımcı
## rengi yalnız sona eklendi. Dünya DÜZ kalır; akış yalnız geçişlerde, mesafe rozetinde ve
## rekor damgasında. Yazı rengi vurgunun üstünde kodla seçilir (en az ESIK).
const GECIS_TURLERI: Array[StringName] = [&"iris", &"glitch", &"bloklar", &"itme", &"perde", &"flas", &"kararma", &"zoom"]
const ESIK := 4.5                  ## okunurluk alt sınırı (videoda 5:1, burada WCAG AA 4,5:1)
## Dünya teması (oyun.gd TEMALAR: Gece, Şarap, Yağış, Menekşe, Fırtına) -> palet dizini.
const PALET_ESLEME: Array[int] = [0, 1, 0, 2, 1]
const AKIS: Array = [
	{"kaynak": "neon", "acik": KAGIT, "koyu": MUREKKEP,
		"vurgu": [PEMBE, CAM, SARI, MOR, Color("3dffb0")],
		"gecis": [&"glitch", &"iris", &"zoom", &"bloklar"]},
	{"kaynak": "arcade", "acik": KAGIT, "koyu": MUREKKEP,
		"vurgu": [SARI, PEMBE, CAM, Color("b6ff3b"), Color("ff9f1c")],
		"gecis": [&"bloklar", &"flas", &"itme", &"glitch"]},
	{"kaynak": "uzay", "acik": KAGIT, "koyu": MUREKKEP,
		"vurgu": [MOR, Color("ffab40"), Color("7fe7ff"), PEMBE, Color("7dffc8")],
		"gecis": [&"iris", &"perde", &"kararma", &"zoom"]},
]


## Dünya temasına karşılık gelen palet dizini.
static func palet(dunya_tema: int) -> int:
	return PALET_ESLEME[clampi(dunya_tema, 0, PALET_ESLEME.size() - 1)]


## WCAG göreli parlaklık.
static func parlaklik(c: Color) -> float:
	var k: Array[float] = []
	for v in [c.r, c.g, c.b]:
		k.append(v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * k[0] + 0.7152 * k[1] + 0.0722 * k[2]


static func kontrast(a: Color, b: Color) -> float:
	var x := parlaklik(a)
	var y := parlaklik(b)
	return (maxf(x, y) + 0.05) / (minf(x, y) + 0.05)


## Vurgu rengi üzerindeki yazı: açık ya da koyu, hangisi daha okunuyorsa.
static func yazi_rengi(zemin: Color, pal: int) -> Color:
	var a: Dictionary = AKIS[clampi(pal, 0, AKIS.size() - 1)]
	return a["acik"] if kontrast(zemin, a["acik"]) >= kontrast(zemin, a["koyu"]) else a["koyu"]


## Akış paletinden k. renk (sarmal).
static func akis_rengi(pal: int, k: int) -> Color:
	var v: Array = AKIS[clampi(pal, 0, AKIS.size() - 1)]["vurgu"]
	return v[posmod(k, v.size())]
