class_name Simgeler
extends RefCounted
## Varsayılan yazı tipinde (Open Sans) olmayan simgeler (★ ☆ ✓ ✗ ← ↑ → ↓ ■ □) için yedek yazı tipi.
## Masaüstünde sistem yazı tipleri bu eksiği örtüyor; web'de örtmüyordu (kutu görünüyordu).
## Menü ve oyun sahnesi açılışta çağırır; birden çok çağrı zararsızdır.

const YOL := "res://assets/fonts/simgeler.ttf"


static func kur() -> void:
	var ana := ThemeDB.fallback_font
	if ana == null or not ResourceLoader.exists(YOL):
		return
	var yedek: Font = load(YOL)
	if yedek == null or ana.fallbacks.has(yedek):
		return
	var liste := ana.fallbacks.duplicate()
	liste.append(yedek)
	ana.fallbacks = liste
