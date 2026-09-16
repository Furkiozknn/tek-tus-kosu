class_name ParcaListesi
extends RefCounted
## OTOMATİK ÜRETİLDİ: tools/sahne_uret.gd — elle düzenleme.

const DUZ := "res://scenes/parcalar/01_duz.tscn"

const YOLLAR: Array[String] = [
	"res://scenes/parcalar/01_duz.tscn",
	"res://scenes/parcalar/02_tek_diken.tscn",
	"res://scenes/parcalar/03_kucuk_cukur.tscn",
	"res://scenes/parcalar/04_iki_diken.tscn",
	"res://scenes/parcalar/05_basamak.tscn",
	"res://scenes/parcalar/06_blok.tscn",
	"res://scenes/parcalar/07_genis_cukur.tscn",
	"res://scenes/parcalar/08_platform.tscn",
	"res://scenes/parcalar/09_merdiven.tscn",
	"res://scenes/parcalar/10_diken_blok.tscn",
	"res://scenes/parcalar/11_buyuk_cukur.tscn",
	"res://scenes/parcalar/12_cukur_diken.tscn",
]

const ZORLUK := {
	"res://scenes/parcalar/01_duz.tscn": 1,
	"res://scenes/parcalar/02_tek_diken.tscn": 1,
	"res://scenes/parcalar/03_kucuk_cukur.tscn": 1,
	"res://scenes/parcalar/04_iki_diken.tscn": 1,
	"res://scenes/parcalar/05_basamak.tscn": 1,
	"res://scenes/parcalar/06_blok.tscn": 2,
	"res://scenes/parcalar/07_genis_cukur.tscn": 2,
	"res://scenes/parcalar/08_platform.tscn": 2,
	"res://scenes/parcalar/09_merdiven.tscn": 2,
	"res://scenes/parcalar/10_diken_blok.tscn": 3,
	"res://scenes/parcalar/11_buyuk_cukur.tscn": 3,
	"res://scenes/parcalar/12_cukur_diken.tscn": 3,
}
