# butler komutları (ÇALIŞTIRILMADI — Furki onayı gerekir)

itch.io kullanıcı adı ve oyun adresi henüz belli değil; `KULLANICI` yerine yazılacak.
Oyun sayfası itch.io panelinden önce elle oluşturulmalı (adres önerisi: `tek-tus-kosu`).

```powershell
# 1) butler kurulumu (bir kez): https://itch.io/docs/butler/installing.html
butler login

# 2) Dışa aktarma (proje kökünde)
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "Windows Desktop" build/windows/tek-tus-kosu.exe

# 3) Yükleme — kanal adları itch'in platform etiketlemesi için önemli
butler push build/web      KULLANICI/tek-tus-kosu:html5   --userversion 1.7.0
butler push build/windows  KULLANICI/tek-tus-kosu:windows --userversion 1.7.0

# 4) Durum
butler status KULLANICI/tek-tus-kosu
```

Notlar:
- `html5` kanalı yüklendikten sonra itch panelinde "This file will be played in the browser"
  işaretlenmeli; boyut 1280×720, "Mobile friendly" açık.
- Web yapısı iş parçacığı kullanmıyor (`web_nothreads`), bu yüzden SharedArrayBuffer/COOP-COEP
  ayarı gerekmez.
- Windows yapısında pck exe'ye gömülü (`embed_pck=true`); klasörde tek exe yeterli.
