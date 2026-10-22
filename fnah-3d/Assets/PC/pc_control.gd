extends Control

enum DropTarget { NONE, DESKTOP, BROWSER, PRINTER, TRASH }
enum PowerState { OFF, BOOTING, LOGIN, LOGGING_IN, DESKTOP, SLEEPING, WAKING, SHUTTING_DOWN }

const DESKTOP_FILE_SCENE = preload("res://Assets/PC/Aplikacje/Ikony/desktop_file.tscn")
const CLOSE_TEX = preload("res://Assets/PC/Aplikacje/Przyciski/close_button.png")

# --- Zasilanie (czasy w sekundach) ---
const BOOT_BLACK_TIME := 1.0     # czarny ekran przed logo
const BOOT_TIME := 6.0           # logo + kółeczka
const WELCOME_TIME := 1.5        # ekran "Witaj" po zalogowaniu
const WAKE_TIME := 0.8           # wybudzenie z uśpienia
const SHUTDOWN_TIME := 2.5       # ekran "Zamykanie systemu"
const RESTART_PAUSE := 1.0       # czarny ekran między zamknięciem a bootem przy restarcie
const USER_NAME := "User"

# --- Siatka pulpitu ---
const GRID_ORIGIN := Vector2(10, 10)
const CELL_SIZE := Vector2(140, 175)
const ICON_SIZE := Vector2(115, 157)
const GRID_COLS := 7
const GRID_ROWS := 5
const FILE_SPAWN_CELL := Vector2i(6, 2)

const APP_ICONS := [
	{"id": &"printer", "label": "Printer", "kind": DesktopIcon.Kind.APP, "cell": Vector2i(0, 1),
		"texture": preload("res://Assets/PC/Aplikacje/Ikony/printer.png")},
	{"id": &"trash", "label": "ZHR", "kind": DesktopIcon.Kind.SYSTEM, "cell": Vector2i(0, 2),
		"texture": preload("res://Assets/PC/Aplikacje/Ikony/trashIcon.png")},
	{"id": &"browser", "label": "Chrome", "kind": DesktopIcon.Kind.APP, "cell": Vector2i(6, 1),
		"texture": preload("res://Assets/PC/Aplikacje/Ikony/chrome.png")},
]

const DROP_RULES := {
	DesktopIcon.Kind.FILE: [DropTarget.DESKTOP, DropTarget.PRINTER, DropTarget.TRASH],
	DesktopIcon.Kind.APP: [DropTarget.DESKTOP],
	DesktopIcon.Kind.SYSTEM: [DropTarget.DESKTOP],
}

@onready var mouse_cursor: Sprite2D = $MouseCursor
@onready var browserWindow = $BrowserWindow
@onready var printerWindow = $PrinterWindow
@onready var download_window: PanelContainer = $BrowserWindow/DownloadWindow
@onready var browser: MarginContainer = $BrowserWindow/MarginContainer
@onready var zegar: Label = $TaskBar/GridContainer/Zegar
@onready var taskbar: PanelContainer = $TaskBar
@onready var printer_gui: Control = $PrinterWindow/MarginContainer/App/GUI

var pc_mouse_pos: Vector2 = Vector2(512, 512)

@export var panel_windows: Array[DraggablePanelContainer]

var all_received_emails: Array = []
var active_email_app: Control = null
var czas: String = "00:00"

var icon_layer: Control

# --- Zasilanie / logowanie ---
var power_state: PowerState = PowerState.OFF
var user_password: String = ""        # puste = brak hasła (pole hasła niewidoczne)
var power_layer: PowerLayer

# --- Okna i menu ---
var cmd_app: CmdApp
var cmd_window: DraggablePanelContainer
var settings_window: DraggablePanelContainer
var start_button: Button
var search_box: LineEdit
var start_menu: StartMenu
var settings_app: SettingsApp
var password_strength: Dictionary = PasswordStrength.none_result()

