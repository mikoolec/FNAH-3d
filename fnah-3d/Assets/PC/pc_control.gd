extends Control
@onready var mouse_cursor:Sprite2D = $MouseCursor
@onready var browserWindow = $BrowserWindow
@onready var printerWindow = $PrinterWindow
@onready var download_window: PanelContainer = $BrowserWindow/DownloadWindow
var pc_mouse_pos:Vector2 = Vector2(512, 512)

@export var panel_windows:Array[DraggablePanelContainer]

const DESKTOP_FILE_SCENE = preload("res://Assets/PC/Aplikacje/Ikony/desktop_file.tscn")

# Centralny magazyn maili na pulpicie (istnieje zawsze)
var all_received_emails: Array = []

# Referencja do instancji aplikacji (gdy jest otwarta, ma wartość. Gdy zamknięta = null)
var active_email_app: Control = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Przykładowy stoper generujący maile
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.autostart = true
	timer.timeout.connect(_on_email_timer_timeout)
	add_child(timer)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_cursor_pos():
	mouse_cursor.position = pc_mouse_pos



func spawn_file_on_desktop(file_name: String) -> void:
	var new_file = DESKTOP_FILE_SCENE.instantiate()
	new_file.set_file_data(file_name)
	
	# Dodaj plik do kontenera na pulpicie (np. do GridContainera, jeśli ikony się układają w siatkę)
	$GridContainer.add_child(new_file)


func _on_browser_icon_pressed() -> void:
	browserWindow.visible = true

func _on_printer_icon_pressed() -> void:
	printerWindow.visible = true


func _on_close_browser_button_pressed() -> void:
	browserWindow.visible = false

func _on_close_printer_button_pressed() -> void:
	printerWindow.visible = false

func _on_email_timer_timeout() -> void:
	# 1. Losujemy maila z bazy (do stałej pamięci pulpitu)
	var new_mail = EmailDatabase.get_random_email()
	all_received_emails.push_front(new_mail)
	#print("Nowy mail przyszedł na serwer komputera!")
	
	# 2. Jeśli aplikacja mailowa jest AKTUALNIE OTWARTA, natychmiast ją odświeżamy
	if is_instance_valid(active_email_app):
		active_email_app.refresh_from_pc(all_received_emails)

func start_file_download(file_name: String) -> void:
	if is_instance_valid(download_window):
		# Pokazujemy okno i odpalamy pobieranie, przekazując pulpit (self) do stworzenia pliku na końcu
		download_window.start_download(file_name, self)
	else:
		print("Błąd: Nie znaleziono DownloadWindow w BrowserWindow!")
