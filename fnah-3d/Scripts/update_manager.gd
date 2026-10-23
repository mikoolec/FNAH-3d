extends Node
class_name UpdateManager
## Usługa Windows Update w grze: losuje aktualizacje, pilnuje deadline'ów, obsługuje
## sprawdzanie / pobieranie / instalowanie. UI jest w settings_app.gd.

signal forced_update_due(count: int)   # deadline minął - komputer ma się zaktualizować siłą

# =========================================================================
# USTAWIENIA - zmieniaj do testów (np. SPAWN_INTERVAL 10, SPAWN_CHANCE 1.0, DEADLINE 40)
# =========================================================================
const SPAWN_INTERVAL := 60.0            # co ile sekund losujemy, czy pojawi się aktualizacja
const SPAWN_CHANCE := 0.5               # szansa (0.0-1.0), że wylosowana aktualizacja się pojawi
const DEADLINE := 120.0                 # czas (s) na wykonanie aktualizacji, liczony od jej utworzenia
const MAX_PENDING := 2                  # ile aktualizacji może czekać jednocześnie

const CHECK_TIME := 3.0                 # czas sprawdzania aktualizacji (s)
const OFFLINE_CHECK_FAIL_TIME := 1.5    # po ilu s bez internetu sprawdzanie kończy się błędem
const DOWNLOAD_TIME := 8.0              # czas pobierania JEDNEJ aktualizacji (s)
const INSTALL_TIME := 10.0              # czas instalowania JEDNEJ aktualizacji (s)
const FORCED_TIME_PER_UPDATE := 20.0    # czas ekranu wymuszonej aktualizacji NA KAŻDĄ aktualizację (s)
const READY_GRACE_TIME := 8.0           # sekundy doliczane do deadline'u po pobraniu aktualizacji
										# (czas na kliknięcie "Zainstaluj teraz")

const SHOW_DEADLINE := false            # czy pokazywać graczowi odliczanie przy znalezionych aktualizacjach

const ERR_NO_INTERNET := "Nie można połączyć się z usługą aktualizacji. Sprawdź połączenie z Internetem i spróbuj ponownie. (0x80072EE7)"

# {kb} - losowy numer KB, {n} - losowy numer wersji
const TITLE_POOL := [
	"2026-10 Aktualizacja zbiorcza dla systemu Windows 10 w wersji 22H2 dla systemów opartych na procesorach x64 ({kb})",
	"2026-10 Aktualizacja zabezpieczeń dla programu .NET Framework 3.5 i 4.8 w systemie Windows 10 w wersji 22H2 dla procesorów x64 ({kb})",
	"Aktualizacja analizy zabezpieczeń dla programu Microsoft Defender Antivirus - {kb} (wersja 1.405.{n}.0)",
	"Narzędzie Windows do usuwania złośliwego oprogramowania dla systemów x64 - 2026-10 ({kb})",
	"Aktualizacja stosu obsługi dla systemu Windows 10 w wersji 22H2 dla systemów opartych na procesorach x64 ({kb})",
	"Aktualizacja sterownika - Microsoft - PrintDevice - 10.0.19041.{n}",
	"Aktualizacja pakietu językowego dla języka polskiego (Polska) w systemie Windows 10 ({kb})",
	"Aktualizacja pakietu redystrybucyjnego Microsoft Visual C++ 2015-2022 (x64) ({kb})",
	"2026-10 Aktualizacja zabezpieczeń dla programu Internet Explorer 11 w systemie Windows 10 w wersji 22H2 ({kb})",
	"Aktualizacja funkcji do systemu Windows 10 w wersji 22H2 ({kb})",
	"Aktualizacja sterownika - Intel - System - 10.1.{n}.8",
	"Aktualizacja zabezpieczeń dla składników zabezpieczeń Windows Defender SmartScreen ({kb})",
]

enum State { FOUND, DOWNLOADING, READY, INSTALLING }   # ukryta = stan FOUND z flagą hidden

class Item:
	var id: int = 0
	var template: int = 0
	var title: String = ""
	var hidden: bool = true            # true = istnieje, ale gracz jej jeszcze nie znalazł
	var state: int = 0                 # UpdateManager.State
	var progress: float = 0.0          # 0..1 (pobieranie / instalowanie)
	var deadline_left: float = 0.0

