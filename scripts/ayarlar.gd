class_name Ayarlar
extends RefCounted
## Oyunun tüm ayar sabitleri tek yerde. Denge değişiklikleri buradan yapılır.

# --- Dünya ---
const ZEMIN_Y := 280.0          ## Normal zemin yüzeyinin y'si (piksel)
const ZEMIN_ALT_Y := 400.0      ## Zemin dikdörtgenlerinin alt kenarı
const OLUM_Y := 420.0           ## Bu y'nin altına düşen oyuncu ölür
const PIKSEL_METRE := 32.0      ## Mesafe puanı: 32 piksel = 1 metre
const OYUNCU_EKRAN_X := 160.0   ## Oyuncunun ekranda soldan konumu

# --- Oyuncu fiziği ---
const YERCEKIMI := 1400.0
const AZAMI_DUSUS := 900.0
const ZIPLAMA_HIZI := -520.0        ## İlk zıplama (tam basılı tutunca ~96 px yükseklik)
const IKINCI_ZIPLAMA_HIZI := -440.0 ## Havadaki ikinci zıplama
const KISA_ZIPLAMA_CARPANI := 0.6   ## Erken bırakınca yukarı hız bu oranla kesilir (dokunuş ≈ 35 px sıçrama)
const KOJOT_SURESI := 0.08          ## Kenardan düştükten sonra hâlâ zıplanabilen süre
const ZIPLAMA_TAMPONU := 0.12       ## Yere değmeden hemen önce basılan zıplama kabul süresi

# --- Hız ---
const HIZ_BAS := 220.0      ## Başlangıç koşu hızı (piksel/sn)
const HIZ_ARTIS := 4.0      ## Her saniye eklenen hız
const HIZ_AZAMI := 460.0    ## Hız üst sınırı
const RAHAT_MOD_CARPANI := 0.8  ## Rahat modda tüm hızlar bu oranla çarpılır (ayrı rekor)

# --- Parçalar ---
## Zorluk -> o zorluktaki parçaların çıkabileceği en düşük hız
const ZORLUK_ESIGI := {0: 0.0, 1: 0.0, 2: 280.0, 3: 360.0}
const PARCA_ONDEN_URET := 360.0 ## Ekranın sağ kenarından bu kadar ileriye kadar parça hazır olsun
const PARCA_ARKADA_SIL := 160.0 ## Ekranın sol kenarından bu kadar geride kalan parça silinir
const NEFES_ARALIGI := Vector2i(3, 8)  ## Bu kadar tehlikeli parçadan sonra bir "nefes" parçası gelir

# --- Tehlikeler ---
const PISTON_PERIYOT := 1.6     ## Yükselip inen dikenin bir tur süresi (sn)
const PISTON_ALCAK := 4.0       ## Piston inikken görünen yükseklik
const YAKIN_KACIS_PAYI := 14.0  ## Engelin bu kadar üstünden geçmek "kıl payı" sayılır
const YAKIN_KACIS_ODULU := 1    ## Kıl payı kaçış başına altın

# --- Görsel ---
const TEMA_ARALIGI_M := 500     ## Bu kadar metrede bir tema (ışık/hava) değişir
const SARSINTI_OLUM := 7.0
const OLUM_TEKRARI_KARE := 90   ## Ölüm tekrarında gösterilen son kare sayısı (1,5 sn)
const OLUM_TEKRARI_HIZ := 0.4   ## Ölüm tekrarının oynatma hızı

# --- v0.3 ---
const HAYALET_HZ := 20             ## Günlük koşu hayaletinin saniyedeki örnek sayısı
const HAYALET_SAYDAMLIK := 0.55
const OLUM_ISARETI_SAYISI := 12    ## Saklanan son ölüm mesafesi (mod başına)
const ISARET_EN_AZ_M := 30         ## Bundan kısa rekor/ölüm yeri için işaret konmaz
const BASARIM_ODULU := 25          ## Açılan her başarımın altın ödülü
const TITRESIM_OLUM_MS := 90


## Tam basılı zıplamanın havada kalma süresi (saniye)
static func tam_ziplama_suresi() -> float:
	return 2.0 * -ZIPLAMA_HIZI / YERCEKIMI


## Kısa (hemen bırakılmış) zıplamanın havada kalma süresi ve yüksekliği
static func kisa_ziplama_suresi() -> float:
	return 2.0 * -ZIPLAMA_HIZI * KISA_ZIPLAMA_CARPANI / YERCEKIMI


static func kisa_ziplama_yuksekligi() -> float:
	var v := -ZIPLAMA_HIZI * KISA_ZIPLAMA_CARPANI
	return v * v / (2.0 * YERCEKIMI)


## Sabit hız artışında (v = HIZ_BAS + HIZ_ARTIS * t) başlangıçtan d piksel sonraki hız.
## Parça seçimi bunu kullanır: böylece parça dizisi kare hızından bağımsız, tohumla belirlenir.
static func hiz_mesafede(d: float) -> float:
	var a := HIZ_ARTIS
	var b := HIZ_BAS
	var t_azami := (HIZ_AZAMI - b) / a
	var d_azami := b * t_azami + 0.5 * a * t_azami * t_azami
	if d >= d_azami:
		return HIZ_AZAMI
	var t := (-b + sqrt(b * b + 2.0 * a * maxf(d, 0.0))) / a
	return b + a * t


## Verilen zorluktaki parçanın çıkabilmesi için gereken en düşük hız
static func zorluk_esigi(zorluk: int) -> float:
	return float(ZORLUK_ESIGI.get(zorluk, 0.0))
