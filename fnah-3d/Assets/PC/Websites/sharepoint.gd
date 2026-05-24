extends Control

# Referencje do UI
@onready var login_panel: PanelContainer = $LoginPanel
@onready var main_panel: PanelContainer = $MainPanel
@onready var code_input: LineEdit = $LoginPanel/VBoxContainer/CodeInput
@onready var error_label: Label = $LoginPanel/VBoxContainer/ErrorLabel
@onready var items_container: VBoxContainer = $MainPanel/VBoxContainer/ItemsContainer
@onready var path_label: Label = $MainPanel/VBoxContainer/PathLabel
@onready var back_button: Button = $MainPanel/VBoxContainer/BackButton

@onready var downloadWindow = $DownloadWindow
@onready var pc = get_node("../../../../..")

# Słownik przechowujący wygenerowaną strukturę danych internetu
var file_system = {}
var current_dir = null
var directory_stack = [] # Historia przeglądania do przycisku "Wstecz"

func _ready() -> void:
	# Ukrywamy panel główny, pokazujemy logowanie
	login_panel.show()
	main_panel.hide()
	error_label.text = ""
	back_button.pressed.connect(_on_back_pressed)
	
	# Podłączenie przycisku logowania
	$LoginPanel/VBoxContainer/LoginButton.pressed.connect(_on_login_attempt)
	
	var komputer = get_node_or_null("/root/model_harcowka/PC") 
	if komputer and "sharepoint_data" in komputer:
		file_system = komputer.sharepoint_data
	else:
		# Awaryjny system na wypadek testowania samej sceny sharepoint
		file_system = {"Brak danych": {"type": "folder", "contents": {}}}

# --- LOGIKA LOGOWANIA ---
func _on_login_attempt() -> void:
	# Przykładowy kod z telefonu, np. "1234"
	if code_input.text == "1234":
		login_panel.hide()
		main_panel.show()
		open_directory(file_system, "Root")
	else:
		error_label.text = "Niepoprawny kod MFA. Spróbuj ponownie."


# --- LOGIKA PRZEGLĄDANIA ---
func open_directory(dir_data: Dictionary, dir_name: String) -> void:
	# Czyścimy starą listę plików/folderów z ekranu
	for child in items_container.get_children():
		child.queue_free()
		
	current_dir = dir_data
	
	# POPRAWKA 1: Zawsze budujemy czysty tekst od zera, bez względu na to, czy wchodzimy, czy się cofamy
	path_label.text = "Lokalizacja: " + dir_name
	
	# Kontrola widoczności przycisku wstecz (ukryty tylko w głównym Root)
	back_button.visible = (dir_name != "Root")
	
	# Sprawdzamy strukturę w zależności od tego, czy to Root
	var items = dir_data if dir_name == "Root" else dir_data.get("contents", {})
	
	for item_key in items.keys():
		var item = items[item_key]
		
		var hbox = HBoxContainer.new()
		items_container.add_child(hbox)
		
		if item["type"] == "folder":
			var btn = Button.new()
			btn.text = "📁 " + item_key
			btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			btn.pressed.connect(func():
				# POPRAWKA 2: Do historii zapisujemy tylko czystą nazwę folderu (dir_name), a nie cały tekst z "Lokalizacja: ..."
				directory_stack.append([current_dir, dir_name])
				open_directory(item, dir_name + " / " + item_key)
			)
			hbox.add_child(btn)
			
		elif item["type"] == "file":
			var label = Label.new()
			label.text = "📄 " + item_key
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(label)
			
			var dl_btn = Button.new()
			dl_btn.text = "Pobierz"
			dl_btn.pressed.connect(func():
				_on_file_downloaded(item_key)
			)
			hbox.add_child(dl_btn)

func _on_back_pressed() -> void:
	if not directory_stack.is_empty():
		var previous = directory_stack.pop_back()
		# previous[0] to słownik folderu, previous[1] to jego czysta nazwa (np. "Root" lub "Root / Projekty")
		open_directory(previous[0], previous[1])

#func _on_file_downloaded(file_name: String) -> void:
	#print("Pobrano plik: ", file_name)
	#downloadWindow.start_download(file_name, pc)
	
func _on_file_downloaded(file_name: String) -> void:
	# Odpalamy funkcję
	downloadWindow.start_download(file_name, pc)
	# Tutaj możesz dodać kod gry, np. dodanie przedmiotu do ekwipunku gracza:
	# Ekwipunek.dodaj_plik(file_name)
