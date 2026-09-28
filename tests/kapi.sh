#!/usr/bin/env bash
# Test kapisi: testler.gd'nin cikis kodu tek basina yeterli bir sinyal degil.
#
#   tests/kapi.sh <test-gunlugu> <en-az-gecen>
#
# testler.gd yalnizca `hatalar > 0` ise 1 ile cikiyor. Oysa GDScript'te bir
# calisma zamani hatasi (null erisimi, int == bool, eksik metot) yalnizca o
# fonksiyonu keser: motor "SCRIPT ERROR" yazar, fonksiyonun kalan
# dogrulamalari hic sayilmaz ve takim yine "N gecti, 0 hata" ile 0 dondurur.
# Yani bir test bolumu sessizce yarida kalabilir ve CI yesil kalir.
#
# Bu betik gunlugu okuyup uc seyi zorunlu kilar:
#   1. "=== SONUÇ: N geçti, 0 hata ===" satiri var (takim sonuna kadar kostu),
#   2. N >= en-az-gecen (dogrulama sayisi bilinen tabanin altina dusmedi),
#   3. gunlukte "SCRIPT ERROR" / "Parse Error" yok.
# Motorun cikista yazdigi "ERROR: N resources still in use at exit" satiri
# test sonucuyla ilgili degil; onu bilerek aramiyoruz.
#
# Sinamasi: tests/kapi_sinama.sh (Godot gerektirmez).
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "kullanim: $0 <test-gunlugu> <en-az-gecen>" >&2
  exit 2
fi
gunluk="$1"
alt_sinir="$2"

if [ ! -r "$gunluk" ]; then
  echo "KAPI: gunluk okunamadi: $gunluk" >&2
  exit 1
fi

if grep -nE 'SCRIPT ERROR|Parse Error' "$gunluk" >&2; then
  echo "KAPI: gunlukte betik hatasi var (yukarida). Bir test bolumu yarida kesilmis olabilir." >&2
  exit 1
fi

sonuc="$(grep -aoE '=== SONUÇ: [0-9]+ geçti, [0-9]+ hata ===' "$gunluk" | tail -n 1 || true)"
if [ -z "$sonuc" ]; then
  echo "KAPI: '=== SONUÇ: ... ===' satiri yok; takim sonuna kadar kosmadi." >&2
  exit 1
fi

gecen="$(sed -E 's/^=== SONUÇ: ([0-9]+) geçti, ([0-9]+) hata ===$/\1/' <<<"$sonuc")"
hata="$(sed -E 's/^=== SONUÇ: ([0-9]+) geçti, ([0-9]+) hata ===$/\2/' <<<"$sonuc")"

if [ "$hata" -ne 0 ]; then
  echo "KAPI: $hata dogrulama basarisiz." >&2
  exit 1
fi
if [ "$gecen" -lt "$alt_sinir" ]; then
  echo "KAPI: $gecen dogrulama gecti, taban $alt_sinir. Bir bolum atlanmis ya da yarida kalmis." >&2
  exit 1
fi

echo "KAPI: $gecen gecti (taban $alt_sinir), 0 hata, betik hatasi yok."