var _overlays: Array[Control] = []
var _updating_search: bool = false


func _ready() -> void:
	_setup_desktop()
	_setup_windows()
	_setup_printer_skin()
	_setup_browser_skin()
	_setup_taskbar()
	_setup_power()

	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.autostart = true
	timer.timeout.connect(_on_email_timer_timeout)
	add_child(timer)

	GameManager.time_changed.connect(_on_time_changed)
	GameManager.start_game()


func _process(_delta: float) -> void:
	zegar.text = czas


func _on_time_changed(t: String) -> void:
	czas = t
	if power_layer:
		power_layer.set_clock(t)


func update_cursor_pos():
	mouse_cursor.position = pc_mouse_pos


# Enter: włącza wyłączony komputer, budzi uśpiony, loguje gdy nie ma hasła
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode != KEY_ENTER and event.keycode != KEY_KP_ENTER:
		return
	match power_state:
		PowerState.OFF:
			_run_boot()
		PowerState.SLEEPING:
			_wake_up()
		PowerState.LOGIN:
			if user_password == "":
				_on_login_pressed("")


# =========================================================================
# APLIKACJE: uruchamianie / zamykanie (używa tego menu Start, cmd i ikony)
# =========================================================================

func _app_window(id: StringName) -> Control:
	match id:
		&"browser": return browserWindow
		&"printer": return printerWindow
		&"cmd": return cmd_window
		&"settings": return settings_window
	return null


func launch_app(id: StringName) -> void:
	var win := _app_window(id)
	if win == null:
		return
	if id == &"browser" and not win.visible:
		_on_browser_icon_pressed()   # otwiera i ładuje ostatnią stronę
	win.visible = true
	move_child(win, -1)
	if id == &"cmd":
		cmd_app.focus_input.call_deferred()


# Zwraca true, jeśli aplikacja była otwarta
func close_app(id: StringName) -> bool:
	var win := _app_window(id)
	if win == null or not win.visible:
		return false
	win.visible = false
	return true


func is_app_open(id: StringName) -> bool:
	var win := _app_window(id)
	return win != null and win.visible


# =========================================================================
# OKNA TWORZONE W KODZIE (cmd, ustawienia)
# =========================================================================

func _setup_windows() -> void:
	cmd_app = CmdApp.new()
	cmd_app.pc = self
	var cmd_body := PanelContainer.new()
	var cmd_style := UiStyle.box(Color.BLACK)
	cmd_style.set_content_margin_all(6)
	cmd_body.add_theme_stylebox_override("panel", cmd_style)
	cmd_body.add_child(cmd_app)
	cmd_window = _create_window("CmdWindow", "Wiersz polecenia", Vector2(150, 200), Vector2(660, 420), cmd_body, &"cmd")

	settings_app = SettingsApp.new()
	settings_app.pc = self
	settings_app.username = USER_NAME
	settings_window = _create_window("SettingsWindow", "Ustawienia", Vector2(80, 90), Vector2(860, 600), settings_app, &"settings")


# Okno w tym samym stylu co przeglądarka i drukarka (przesuwane za pasek tytułu)
func _create_window(win_name: String, title: String, win_pos: Vector2, win_size: Vector2,
		body: Control, app_id: StringName) -> DraggablePanelContainer:
	var win := DraggablePanelContainer.new()
	win.name = win_name
	win.visible = false
	win.custom_minimum_size = win_size
	win.position = win_pos
	add_child(win)

	var frame := ColorRect.new()
	frame.color = Color(0.683, 0.683, 0.683)
	win.add_child(frame)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	win.add_child(margin)
	margin.add_child(body)

	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 32)
	bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bar.alignment = BoxContainer.ALIGNMENT_END
	win.add_child(bar)

	var title_label := UiStyle.label("  " + title, 18, Color.BLACK)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(title_label)

	var close_btn := TextureButton.new()
	close_btn.texture_normal = CLOSE_TEX
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_SCALE
	close_btn.custom_minimum_size = Vector2(30, 10)
	close_btn.pressed.connect(close_app.bind(app_id))
	bar.add_child(close_btn)

	return win

