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
