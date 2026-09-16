#!/usr/bin/env python3
"""Simge yedek yazı tipi üretici (Tek Tuş Koşu).

Godot'nun gömülü yazı tipi (Open Sans SemiBold) ★ ☆ ✓ ✗ ← ↑ → ↓ ■ □ karakterlerini içermiyor.
Masaüstünde sistem yazı tipleri bu eksiği örtüyor, web'de örtmüyor (kutu görünüyor).
Bu betik DejaVu Sans Bold'dan yalnız bu karakterleri alır ve yeniden adlandırır
(Bitstream Vera lisansı değiştirilmiş yazı tipinin yeniden adlandırılmasını ister).

    pip install fonttools
    python3 tools/simge_fontu.py [/yol/DejaVuSans-Bold.ttf]

Çıktı: assets/fonts/simgeler.ttf (+ lisans: assets/fonts/LISANS-simgeler.txt, elle tutulur).
Çıktı belirlenimcidir (zaman damgası kaynaktan kopyalanır).
"""
import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

KAYNAK = sys.argv[1] if len(sys.argv) > 1 else "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
CIKTI = Path(__file__).resolve().parent.parent / "assets" / "fonts" / "simgeler.ttf"
KARAKTERLER = "★☆✓✗←↑→↓■□"
AD = "TTK Simgeler"

font = TTFont(KAYNAK)
secenek = subset.Options()
secenek.hinting = False
secenek.desubroutinize = True
secenek.name_IDs = [0, 1, 2, 3, 4, 5, 6]
secenek.layout_features = []
secenek.notdef_outline = True
alt = subset.Subsetter(secenek)
alt.populate(unicodes=[ord(c) for c in KARAKTERLER])
alt.subset(font)

isimler = font["name"]
for kayit in list(isimler.names):
    if kayit.nameID in (1, 4):
        isimler.setName(AD, kayit.nameID, kayit.platformID, kayit.platEncID, kayit.langID)
    elif kayit.nameID == 3:
        isimler.setName(AD + " 1.0", kayit.nameID, kayit.platformID, kayit.platEncID, kayit.langID)
    elif kayit.nameID == 6:
        isimler.setName("TTKSimgeler-Bold", kayit.nameID, kayit.platformID, kayit.platEncID, kayit.langID)

CIKTI.parent.mkdir(parents=True, exist_ok=True)
font.save(str(CIKTI))
eksik = [c for c in KARAKTERLER if ord(c) not in font.getBestCmap()]
print(f"{CIKTI.name}: {CIKTI.stat().st_size} bayt, {len(KARAKTERLER) - len(eksik)} simge" + (f", EKSİK: {''.join(eksik)}" if eksik else ""))
