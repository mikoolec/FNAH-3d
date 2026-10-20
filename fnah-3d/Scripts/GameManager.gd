extends Node
## Autoload: GameManager
## Trzyma stan gry: numer nocy, zegar, wymagane wydruki oraz warunki wygranej i przegranej.
## Inne skrypty tylko czytaja ten stan albo podpinaja sie pod sygnaly.

enum GameState { NONE, PLAYING, NIGHT_WON, GAME_WON, LOST }
enum LoseReason { CAUGHT, TIME_UP, ASLEEP }

signal state_changed(new_state: GameState)
signal night_started(night: int)
signal time_changed(time_text: String)   # np. "03:45", wysylany gdy zmieni sie minuta
signal hour_changed(hour: int)           # wysylany przy zmianie godziny (0-23)
signal requirements_changed(required: Array[String], delivered: Array[String])
signal file_delivered(file_name: String)
signal night_won(night: int)
signal game_won()
signal game_lost(reason: LoseReason, culprit: String)

# --- Ustawienia zegara ---
const NIGHT_START_MINUTE: int = 0        # 00:00
const NIGHT_LENGTH_MINUTES: int = 360    # do 06:00

# --- Konfiguracja nocy (indeks 0 = noc 1) ---
# real_seconds   - ile prawdziwych sekund trwa cala noc (00:00 -> 06:00)
# required_sheets - ile roznych kartek trzeba wydrukowac i odlozyc
# difficulty     - bazowa trudnosc 0.0-1.0 (dla przeciwnikow i awarii)
const NIGHTS := [
	{"real_seconds": 300.0, "required_sheets": 1, "difficulty": 0.2},
	{"real_seconds": 330.0, "required_sheets": 2, "difficulty": 0.35},
	{"real_seconds": 360.0, "required_sheets": 2, "difficulty": 0.5},
	{"real_seconds": 390.0, "required_sheets": 3, "difficulty": 0.7},
	{"real_seconds": 420.0, "required_sheets": 4, "difficulty": 0.9},
]

# Mnoznik szybkosci czasu - przydatny do testow (np. 10.0 = noc 10x szybciej)
var time_scale: float = 1.0

var state: GameState = GameState.NONE
var current_night: int = 0
var elapsed_seconds: float = 0.0
var night_progress: float = 0.0          # 0.0 (00:00) -> 1.0 (06:00)
var last_lose_reason: LoseReason = LoseReason.CAUGHT

var required_files: Array[String] = []
var delivered_files: Array[String] = []

var _last_minute: int = -1
var _last_hour: int = -1


func _process(delta: float) -> void:
	if state != GameState.PLAYING:
		return

	elapsed_seconds += delta * time_scale
	night_progress = clampf(elapsed_seconds / _night_duration(), 0.0, 1.0)
	_update_clock()

	if night_progress >= 1.0:
		_finish_night()


# =========================================================================
# STEROWANIE PRZEBIEGIEM GRY
# =========================================================================

func start_game() -> void:
	start_night(1)


func start_night(night: int) -> void:
	current_night = clampi(night, 1, NIGHTS.size())
	elapsed_seconds = 0.0
	night_progress = 0.0
	required_files.clear()
	delivered_files.clear()
	_last_minute = -1
	_last_hour = -1

	_set_state(GameState.PLAYING)
	night_started.emit(current_night)
	_update_clock(true)
	requirements_changed.emit(required_files, delivered_files)


func next_night() -> void:
	if state == GameState.NIGHT_WON:
		start_night(current_night + 1)


func retry_night() -> void:
	if state == GameState.LOST:
		start_night(current_night)


# Wywolaj, gdy przeciwnik zlapie gracza, np. GameManager.player_caught("Krystian")
func player_caught(culprit: String = "") -> void:
	if state == GameState.PLAYING:
		_lose(LoseReason.CAUGHT, culprit)

func player_fell_asleep() -> void:
	if state == GameState.PLAYING:
		_lose(LoseReason.ASLEEP, "")

# =========================================================================
# WYMAGANE WYDRUKI
# =========================================================================

# Losuje wymagane pliki z puli nazw (liczba zalezy od konfiguracji nocy).
func generate_requirements(pool: Array[String]) -> void:
	var cfg: Dictionary = _night_config()
	var shuffled: Array[String] = pool.duplicate()
	shuffled.shuffle()

	var count: int = mini(int(cfg["required_sheets"]), shuffled.size())
	var picked: Array[String] = []
	for i in range(count):
		picked.append(shuffled[i])
	set_required_files(picked)


func set_required_files(files: Array[String]) -> void:
	required_files = files.duplicate()
	delivered_files.clear()
	requirements_changed.emit(required_files, delivered_files)


# Wywolaj, gdy gracz odlozy gotowa kartke w wyznaczonym miejscu.
# Zwraca true, jesli kartka byla wymagana i jeszcze nie zaliczona.
func deliver_file(file_name: String) -> bool:
	if state != GameState.PLAYING:
		return false
	if file_name in required_files and not (file_name in delivered_files):
		delivered_files.append(file_name)
		file_delivered.emit(file_name)
		requirements_changed.emit(required_files, delivered_files)
		return true
	return false


func is_objective_complete() -> bool:
	return not required_files.is_empty() and delivered_files.size() >= required_files.size()


# =========================================================================
# ZEGAR
# =========================================================================

# Aktualna godzina na zegarze w minutach od polnocy (0-1439).
func get_clock_minutes() -> int:
	var total: int = NIGHT_START_MINUTE + int(night_progress * NIGHT_LENGTH_MINUTES)
	return posmod(total, 1440)


# Czas w formacie "03:45".
func get_time_string() -> String:
	var minutes: int = get_clock_minutes()
	return "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]


func get_hour() -> int:
	return floori(get_clock_minutes() / 60.0)


func get_seconds_left() -> float:
	return maxf(_night_duration() - elapsed_seconds, 0.0)


# =========================================================================
# TRUDNOSC (dla przeciwnikow i awarii)
# =========================================================================

func get_night_difficulty() -> float:
	return float(_night_config()["difficulty"])


# Trudnosc rosnaca w trakcie nocy: baza nocy + do 0.15 pod koniec.
func get_difficulty() -> float:
	return clampf(get_night_difficulty() + night_progress * 0.15, 0.0, 1.0)


func is_playing() -> bool:
	return state == GameState.PLAYING


# =========================================================================
# WEWNETRZNE
# =========================================================================

func _night_config() -> Dictionary:
	return NIGHTS[clampi(current_night - 1, 0, NIGHTS.size() - 1)]


func _night_duration() -> float:
	return float(_night_config()["real_seconds"])


func _update_clock(force: bool = false) -> void:
	var minute: int = get_clock_minutes()
	if not force and minute == _last_minute:
		return
	_last_minute = minute
	time_changed.emit(get_time_string())

	var hour: int = get_hour()
	if hour != _last_hour:
		_last_hour = hour
		hour_changed.emit(hour)


func _finish_night() -> void:
	if is_objective_complete():
		night_won.emit(current_night)
		if current_night >= NIGHTS.size():
			_set_state(GameState.GAME_WON)
			game_won.emit()
		else:
			_set_state(GameState.NIGHT_WON)
	else:
		_lose(LoseReason.TIME_UP, "")


func _lose(reason: LoseReason, culprit: String) -> void:
	last_lose_reason = reason
	_set_state(GameState.LOST)
	game_lost.emit(reason, culprit)


func _set_state(new_state: GameState) -> void:
	state = new_state
	state_changed.emit(new_state)
