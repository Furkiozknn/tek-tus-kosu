#!/usr/bin/env python3
"""Web yapisi icin duman testi: dışa aktarılmış oyun tarayıcıda gerçekten açılıyor mu?

    python3 tools/web_duman.py build/web [--cikti build/duman] [--chromium /yol/chrome]

Birim testleri (tests/testler.gd) motorun içinde koşar; web kabuğunu
(`yayin/web-kabuk.html`), .pck yüklemeyi, WebGL 2'yi ve tarayıcıdaki girdiyi
hiç görmez. Bu betik Yapi iş akışında dışa aktarmadan hemen sonra koşar, yani
Pages'e yayın bu testten geçmeyen bir pakete hiç ulaşmaz.

Adımlar:
  1. build/web yerel bir HTTP sunucusuyla sunulur (dosyadan açmak Godot'da çalışmaz).
  2. Headless Chromium (WebGL 2, SwiftShader) sayfayı açar.
  3. Yükleme perdesi (#status) kalkana kadar beklenir; #status-notice'te
     hata çıkarsa ya da süre dolarsa düşer.
  4. Menünün ekran görüntüsü alınır, Boşluk'a basılır (menüde "başla", koşuda
     "zıpla"), birkaç saniye koşulur, ikinci ekran görüntüsü alınır.
  5. Düşme koşulları: sayfa hatası (pageerror), konsolda SCRIPT ERROR /
     Parse Error, tek renkli (boş) kare, ya da menü ile koşu karesinin aynı
     olması (oyun donmuş ya da girdi ulaşmıyor).

Gereken: `pip install playwright pillow` (Yapi iş akışı 1.63.0 / 12.3.0 sabitliyor) ve `python -m playwright install chromium`.
"""
from __future__ import annotations

import argparse
import functools
import http.server
import io
import sys
import threading
import time
from pathlib import Path

from PIL import Image
from playwright.sync_api import sync_playwright

YUKLEME_SN = 120      # SwiftShader yavaş; ~10 MB paket + WASM derlemesi
KOSU_SN = 6
EN_AZ_RENK = 16       # tek renkli ya da boş tuval bunun çok altında kalır
HATA_IZLERI = ("SCRIPT ERROR", "Parse Error")


class SessizIsleyici(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args) -> None:  # noqa: D401 - gürültüyü kapat
        pass


def sunucu_baslat(kok: Path) -> http.server.ThreadingHTTPServer:
    isleyici = functools.partial(SessizIsleyici, directory=str(kok))
    sunucu = http.server.ThreadingHTTPServer(("127.0.0.1", 0), isleyici)
    threading.Thread(target=sunucu.serve_forever, daemon=True).start()
    return sunucu


def renk_sayisi(png: bytes) -> int:
    img = Image.open(io.BytesIO(png)).convert("RGB").resize((320, 180))
    return len(img.getcolors(maxcolors=320 * 180) or [])


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("web_klasoru", type=Path)
    ap.add_argument("--cikti", type=Path, default=Path("build/duman"))
    ap.add_argument("--chromium", help="Playwright'ın kendi Chromium'u yerine bu çalıştırılabilir")
    a = ap.parse_args()

    index = a.web_klasoru / "index.html"
    if not index.is_file():
        print(f"DUMAN: {index} yok; önce Web dışa aktarması gerekir.", file=sys.stderr)
        return 1
    a.cikti.mkdir(parents=True, exist_ok=True)

    sunucu = sunucu_baslat(a.web_klasoru)
    adres = f"http://127.0.0.1:{sunucu.server_address[1]}/index.html"
    hatalar: list[str] = []
    konsol: list[str] = []

    with sync_playwright() as p:
        tarayici = p.chromium.launch(
            executable_path=a.chromium,
            args=["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--autoplay-policy=no-user-gesture-required"],
        )
        sayfa = tarayici.new_page(viewport={"width": 1280, "height": 720})
        sayfa.on("pageerror", lambda e: hatalar.append(f"pageerror: {e}"))

        def konsol_dinle(m) -> None:
            satir = f"[{m.type}] {m.text}"
            konsol.append(satir)
            if any(iz in m.text for iz in HATA_IZLERI):
                hatalar.append(satir)

        sayfa.on("console", konsol_dinle)

        t0 = time.monotonic()
        sayfa.goto(adres)
        # Perde kalkınca başarı; kabuk #status-notice'e hata yazarsa beklemeden düş.
        try:
            sayfa.wait_for_function(
                "() => !document.getElementById('status')"
                " || (document.getElementById('status-notice')?.textContent || '').trim() !== ''",
                timeout=YUKLEME_SN * 1000,
            )
        except Exception:  # noqa: BLE001 - nedeni aşağıda yazılıyor
            pass
        if sayfa.locator("#status").count():
            bildirim = sayfa.locator("#status-notice")
            metin = bildirim.inner_text() if bildirim.count() else ""
            sayfa.screenshot(path=str(a.cikti / "duman-yukleme.png"))
            hatalar.append(f"yükleme perdesi kalkmadı ({YUKLEME_SN} sn sınır); bildirim: {metin!r}")
        yukleme = time.monotonic() - t0

        menu = kosu = b""
        if not hatalar:
            sayfa.wait_for_timeout(2000)
            menu = sayfa.screenshot(path=str(a.cikti / "duman-menu.png"))
            sayfa.keyboard.press("Space")
            for _ in range(KOSU_SN * 2):
                sayfa.wait_for_timeout(500)
                sayfa.keyboard.press("Space")
            kosu = sayfa.screenshot(path=str(a.cikti / "duman-kosu.png"))
        tarayici.close()
    sunucu.shutdown()

    (a.cikti / "konsol.txt").write_text("\n".join(konsol) + "\n", encoding="utf-8")
    print(f"DUMAN: yükleme {yukleme:.1f} sn; konsol {len(konsol)} satır ({a.cikti / 'konsol.txt'})")

    if menu and kosu:
        rm, rk = renk_sayisi(menu), renk_sayisi(kosu)
        print(f"DUMAN: menü {rm} renk, koşu {rk} renk")
        if rm < EN_AZ_RENK or rk < EN_AZ_RENK:
            hatalar.append(f"boş ya da tek renkli kare (menü {rm}, koşu {rk} renk)")
        if menu == kosu:
            hatalar.append("Boşluk'tan sonra kare değişmedi: oyun donmuş ya da girdi ulaşmıyor")

    if hatalar:
        for h in hatalar:
            print(f"DUMAN HATA: {h}", file=sys.stderr)
        return 1
    print("DUMAN: tamam: yükleme ekranı kalktı, menü çizildi, Boşluk ile koşu başladı, betik hatası yok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