# Nowy wygląd okna drukarki (dokłada się do istniejących węzłów, nic nie przenosi)
func _setup_printer_skin() -> void:
	var skin := PrinterSkin.new()
	skin.name = "PrinterSkin"
	printer_gui.add_child(skin)
	printer_gui.move_child(skin, 0)   # pod etykietą i przyciskiem


# Używane do podświetlania strefy upuszczania, gdy plik jest nad oknem drukarki
func is_printer_drop_target(pos: Vector2) -> bool:
	return get_drop_target(pos) == DropTarget.PRINTER

# Nowy wygląd okna przeglądarki (dokłada się do istniejących węzłów, nic nie przenosi)
func _setup_browser_skin() -> void:
	var skin := BrowserSkin.new()
	skin.name = "BrowserSkin"
	browserWindow.add_child(skin)

# =========================================================================
# PASEK ZADAŃ: przycisk Start + wyszukiwarka + menu
# =========================================================================

func _setup_taskbar() -> void:
	var area := HBoxContainer.new()
	area.name = "StartArea"
	area.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	area.add_theme_constant_override("separation", 4)
	taskbar.add_child(area)

	start_button = Button.new()
	start_button.custom_minimum_size = Vector2(56, 0)
	start_button.focus_mode = Control.FOCUS_NONE
	UiStyle.flat_button(start_button, Color(0, 0, 0, 0), Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.26))
	var logo := WinIcon.new()
	logo.kind = WinIcon.Kind.LOGO
	start_button.add_child(logo)
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	area.add_child(start_button)

	search_box = LineEdit.new()
	search_box.custom_minimum_size = Vector2(300, 38)
	search_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	search_box.placeholder_text = "Wpisz tutaj, aby wyszukać"
	search_box.add_theme_font_size_override("font_size", 20)
	search_box.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	search_box.add_theme_color_override("font_placeholder_color", Color(0.4, 0.4, 0.4))
	search_box.add_theme_color_override("caret_color", Color(0.1, 0.1, 0.1))
	var sb := UiStyle.box(Color(0.92, 0.92, 0.94))
	sb.content_margin_left = 12
	sb.content_margin_right = 40
	search_box.add_theme_stylebox_override("normal", sb)
	var sbf := UiStyle.box(Color.WHITE, 0, Color(0.0, 0.47, 0.84), 2)
	sbf.content_margin_left = 12
	sbf.content_margin_right = 40
	search_box.add_theme_stylebox_override("focus", sbf)
	var mag := WinIcon.new()
	mag.kind = WinIcon.Kind.SEARCH
	mag.color = Color(0.2, 0.2, 0.2)
	mag.custom_minimum_size = Vector2(36, 0)
	search_box.add_child(mag)
	mag.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	area.add_child(search_box)

	start_menu = StartMenu.new()
	start_menu.taskbar_ref = taskbar
	start_menu.keep_open.append(start_button)
	start_menu.keep_open.append(search_box)
	add_child(start_menu)
	register_overlay(start_menu)

	start_button.pressed.connect(_toggle_start_menu)
	search_box.text_changed.connect(_on_search_changed)
	search_box.text_submitted.connect(_on_search_submitted)
	search_box.focus_entered.connect(_on_search_focus)
	start_menu.app_chosen.connect(_on_start_app_chosen)
	start_menu.settings_pressed.connect(_on_start_settings)
	start_menu.power_action.connect(power_action)
	start_menu.closed.connect(_on_start_closed)


func _toggle_start_menu() -> void:
	if start_menu.visible:
		start_menu.close()
	else:
		_clear_search()
		start_menu.set_query("")
		start_menu.open()


