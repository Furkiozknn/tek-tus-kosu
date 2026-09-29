class_name Ceviri
extends RefCounted
## Arayüz metinleri: KAYNAK dil Türkçe (tr() anahtarı Türkçe metnin kendisi), İngilizce tablo aşağıda.
## Türkçe için tablo gerekmez: anahtar bulunamazsa Godot metni aynen döner (proje ayarı: yedek dil "tr").
##
## Yeni bir arayüz metni eklerken:
##   1. Kodda tr("Türkçe metin") (örnek metotlarda) ya da Ceviri.t("...") (static metotlarda) yaz;
##      sahne üreticide (tools/sahne_uret.gd) düğme/etiket metinleri zaten anahtardır ve otomatik çevrilir;
##   2. Aşağıdaki EN tablosuna aynı anahtarla İngilizcesini ekle (biçim belirteçlerinin sayısı ve sırası
##      aynı kalsın: %d, %s, %+d);
##   3. tests/testler.gd -> _test_ceviri eksik anahtarı ve belirteç uyuşmazlığını yakalar.
##
## İngilizce metinler doğal ve kısa ("Jump: Space or tap"), dizgi dizgi çeviri değil: videolar X ve
## YouTube'da İngilizce yayınlanıyor.

const EN := {
	# --- menü ---
	"Tek Tuş Koşu": "Tek Tuş Koşu",
	"TEK TUŞ · TAM RİTİM": "ONE KEY · FULL RHYTHM",
	"Oyna": "Play",
	"Boşluk ya da dokun: zıpla · basılı tut: daha yüksek · havada bir kez daha": "Space or tap to jump · hold to go higher · jump again in mid-air",
	"Ritim": "Rhythm",
	"Günlük koşu": "Daily run",
	"Günlük": "Daily",
	"Karakter": "Character",
	"Başarımlar": "Achievements",
	"Ayarlar": "Settings",
	"Çıkış": "Quit",
	"Başlamak için boş bir yere dokun ya da Boşluk": "Tap anywhere or press Space to start",
	"Rekor: %d m": "Best: %d m",
	"Rahat rekor: %d m": "Relaxed best: %d m",
	"Altın: %d": "Gold: %d",
	"Görevler": "Tasks",
	"seviye %d": "level %d",
	"Başarım %d/%d": "Achievements %d/%d",
	"%d gün": "%d days",
	"Günün ritmi · %s": "Rhythm of the day · %s",
	"Günün ritmi": "Rhythm of the day",
	"Bugün herkes aynı şarkıda aynı çatılarda koşar. Deneme: %d": "Everyone runs the same song on the same rooftops today. Attempts: %d",
	"Bugün herkes aynı çatılarda koşar. Deneme: %d": "Everyone runs the same rooftops today. Attempts: %d",
	"Engeller müziğin vuruşlarına hizalı; vuruşta zıpla.": "Obstacles follow the beat; jump on it.",
	"Son günler: ": "Recent days: ",
	# --- paneller ---
	"Geri": "Back",
	"Müzik": "Music",
	"Efektler": "Effects",
	"Dil": "Language",
	"Dil: %s": "Language: %s",
	"Tam ekran": "Fullscreen",
	"Ekran sarsıntısı": "Screen shake",
	"Titreşim (telefon)": "Vibration (phone)",
	"Yüksek kontrast (tehlike çerçevesi)": "High contrast (hazard outline)",
	"Rahat mod (%80 hız, ayrı rekor)": "Relaxed mode (slower, separate record)",
	"Ritim koşusu": "Rhythm run",
	"Engeller müziğin vuruşuna hizalı. Pembe oklu çizgide zıpla.": "Obstacles follow the beat. Jump on the pink arrow line.",
	"Ses gecikmesi": "Audio delay",
	"Vuruşları geç duyuyorsan (bluetooth kulaklık) artır.": "Raise this if you hear beats late (bluetooth headphones).",
	"Zıplama vuruşundan önce tık sesi": "Click sound before a jump beat",
	"Seçili": "Selected",
	"Seç": "Select",
	"Satın al: %d altın": "Buy: %d gold",
	# --- kostümler ---
	"Klasik": "Classic",
	"Kızıl": "Red",
	"Yeşil": "Green",
	"Menekşe": "Violet",
	"Taç": "Crown",
	# --- şarkılar ---
	"Gece Koşusu": "Night Run",
	"Çatı Neşesi": "Rooftop Joy",
	"Fırtına Hattı": "Storm Line",
	"150 BPM · dengeli": "150 BPM · balanced",
	"128 BPM · daha çok alçak tavan": "128 BPM · more low ceilings",
	"140 BPM · sık ikili diken": "140 BPM · frequent double spikes",
	# --- temalar ---
	"Gece": "Night",
	"Şarap": "Wine",
	"Yağış": "Rain",
	"Fırtına": "Storm",
	# --- oyun içi ---
	"Zıpla: Boşluk ya da dokun": "Jump: Space or tap",
	"Basılı tut: daha yüksek · havada bir kez daha zıpla": "Hold: jump higher · jump once more in mid-air",
	"Sarı tabelanın altında KISA dokun": "Tap BRIEFLY under the yellow sign",
	"Müziği dinle: pembe oklu çizgide vuruşla zıpla · alçak tavanda kısa dokun": "Listen to the music: jump on the beat at the pink arrow line · tap briefly under low ceilings",
	"Ölüm tekrarı  •  geçmek için dokun": "Death replay  •  tap to skip",
	"Çukura düştün  •  geçmek için dokun": "You fell  •  tap to skip",
	"Kıl payı! +%d": "Close call! +%d",
	"REKOR": "BEST",
	"SON": "LAST",
	"rekor": "best",
	"← karşı rüzgâr": "← headwind",
	"arka rüzgâr →": "tailwind →",
	"Tam vuruş": "Perfect",
	"Erken": "Early",
	"Geç": "Late",
	"Görev tamam: %s  +%d altın": "Task done: %s  +%d gold",
	"★ Başarım: %s  +%d altın": "★ Achievement: %s  +%d gold",
	"DURAKLATILDI": "PAUSED",
	"Devam": "Resume",
	"Baştan": "Restart",
	"Menü": "Menu",
	# --- oyun sonu ---
	"KOŞU BİTTİ": "RUN OVER",
	"Mesafe: %d m": "Distance: %d m",
	"YENİ REKOR!": "NEW RECORD!",
	"GÜNÜN REKORU!": "TODAY'S RECORD!",
	"Bugünün rekoru: %d m": "Today's best: %d m",
	"   (deneme %d)": "   (attempt %d)",
	"Günlük rekor: %d m": "Daily best: %d m",
	"Günün ritmi rekoru: %d m": "Rhythm of the day best: %d m",
	"%s rekoru: %d m": "%s best: %d m",
	"   Ödül: +%d": "   Bonus: +%d",
	"   Tam vuruş: %d": "   Perfect: %d",
	"   Ort. sapma: %+d ms": "   Avg. offset: %+d ms",
	"Görev seviyesi %d!": "Task level %d!",
	"Tekrar": "Retry",
	"Paylaş": "Share",
	"Gecikme": "Delay",
	"Gecikme %+d ms": "Delay %+d ms",
	"Zıplamaların vuruştan ortalama %+d ms uzakta. Ses gecikmesi ayarını buna göre değiştir.": "Your jumps are %+d ms from the beat on average. Adjust the audio delay accordingly.",
	"Ayarlandı ✓": "Set ✓",
	"Paylaşıldı ✓": "Shared ✓",
	"Kopyalandı ✓": "Copied ✓",
	"Tekrar için dokun ya da Boşluk": "Tap or press Space to retry",
	"çok erken": "way early",
	"erken": "early",
	"tam": "on beat",
	"geç": "late",
	"çok geç": "way late",
	# --- dikey uyarı ---
	"Telefonu yan çevir": "Rotate your phone",
	"Tek Tuş Koşu yatay oynanır": "Tek Tuş Koşu is played in landscape",
	# --- görev şablonları ---
	"Tek koşuda %d m koş": "Run %d m in one run",
	"Tek koşuda %d altın topla": "Collect %d gold in one run",
	"Tek koşuda %d kez havada zıpla": "Jump in mid-air %d times in one run",
	"Tek koşuda %d kez kıl payı kaç": "Have %d close calls in one run",
	"Toplam %d altın topla": "Collect %d gold in total",
	"%d koşu tamamla": "Complete %d runs",
	"Toplam %d kıl payı kaçış": "%d close calls in total",
	"Toplam %d m koş": "Run %d m in total",
	"Toplam %d kez havada zıpla": "Jump in mid-air %d times in total",
	# --- başarımlar ---
	"İlk adım": "First steps",
	"Bir koşuyu bitir": "Finish a run",
	"Çatı yolcusu": "Rooftop traveler",
	"Tek koşuda 500 m": "500 m in one run",
	"Gece kuşu": "Night owl",
	"Tek koşuda 1000 m": "1000 m in one run",
	"Şehrin öbür ucu": "Across the city",
	"Tek koşuda 2000 m": "2000 m in one run",
	"Cepler dolu": "Pockets full",
	"Tek koşuda 50 altın": "50 gold in one run",
	"Kıl payı ustası": "Close-call master",
	"Tek koşuda 10 kıl payı kaçış": "10 close calls in one run",
	"Eğil ve geç": "Duck and pass",
	"Tek koşuda 10 alçak tavan": "10 low ceilings in one run",
	"Piston dansı": "Piston dance",
	"Tek koşuda 10 piston": "10 pistons in one run",
	"Hafif adımlar": "Light steps",
	"Tek koşuda 8 çürük iskele": "8 crumbling scaffolds in one run",
	"Vuruşu yakala": "Catch the beat",
	"Ritim koşusunda 20 tam vuruş": "20 perfect beats in a rhythm run",
	"Günün koşucusu": "Runner of the day",
	"Günlük koşuda 300 m": "300 m in the daily run",
	"Maratoncu": "Marathoner",
	"Toplam 10.000 m koş": "Run 10,000 m in total",
	"Gardırop": "Wardrobe",
	"Bütün kostümleri aç": "Unlock every costume",
	"Metronom": "Metronome",
	"Ritim koşusunda 100 tam vuruş": "100 perfect beats in a rhythm run",
	"Üç şarkı": "Three songs",
	"Her şarkıda 300 m rekor": "300 m record on every song",
	"Ritim müdavimi": "Rhythm regular",
	"Günün ritmini 5 ayrı gün koş": "Run the rhythm of the day on 5 different days",
}

