extends Node3D

@onready var view_point = $view_point
@onready var player = $"../Player"
@onready var subview = $PC/SubViewport
@onready var pc_control: Control = $PC/SubViewport/PCControl

# Tu przechowujemy strukturę na stałe przez całą grę
var sharepoint_data = {}

# Banki nazw przeniesione ze skryptu strony:
const FOLDER_NAMES = ["Projekty_2026", "Finanse_Q2", "Tajne", "HR_Rekrutacja", "Logistyka", "Backup_System", "Raporty", "Klienci_VIP"]
const SUBFOLDER_NAMES = ["Archiwum", "Do_Sprawdzenia", "Wykresy", "Prywatne", "Instrukcje", "Dokumentacja"]
const FILE_NAMES = ["faktura", "umowa", "dane_logowania", "notatki", "specyfikacja", "harmonogram"]
const EXTENSIONS = [".pdf", ".docx", ".xlsx", ".txt"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#player = get_tree().get_first_node_in_group("player")
	generate_global_sharepoint()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func interact():
	if !player.is_using_computer:
		player.enter_computer()

func _input(event: InputEvent) -> void:
	if !player.is_using_computer: return
	
	if event is InputEventKey:
		if Input.is_action_just_pressed("escape"): player.exit_computer()
		else: subview.push_input(event)
	elif event is InputEventMouseButton:
		#Forward left and middle mouse button events to subviewport
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_event = InputEventMouseButton.new()
			mouse_event.button_index = event.button_index
			mouse_event.pressed = event.pressed
			mouse_event.position = pc_control.pc_mouse_pos
			mouse_event.global_position = pc_control.pc_mouse_pos
			
			subview.push_input(mouse_event)
	elif event is InputEventMouseMotion:
		pc_control.pc_mouse_pos += event.relative
		pc_control.pc_mouse_pos.x = clamp(pc_control.pc_mouse_pos.x, 0.0, subview.size.x - 10.0)
		pc_control.pc_mouse_pos.y = clamp(pc_control.pc_mouse_pos.y, 0.0, subview.size.y - 10.0)
		pc_control.update_cursor_pos()

		var motion_event = InputEventMouseMotion.new()

		motion_event.position = pc_control.pc_mouse_pos
		motion_event.global_position = pc_control.pc_mouse_pos
		motion_event.button_mask = Input.get_mouse_button_mask()
		motion_event.relative = event.relative

		subview.push_input(motion_event)

func generate_global_sharepoint() -> void:
	var pool_folders = FOLDER_NAMES.duplicate()
	pool_folders.shuffle()
	
	var num_main_folders = randi_range(6, 10)
	for i in range(num_main_folders):
		if pool_folders.is_empty(): break
		var f_name = pool_folders.pop_back()
		
		sharepoint_data[f_name] = {
			"type": "folder",
			"contents": {}
		}
		
		var pool_subs = SUBFOLDER_NAMES.duplicate()
		pool_subs.shuffle()
		var num_subs = randi_range(3, 6)
		for j in range(num_subs):
			var sub_name = pool_subs.pop_back()
			
			sharepoint_data[f_name]["contents"][sub_name] = {
				"type": "folder",
				"contents": {}
			}
			
			var num_files = randi_range(1, 5)
			var pool_files = FILE_NAMES.duplicate()
			pool_files.shuffle()
			for k in range(num_files):
				var file_title = pool_files.pop_back() if not pool_files.is_empty() else "plik_" + str(k)
				var file_name = file_title + EXTENSIONS.pick_random()
				
				sharepoint_data[f_name]["contents"][sub_name]["contents"][file_name] = {
					"type": "file"
				}
	print("SharePoint pomyślnie wygenerowany na starcie gry!")