func _on_search_focus() -> void:
	start_menu.set_query(search_box.text)
	start_menu.open()


func _on_search_changed(text: String) -> void:
	if _updating_search:
		return
	start_menu.set_query(text)
	start_menu.open()


# Enter w wyszukiwarce uruchamia pierwszy (najlepszy) wynik
func _on_search_submitted(text: String) -> void:
	var results := AppRegistry.search(text)
	search_box.release_focus()
	start_menu.close()
	if not results.is_empty():
		launch_app(results[0])


func _on_start_app_chosen(id: StringName) -> void:
	start_menu.close()
	launch_app(id)


func _on_start_settings() -> void:
	start_menu.close()
	launch_app(&"settings")


func _on_start_closed() -> void:
	_clear_search()
	search_box.release_focus()


func _clear_search() -> void:
	_updating_search = true
	search_box.clear()
	_updating_search = false


# =========================================================================
# WARSTWY NA WIERZCHU (menu Start, lista wifi, nakładka zasilania)
# =========================================================================

# Wywołuje to np. lista wifi. Kolejność rejestracji = kolejność od najniższej warstwy.
func register_overlay(c: Control) -> void:
	if not _overlays.has(c):
		_overlays.append(c)
	_keep_overlays_on_top()


# Okna po kliknięciu wskakują na koniec - przywracamy overlaye nad nie.
# Nakładka zasilania zawsze na samym końcu.
func _keep_overlays_on_top() -> void:
	var order: Array = _overlays.duplicate()
	if power_layer:
		order.append(power_layer)
	var first := get_child_count() - order.size()
	var ordered := true
	for i in order.size():
		if order[i].get_parent() != self or order[i].get_index() != first + i:
			ordered = false
			break
	if ordered:
		return
	for c in order:
		if c.get_parent() == self:
			move_child(c, -1)


func _close_menus() -> void:
	for c in _overlays:
		if c is StartMenu:
			(c as StartMenu).close()
		else:
			c.hide()


# =========================================================================
# ZASILANIE: włączanie, logowanie, uśpienie, zamykanie, restart
# =========================================================================

func _setup_power() -> void:
	power_layer = PowerLayer.new()
	power_layer.name = "PowerLayer"
	add_child(power_layer)
	power_layer.set_wallpaper($BG.texture)
	power_layer.set_user_name(USER_NAME)
	power_layer.set_clock(czas)
	power_layer.login_pressed.connect(_on_login_pressed)
	child_order_changed.connect(_keep_overlays_on_top, CONNECT_DEFERRED)
	_keep_overlays_on_top()

	# Na starcie gry komputer jest wyłączony
	power_state = PowerState.OFF
	power_layer.show_black()
	_set_cursor_visible(false)


# Ustawianie hasła. "" = brak hasła. Zapisuje też ocenę siły (password_strength).
func set_user_password(p: String) -> void:
	user_password = p
	password_strength = PasswordStrength.evaluate(p, USER_NAME)   # dla "" zwraca poziom -1


func _set_cursor_visible(v: bool) -> void:
	mouse_cursor.visible = v


# Wywoływane z menu Start i z cmd: &"sleep", &"shutdown", &"restart"
func power_action(action: StringName) -> void:
	if power_state != PowerState.DESKTOP:
		return
	_close_menus()
	get_viewport().gui_release_focus()
	match action:
		&"sleep": _go_sleep()
		&"shutdown": _shutdown(false)
		&"restart": _shutdown(true)


func _run_boot() -> void:
	if power_state != PowerState.OFF and power_state != PowerState.SHUTTING_DOWN:
		return
	power_state = PowerState.BOOTING
	_set_cursor_visible(false)
	power_layer.show_black()
	await get_tree().create_timer(BOOT_BLACK_TIME).timeout
	power_layer.show_boot()
	await get_tree().create_timer(BOOT_TIME).timeout
	power_state = PowerState.LOGIN
	power_layer.show_login(user_password != "")
	_set_cursor_visible(true)


