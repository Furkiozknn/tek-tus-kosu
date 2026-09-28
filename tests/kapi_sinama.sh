#!/usr/bin/env bash
# tests/kapi.sh'in kendi sinamasi. Godot gerektirmez; CI'da her push'ta kosar.
# Gunluk ornekleri gercek CI ciktisinin bicimini izler (22 Eylul 2026, 961 test).
set -uo pipefail

kok="$(cd "$(dirname "$0")" && pwd)"
kapi="$kok/kapi.sh"
gecici="$(mktemp -d)"
trap 'rm -rf "$gecici"' EXIT
basarisiz=0

# $1 ad, $2 beklenen cikis (0 gecer / 1 duser), $3 taban, stdin gunluk
bekle() {
  local ad="$1" beklenen="$2" taban="$3" dosya="$gecici/$1.log" kod
  cat >"$dosya"
  bash "$kapi" "$dosya" "$taban" >/dev/null 2>&1
  kod=$?
  if [ "$kod" -eq "$beklenen" ]; then
    echo "  tamam  $ad (cikis $kod)"
  else
    echo "  HATA   $ad: beklenen $beklenen, gelen $kod"
    basarisiz=$((basarisiz + 1))
  fi
}

echo "[test kapisi]"

bekle temiz 0 961 <<'EOF'
[ritim: her desen, her şarkının vuruş aralığında, kusursuz bot ile]

=== SONUÇ: 961 geçti, 0 hata ===
WARNING: 12 ObjectDB instances were leaked at exit (run with `--verbose` for details).
ERROR: 3 resources still in use at exit (run with --verbose for details).
EOF

bekle tabandan_fazla 0 961 <<'EOF'
=== SONUÇ: 975 geçti, 0 hata ===
EOF

bekle dogrulama_hatasi 1 961 <<'EOF'
  HATA: boş kayıt sıfır olmalı
=== SONUÇ: 960 geçti, 1 hata ===
EOF

# Asil kapattigi aciklik: bir bolum calisma zamani hatasiyla kesildi, kalan
# dogrulamalari sayilmadi, ama takim yine "0 hata" ile bitti.
bekle betik_hatasi_sessiz_atlama 1 961 <<'EOF'
[ritim koşusu]
SCRIPT ERROR: Invalid access to property or key 'olaylar' on a base object of type 'Nil'.
   at: parca_kur (res://scripts/ritim.gd:245)
=== SONUÇ: 912 geçti, 0 hata ===
EOF

bekle betik_hatasi_sayi_tam 1 961 <<'EOF'
SCRIPT ERROR: Invalid operands 'int' and 'bool' in operator '=='.
=== SONUÇ: 961 geçti, 0 hata ===
EOF

bekle derleme_hatasi 1 961 <<'EOF'
SCRIPT ERROR: Parse Error: Identifier "Ritim" not declared in the current scope.
EOF

bekle tabanin_alti 1 961 <<'EOF'
=== SONUÇ: 853 geçti, 0 hata ===
EOF

bekle sonuc_satiri_yok 1 961 <<'EOF'
[kayit]
[gorevler ve kostum]
EOF

bekle bos_gunluk 1 961 </dev/null

if [ "$basarisiz" -ne 0 ]; then
  echo "=== test kapisi: $basarisiz sinama basarisiz ==="
  exit 1
fi
echo "=== test kapisi: tum sinamalar gecti ==="