## Testler için: boş değilse dil buna sabitlenir (CI'nin işletim sistemi dili testleri etkilemesin).
static var zorla := ""

static var _kuruldu := false


## İngilizce tabloyu TranslationServer'a yükler (birden çok çağrı zararsız).
static func kur() -> void:
	if _kuruldu:
		return
	_kuruldu = true
	var t := Translation.new()
	t.locale = "en"
	for k in EN:
		t.add_message(k, EN[k])
	TranslationServer.add_translation(t)


## Static metotlarda tr() yok (Object metodu): aynı çeviriyi buradan al.
static func t(metin: String) -> String:
	return TranslationServer.translate(metin)


## Etkin dil: testte zorla, yoksa kayıtlı seçim ("tr" / "en"), yoksa işletim sistemi / tarayıcı dili
## (OS.get_locale_language; web'de navigator.language): "tr" ise Türkçe, diğerleri İngilizce.
static func dil_etkin(kayitli: String = "") -> String:
	if zorla != "":
		return zorla
	if kayitli == "tr" or kayitli == "en":
		return kayitli
	return "tr" if OS.get_locale_language() == "tr" else "en"


static func dil_uygula(kayitli: String = "") -> void:
	kur()
	TranslationServer.set_locale(dil_etkin(kayitli))


static func dil_kodu() -> String:
	return "tr" if TranslationServer.get_locale().begins_with("tr") else "en"


static func dil_adi() -> String:
	return "Türkçe" if dil_kodu() == "tr" else "English"


## Dili değiştirir ve KAYDEDER (kayıt anahtarı "dil"; eski kayıtlarda yok, varsayılan "" = otomatik).
static func dil_degistir() -> void:
	var yeni := "en" if dil_kodu() == "tr" else "tr"
	Kayit.ayar_yaz("dil", yeni)
	if zorla != "":
		zorla = yeni
	dil_uygula(yeni)


## Kaynak anahtarın biçim belirteci (%d, %s, %+d) dizisi: çeviri ile aynı olmalı.
static func belirtecler(m: String) -> PackedStringArray:
	var sonuc := PackedStringArray()
	var r := RegEx.new()
	r.compile("%[-+ 0#]*[0-9]*(?:\\.[0-9]+)?[dsf]")
	for e in r.search_all(m):
		sonuc.append(e.get_string())
	return sonuc