func _on_login_pressed(password: String) -> void:
	if power_state != PowerState.LOGIN:
		return
	if user_password != "" and password != user_password:
		power_layer.show_login_error("Hasło jest nieprawidłowe. Spróbuj ponownie.")
		return
	power_state = PowerState.LOGGING_IN
	_set_cursor_visible(false)
	get_viewport().gui_release_focus()
	power_layer.show_status("Witaj")
	await get_tree().create_timer(WELCOME_TIME).timeout
	_enter_desktop()


func _enter_desktop() -> void:
	power_state = PowerState.DESKTOP
	power_layer.hide_all()
	_set_cursor_visible(true)


func _go_sleep() -> void:
	power_state = PowerState.SLEEPING   # okna zostają otwarte
	power_layer.show_black()
	_set_cursor_visible(false)


func _wake_up() -> void:
	if power_state != PowerState.SLEEPING:
		return
	power_state = PowerState.WAKING
	power_layer.show_wake()
	await get_tree().create_timer(WAKE_TIME).timeout
	_enter_desktop()   # bez logowania


func _shutdown(restart: bool) -> void:
	power_state = PowerState.SHUTTING_DOWN
	_set_cursor_visible(false)
	_close_all_apps()
	power_layer.show_status("Uruchamianie ponownie" if restart else "Zamykanie systemu")
	await get_tree().create_timer(SHUTDOWN_TIME).timeout
	power_layer.show_black()
	if restart:
		await get_tree().create_timer(RESTART_PAUSE).timeout
		_run_boot()
	else:
		power_state = PowerState.OFF


func _close_all_apps() -> void:
	for id in AppRegistry.all_ids():
		close_app(id)
	for w in get_tree().get_nodes_in_group("error_windows"):
		w.queue_free()
	cmd_app.reset()
	settings_app.reset()


# =========================================================================
# PULPIT: ikony i siatka
# =========================================================================

func _setup_desktop() -> void:
	icon_layer = Control.new()
	icon_layer.name = "IconLayer"
	icon_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_layer)
	icon_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	move_child(icon_layer, 1)

	for app in APP_ICONS:
		var icon: DesktopIcon = DESKTOP_FILE_SCENE.instantiate()
		icon.setup(app["kind"], app["id"], app["label"], app["texture"])
		_add_icon(icon, app["cell"])


func _add_icon(icon: DesktopIcon, cell: Vector2i) -> void:
	icon_layer.add_child(icon)
	icon.drag_released.connect(_on_icon_drag_released)
	icon.activated.connect(_on_icon_activated)
	icon.grid_cell = cell
	icon.position = cell_to_pos(cell)


func cell_to_pos(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell) * CELL_SIZE + (CELL_SIZE - ICON_SIZE) / 2.0


func pos_to_cell(pos: Vector2) -> Vector2i:
	var c := Vector2i(((pos - GRID_ORIGIN) / CELL_SIZE).floor())
	return Vector2i(clampi(c.x, 0, GRID_COLS - 1), clampi(c.y, 0, GRID_ROWS - 1))


func _is_cell_taken(cell: Vector2i, ignore: DesktopIcon = null) -> bool:
	for node in icon_layer.get_children():
		var other := node as DesktopIcon
		if other == null or other == ignore or other.is_queued_for_deletion():
			continue
		if other.grid_cell == cell:
			return true
	return false


func _find_free_cell(wanted: Vector2i, ignore: DesktopIcon = null) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist := INF
	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
			var cell := Vector2i(x, y)
			if _is_cell_taken(cell, ignore):
				continue
			var d := Vector2(cell - wanted).length_squared()
			if d < best_dist:
				best_dist = d
				best = cell
	return best


