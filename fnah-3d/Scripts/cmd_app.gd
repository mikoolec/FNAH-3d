extends VBoxContainer
class_name CmdApp
## Zawartość okna "Wiersz polecenia". Okno tworzy pc_control.

const PROMPT := "C:\\Users\\User>"
const FONT_SIZE := 18
const COL_TEXT := Color(0.8, 0.8, 0.8)

var pc   # PCControl (celowo bez typu: wywołujemy jego metody dynamicznie)

var _output: RichTextLabel
var _line: LineEdit
var _history: PackedStringArray = PackedStringArray()
var _hist_idx: int = 0


func _ready() -> void:
	_build()
	reset()


func _build() -> void:
	add_theme_constant_override("separation", 0)

	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Courier New", "Liberation Mono", "monospace"])

	_output = RichTextLabel.new()
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.scroll_following = true
	_output.selection_enabled = false
	_output.add_theme_font_override("normal_font", mono)
	_output.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	_output.add_theme_color_override("default_color", COL_TEXT)
	_output.gui_input.connect(_on_output_gui_input)
	add_child(_output)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	add_child(row)

	var prompt := Label.new()
	prompt.text = PROMPT
	prompt.add_theme_font_override("font", mono)
	prompt.add_theme_font_size_override("font_size", FONT_SIZE)
	prompt.add_theme_color_override("font_color", COL_TEXT)
	row.add_child(prompt)

	_line = LineEdit.new()
	_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line.context_menu_enabled = false
	_line.caret_blink = true
	_line.add_theme_font_override("font", mono)
	_line.add_theme_font_size_override("font_size", FONT_SIZE)
	_line.add_theme_color_override("font_color", COL_TEXT)
	_line.add_theme_color_override("caret_color", COL_TEXT)
	var flat := UiStyle.box(Color.BLACK)
	_line.add_theme_stylebox_override("normal", flat)
	_line.add_theme_stylebox_override("focus", flat)
	_line.text_submitted.connect(_on_submit)
	_line.gui_input.connect(_on_line_gui_input)
	row.add_child(_line)


# Czyści okno i pokazuje nagłówek (jak świeżo otwarty cmd)
func reset() -> void:
	_output.clear()
	_history.clear()
	_hist_idx = 0
	_line.clear()
	_println("Microsoft Windows [Wersja 10.0.19045.3693]")
	_println("(c) Microsoft Corporation. Wszelkie prawa zastrzeżone.")
	_println()


func focus_input() -> void:
	if is_visible_in_tree():
		_line.grab_focus()


func _on_output_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_line.grab_focus()


# Strzałki góra/dół = historia poleceń
func _on_line_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_UP and not _history.is_empty():
		_hist_idx = maxi(_hist_idx - 1, 0)
		_line.text = _history[_hist_idx]
		_line.caret_column = _line.text.length()
		_line.accept_event()
	elif event.keycode == KEY_DOWN:
		_hist_idx = mini(_hist_idx + 1, _history.size())
		_line.text = _history[_hist_idx] if _hist_idx < _history.size() else ""
		_line.caret_column = _line.text.length()
		_line.accept_event()


func _println(text: String = "") -> void:
	_output.add_text(text)
	_output.newline()


func _on_submit(text: String) -> void:
	_println(PROMPT + text)
	if not text.strip_edges().is_empty():
		_history.append(text)
	_hist_idx = _history.size()
	_line.clear()
	_run(text)
	focus_input.call_deferred()


# =========================================================================
# POLECENIA
# =========================================================================

func _run(line: String) -> void:
	var text := line.strip_edges()
	if text.is_empty():
		return
	var parts := text.split(" ", false)
	var cmd := parts[0].to_lower()
	var arg := " ".join(parts.slice(1)).strip_edges()

	match cmd:
		"start": _cmd_start(arg)
		"close": _cmd_close(arg)
		"shutdown": _cmd_shutdown(arg)
		"sleep": _cmd_sleep()
		"help": _cmd_help()
		"cls": _output.clear()
		"exit": pc.close_app(&"cmd")
		_:
			_println("„%s” nie jest rozpoznawana jako polecenie wewnętrzne lub zewnętrzne, program wykonywalny lub plik wsadowy." % parts[0])
			_println()


func _cmd_start(arg: String) -> void:
	if arg.is_empty():
		_println("Użycie: START <nazwa aplikacji>")
		_println()
		return
	var id := AppRegistry.find_by_cmd(arg)
	if id == &"":
		_println("System nie może odnaleźć pliku %s." % arg)
		_println()
		return
	pc.launch_app(id)


func _cmd_close(arg: String) -> void:
	if arg.is_empty():
		_println("Użycie: CLOSE <nazwa aplikacji>")
		_println()
		return
	var id := AppRegistry.find_by_cmd(arg)
	if id == &"":
		_println("BŁĄD: Nie znaleziono aplikacji „%s”." % arg)
	elif not pc.is_app_open(id):
		_println("BŁĄD: Aplikacja „%s” nie jest uruchomiona." % arg)
	else:
		pc.close_app(id)
		_println("SUKCES: Aplikacja „%s” została zamknięta." % arg)
	_println()


func _cmd_shutdown(arg: String) -> void:
	if arg.to_lower().contains("/r"):
		_println("Trwa ponowne uruchamianie systemu...")
		pc.power_action(&"restart")
	else:
		_println("Trwa zamykanie systemu...")
		pc.power_action(&"shutdown")


func _cmd_sleep() -> void:
	_println("Usypianie komputera...")
	pc.power_action(&"sleep")


func _cmd_help() -> void:
	_println("START".rpad(10) + "Uruchamia aplikację.  Użycie: START <aplikacja>")
	_println("CLOSE".rpad(10) + "Zamyka aplikację.  Użycie: CLOSE <aplikacja>")
	_println("SHUTDOWN".rpad(10) + "Wyłącza komputer (SHUTDOWN /R = uruchom ponownie).")
	_println("SLEEP".rpad(10) + "Usypia komputer.")
	_println("CLS".rpad(10) + "Czyści ekran.")
	_println("EXIT".rpad(10) + "Zamyka to okno.")
	_println()
