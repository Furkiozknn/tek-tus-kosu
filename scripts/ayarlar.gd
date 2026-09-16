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

# --- Parçalar ---
## Zorluk -> o zorluktaki parçaların çıkabileceği en düşük hız
const ZORLUK_ESIGI := {1: 0.0, 2: 280.0, 3: 360.0}
const PARCA_ONDEN_URET := 360.0 ## Ekranın sağ kenarından bu kadar ileriye kadar parça hazır olsun
const PARCA_ARKADA_SIL := 160.0 ## Ekranın sol kenarından bu kadar geride kalan parça silinir


## Tam basılı zıplamanın havada kalma süresi (saniye)
static func tam_ziplama_suresi() -> float:
	return 2.0 * -ZIPLAMA_HIZI / YERCEKIMI


## Verilen hızda, parçanın çıkabilmesi için gereken en düşük hız
static func zorluk_esigi(zorluk: int) -> float:
	return float(ZORLUK_ESIGI.get(zorluk, 0.0))