func _snap_icon_to(icon: DesktopIcon, wanted: Vector2i) -> void:
	var cell := _find_free_cell(wanted, icon)
	if cell.x < 0:
		return
	icon.grid_cell = cell
	var tween := create_tween()
	tween.tween_property(icon, "position", cell_to_pos(cell), 0.08).set_trans(Tween.TRANS_SINE)


func spawn_file_on_desktop(file_name: String) -> void:
	var cell := _find_free_cell(FILE_SPAWN_CELL)
	if cell.x < 0:
		return
	var icon: DesktopIcon = DESKTOP_FILE_SCENE.instantiate()
	icon.setup(DesktopIcon.Kind.FILE, StringName(file_name), file_name)
	_add_icon(icon, cell)


func get_desktop_file_count() -> int:
	var n := 0
	for node in icon_layer.get_children():
		var icon := node as DesktopIcon
		if icon and icon.kind == DesktopIcon.Kind.FILE and not icon.is_queued_for_deletion():
			n += 1
	return n


# =========================================================================
# UPUSZCZANIE: gdzie upuszczono i co z tym zrobić
# =========================================================================

func get_drop_target(pos: Vector2) -> DropTarget:
	if not get_tree().get_nodes_in_group("error_windows").is_empty():
		return DropTarget.NONE

	if taskbar.get_global_rect().has_point(pos):
		return DropTarget.NONE

	for i in range(get_child_count() - 1, -1, -1):
		var win := get_child(i) as DraggablePanelContainer
		if win and win.visible and win.get_global_rect().has_point(pos):
			match win.name:
				&"BrowserWindow": return DropTarget.BROWSER
				&"PrinterWindow": return DropTarget.PRINTER
				_: return DropTarget.NONE

	for node in icon_layer.get_children():
		var other := node as DesktopIcon
		if other and other.icon_id == &"trash" and other.get_global_rect().has_point(pos):
			return DropTarget.TRASH

	return DropTarget.DESKTOP


func _on_icon_drag_released(icon: DesktopIcon) -> void:
	var target := get_drop_target(pc_mouse_pos)
	if not DROP_RULES[icon.kind].has(target):
		return

	match target:
		DropTarget.DESKTOP:
			_snap_icon_to(icon, pos_to_cell(pc_mouse_pos))
		DropTarget.TRASH:
			_drop_on_trash(icon)
		DropTarget.PRINTER:
			printer_gui.accept_file(icon.file_name)
		DropTarget.BROWSER:
			_drop_on_browser(icon)


func _drop_on_trash(icon: DesktopIcon) -> void:
	print("Usunięto plik: ", icon.file_name)
	icon.queue_free()


func _drop_on_browser(icon: DesktopIcon) -> void:
	print("Upuszczono ", icon.file_name, " na przeglądarkę")


# Dwuklik na ikonie aplikacji uruchamia ją (id ikony = id w AppRegistry)
func _on_icon_activated(icon: DesktopIcon) -> void:
	if AppRegistry.DEFS.has(icon.icon_id):
		launch_app(icon.icon_id)


# =========================================================================
# OKNA, MAILE, POBIERANIE
# =========================================================================

func _on_browser_icon_pressed() -> void:
	browserWindow.visible = true
	if not browser.current_page_url == "":
		browser._on_url_submitted(browser.current_page_url)


func _on_printer_icon_pressed() -> void:
	printerWindow.visible = true


func _on_close_browser_button_pressed() -> void:
	browserWindow.visible = false


func _on_close_printer_button_pressed() -> void:
	printerWindow.visible = false


func _on_email_timer_timeout() -> void:
	var new_mail = EmailDatabase.get_random_email()
	all_received_emails.push_front(new_mail)
	if is_instance_valid(active_email_app):
		active_email_app.refresh_from_pc(all_received_emails)


func start_file_download(file_name: String) -> void:
	if is_instance_valid(download_window):
		download_window.start_download(file_name, self)
	else:
		print("Błąd: Nie znaleziono DownloadWindow w BrowserWindow!")