var pc                                  # PCControl (bez typu - wołamy jego metody dynamicznie)
var items: Array = []                   # wszystkie oczekujące aktualizacje (także ukryte)
var history: Array = []                 # zainstalowane: {"title", "when", "auto"}
var checking: bool = false
var check_error: String = ""
var last_check_text: String = "dzisiaj, 00:00"
var deadline_paused: bool = false       # true, gdy deadline'y stoją (trwa pobieranie / instalowanie)

var _spawn_timer: float = 0.0
var _check_progress: float = 0.0        # 0..1, tempo zależy od szybkości internetu
var _check_offline_time: float = 0.0    # ile sekund trwa brak internetu w trakcie sprawdzania
var _next_id: int = 1


func _ready() -> void:
	if pc:
		last_check_text = "dzisiaj, " + str(pc.czas)


# =========================================================================
# ZAPYTANIA (dla UI)
# =========================================================================

func has_internet() -> bool:
	return NetworkManager.is_connected_to_internet

# Mnożnik czasu: szybkość sieci x liczba transferów dzielących łącze
func speed_factor() -> float:
	return maxf(NetworkManager.effective_multiplier(), 0.05)

func pending_count() -> int:
	return items.size()


# Aktualizacje widoczne dla gracza (znalezione)
func visible_items() -> Array:
	var out: Array = []
	for it in items:
		if not it.hidden:
			out.append(it)
	return out


func has_state(s: int) -> bool:
	for it in items:
		if not it.hidden and it.state == s:
			return true
	return false


# Trwa sprawdzanie, pobieranie albo instalowanie
func is_busy() -> bool:
	return checking or has_state(State.DOWNLOADING) or has_state(State.INSTALLING)


func status_text(it) -> String:
	match it.state:
		State.FOUND:
			return "Gotowe do pobrania"
		State.DOWNLOADING:
			if it != _first(State.DOWNLOADING):
				return "Oczekiwanie na pobranie"
			if not has_internet():
				return "Pobieranie wstrzymane - brak połączenia z Internetem"
			return "Pobieranie - %d%%" % int(it.progress * 100.0)
		State.READY:
			return "Gotowe do zainstalowania"
		State.INSTALLING:
			if it != _first(State.INSTALLING):
				return "Oczekiwanie na instalację"
			return "Instalowanie - %d%%" % int(it.progress * 100.0)
	return ""


func deadline_text(it) -> String:
	if it.deadline_left <= 0.0 and _forced_needs_internet() and not has_internet():
		return "Czas minął. Automatyczna instalacja rozpocznie się po odzyskaniu połączenia z Internetem"
	var s := int(ceil(maxf(it.deadline_left, 0.0)))
	var text := "Automatyczna instalacja z ponownym uruchomieniem komputera za %d:%02d" % [floori(s / 60.0), s % 60]
	if deadline_paused:
		text += " (wstrzymano na czas pobierania/instalowania)"
	return text


# =========================================================================
# AKCJE GRACZA
# =========================================================================

func start_check() -> void:
	if is_busy():
		return
	checking = true
	check_error = ""
	_check_progress = 0.0
	_check_offline_time = 0.0


func start_download() -> void:
	if is_busy():
		return
	for it in items:
		if not it.hidden and it.state == State.FOUND:
			it.state = State.DOWNLOADING
			it.progress = 0.0


func start_install() -> void:
	if is_busy():
		return
	for it in items:
		if not it.hidden and it.state == State.READY:
			it.state = State.INSTALLING
			it.progress = 0.0


# Wywoływane przez pc_control po ekranie wymuszonej aktualizacji: wszystko zostało zainstalowane
func complete_forced() -> void:
	for it in items:
		_add_history(it, true)
	items.clear()
	checking = false
	_check_progress = 0.0
	_check_offline_time = 0.0
	check_error = ""


# =========================================================================
# DZIAŁANIE W TLE
# =========================================================================

