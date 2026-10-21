extends Node
## Autoload: FatigueManager
## Zmęczenie 0.0 (wypoczęty) -> 1.0 (zasypia = przegrana).

signal fatigue_changed(value: float)

# --- Ustawienia (do tuningu) ---
const FATIGUE_PER_SECOND: float = 1.0 / 240.0  # 4 min do zaśnięcia bez kawy
const DARKEN_START: float = 0.25               # od tego zmęczenia zaczyna się ściemnianie
const DARKEN_SMOOTH: float = 1.5               # szybkość wygładzania ściemniania
const FALL_START: float = 0.4                  # od tego zmęczenia zaczynają się upadki
const FALL_MAX_RATE: float = 0.25              # średnio upadków na sekundę przy zmęczeniu 1.0
const FALL_COOLDOWN: float = 6.0               # minimalna przerwa między upadkami (s)
const COFFEE_STRENGTH: float = 0.25            # o ile jedna kawa zmniejsza zmęczenie

var fatigue: float = 0.0
var _overlay_alpha: float = 0.0
var _fall_cooldown: float = 0.0
var _asleep: bool = false

var _overlay: ColorRect
var _player: CharacterBody3D


func _ready() -> void:
	# Czarna nakładka na cały ekran, nad całym UI
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 0.0
	layer.add_child(_overlay)

	GameManager.night_started.connect(_on_night_started)


func _on_night_started(_night: int) -> void:
	reset()


func reset() -> void:
	fatigue = 0.0
	_overlay_alpha = 0.0
	_fall_cooldown = 0.0
	_asleep = false
	_overlay.modulate.a = 0.0
	fatigue_changed.emit(fatigue)


func _process(delta: float) -> void:
	if _asleep or not GameManager.is_playing():
		return

	# 1. Zmęczenie samoczynnie rośnie
	fatigue = minf(fatigue + FATIGUE_PER_SECOND * GameManager.time_scale * delta, 1.0)
	fatigue_changed.emit(fatigue)

	# 2. Stopniowe ściemnianie ekranu
	var target: float = clampf((fatigue - DARKEN_START) / (1.0 - DARKEN_START), 0.0, 1.0)
	_overlay_alpha = lerpf(_overlay_alpha, target, 1.0 - exp(-DARKEN_SMOOTH * delta))
	_overlay.modulate.a = _overlay_alpha

	# 3. Losowe upadki (częstsze im większe zmęczenie)
	_fall_cooldown = maxf(_fall_cooldown - delta, 0.0)
	if fatigue > FALL_START and _fall_cooldown <= 0.0 and _can_fall():
		var k: float = (fatigue - FALL_START) / (1.0 - FALL_START)
		var rate: float = FALL_MAX_RATE * k * k
		if randf() < 1.0 - exp(-rate * delta):
			_player.start_ragdoll()
			_fall_cooldown = FALL_COOLDOWN

	# 4. Pełne zmęczenie = zasnął
	if fatigue >= 1.0:
		_fall_asleep()


func _unhandled_input(event: InputEvent) -> void:
	# TESTOWY klawisz - do usunięcia, gdy będzie prawdziwy system picia kawy
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_K:
		drink_coffee()


## Wywołaj z przyszłego systemu picia kawy (opcjonalnie z własną mocą).
func drink_coffee(strength: float = COFFEE_STRENGTH) -> void:
	if _asleep:
		return
	fatigue = maxf(fatigue - strength, 0.0)
	fatigue_changed.emit(fatigue)
	print("Kawa! Zmęczenie: %.2f" % fatigue)


func _can_fall() -> bool:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("Player") as CharacterBody3D
		if _player == null:
			return false
	# Nie przewracamy gracza, gdy siedzi, używa PC/panelu, wspina się lub już się przewraca
	return _player.current_state == _player.State.FREE \
		and not _player.walk_locked \
		and not _player.is_using_computer \
		and not _player.is_using_panel \
		and not _player.player_climbing \
		and not _player.is_ragdolling


func _fall_asleep() -> void:
	_asleep = true
	_overlay_alpha = 1.0
	_overlay.modulate.a = 1.0
	GameManager.player_fell_asleep()
