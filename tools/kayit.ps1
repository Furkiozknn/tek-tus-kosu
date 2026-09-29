# Ham oynanis kaydi (sosyal medya klibi): yazisiz, sessiz, dikey 1080x1920.
#   powershell -ExecutionPolicy Bypass -File tools\kayit.ps1 [-Cikti yol.mp4]
#
# Botun (tools/kayit.gd) oynadigi kosu --write-movie ile PNG dizisine yazilir (Godot pencereli
# calisir, ayni anda tek Godot); ffmpeg oyunu 1080 genislige olcekleyip dikey tuvalin ortasina koyar:
# ust bant gokyuzu rengi, alt bant zemin rengi (oyunun zemin cizgisinde birlesir). H.264 yuv420p
# +faststart, ses yok (-an). Arayuz katmani gizli, ekranda yazi yok. 18 sn.
#
# Bu bir BOT kaydidir: tepki gecikmesi 0,04-0,12 sn (insan bandi); tools/kayit.gd bir engelde
# bilerek gec ziplar (olum + renk bandi + yeniden baslama gorunsun).
param(
  [string] $Cikti = 'D:\Claude Projeleri\sosyal\medya\oyunlar\tek-tus-kosu.mp4'
)
$ErrorActionPreference = 'Continue'
$kok = Split-Path -Parent $PSScriptRoot
Set-Location $kok
$gecici = Join-Path $env:TEMP 'tek_tus_kosu_kayit'
if (Test-Path $gecici) { Remove-Item $gecici -Recurse -Force }
New-Item -ItemType Directory -Force $gecici | Out-Null

& godot --path . --write-movie (Join-Path $gecici 'kare.png') --fixed-fps 60 --resolution 1280x720 res://tools/kayit.tscn
$kareler = @(Get-ChildItem $gecici -Filter 'kare*.png')
if ($kareler.Count -lt 900) { Write-Output "KAYIT BASARISIZ: $($kareler.Count) kare"; exit 1 }
Write-Output "kare sayisi: $($kareler.Count)"

$klasor = Split-Path $Cikti
New-Item -ItemType Directory -Force $klasor | Out-Null
# Pencerenin (1280x720) ortasindan 800x600'luk dilim kirpilir (oyuncu solda, onu 300 px ileri gorus var),
# 1080x810'a buyutulur. Zemin cizgisi dilimde y=440 -> 594; ustu gokyuzu rengi (pad), zemin cizgisinin
# altini zemin rengi (drawbox) doldurur.
$filtre = "crop=800:600:100:120,scale=1080:810:flags=lanczos,pad=1080:1920:0:560:color=0x201b2d,drawbox=x=0:y=1157:w=1080:h=763:color=0x120d1f:t=fill,format=yuv420p"
& ffmpeg -y -loglevel error -framerate 60 -i (Join-Path $gecici 'kare%08d.png') -vf $filtre `
  -r 30 -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -movflags +faststart -an $Cikti
if ($LASTEXITCODE -ne 0) { Write-Output "ffmpeg EXIT=$LASTEXITCODE"; exit $LASTEXITCODE }
Write-Output ("KAYIT HAZIR: {0} ({1:N0} bayt)" -f $Cikti, (Get-Item $Cikti).Length)