func _process(delta: float) -> void:
	# Zegar usługi chodzi tylko, gdy komputer jest włączony (pulpit lub uśpiony)
	if pc == null or not pc.is_system_running():
		NetworkManager.end_transfer(&"update")
		return
	var online := has_internet()

	# Zgłaszamy, że usługa aktualizacji korzysta z internetu (dzielenie łącza).
	# Wstrzymane pobieranie (brak sieci) nie zajmuje łącza.
	var downloading_now := _first(State.DOWNLOADING) != null
	if online and (checking or downloading_now):
		NetworkManager.report_transfer(&"update")
	else:
		NetworkManager.end_transfer(&"update")

	# 1) losowanie nowej aktualizacji - tylko gdy jest internet
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		if online and items.size() < MAX_PENDING and randf() < SPAWN_CHANCE:
			_spawn_update()

		# 2) sprawdzanie aktualizacji - tempo zależy od szybkości internetu
	if checking:
		if online:
			_check_offline_time = 0.0
			_check_progress += delta / (CHECK_TIME * speed_factor())
			if _check_progress >= 1.0:
				_finish_check()
		else:
			_check_offline_time += delta
			if _check_offline_time >= OFFLINE_CHECK_FAIL_TIME:
				checking = false
				check_error = ERR_NO_INTERNET

	# 3) pobieranie (wymaga internetu) i instalowanie (nie wymaga)
	var progressing := false    # czy coś faktycznie się teraz pobiera lub instaluje
	var dl = _first(State.DOWNLOADING)
	if dl != null and online:
		progressing = true
		dl.progress += delta / (DOWNLOAD_TIME * speed_factor())
		if dl.progress >= 1.0:
			dl.progress = 0.0
			dl.state = State.READY
			dl.deadline_left += READY_GRACE_TIME   # czas na kliknięcie "Zainstaluj teraz"
	var ins = _first(State.INSTALLING)
	if ins != null:
		progressing = true
		ins.progress += delta / INSTALL_TIME
		if ins.progress >= 1.0:
			_add_history(ins, false)
			items.erase(ins)

	# 4) deadline'y - liczone od utworzenia, ale stoją na czas pobierania i instalowania
	deadline_paused = progressing
	if progressing:
		return
	var expired := false
	for it in items:
		it.deadline_left = maxf(it.deadline_left - delta, 0.0)   # po deadline'ie zostaje na 0
		if it.deadline_left <= 0.0:
			expired = true
	# Deadline minął: wymuszamy od razu, ale jeśli trzeba coś pobrać, to dopiero gdy jest internet.
	# Bez internetu aktualizacja czeka i startuje w pierwszej klatce po odzyskaniu połączenia.
	if expired and (online or not _forced_needs_internet()):
		forced_update_due.emit(items.size())


func _first(s: int):
	for it in items:
		if not it.hidden and it.state == s:
			return it
	return null

# Czy wymuszona aktualizacja musi coś POBRAĆ (czyli potrzebuje internetu)?
# Aktualizacje już pobrane (gotowe / w trakcie instalowania) można zainstalować bez internetu.
func _forced_needs_internet() -> bool:
	for it in items:
		if it.hidden or it.state == State.FOUND or it.state == State.DOWNLOADING:
			return true
	return false

func _spawn_update() -> void:
	var it := Item.new()
	it.id = _next_id
	_next_id += 1
	it.template = _pick_template()
	it.title = TITLE_POOL[it.template].replace("{kb}", "KB%d" % randi_range(4500000, 5099999)) \
		.replace("{n}", str(randi_range(100, 1999)))
	it.deadline_left = DEADLINE
	items.append(it)


# Losuje wzór tytułu, starając się nie powtarzać tego, który już czeka
func _pick_template() -> int:
	var idx := randi() % TITLE_POOL.size()
	for _try in 8:
		var in_use := false
		for it in items:
			if it.template == idx:
				in_use = true
				break
		if not in_use:
			break
		idx = randi() % TITLE_POOL.size()
	return idx


func _finish_check() -> void:
	checking = false
	for it in items:
		it.hidden = false     # sprawdzenie ujawnia wszystkie istniejące aktualizacje
	last_check_text = "dzisiaj, " + str(pc.czas)


func _add_history(it, auto: bool) -> void:
	history.push_front({"title": it.title, "when": str(pc.czas), "auto": auto})
	if history.size() > 12:
		history.pop_back()
