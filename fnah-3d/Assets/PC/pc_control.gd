extends Control
@onready var mouse_cursor:Sprite2D = $MouseCursor
@onready var browserWindow = $BrowserWindow
@onready var printerWindow = $PrinterWindow
var pc_mouse_pos:Vector2 = Vector2(512, 512)

@export var panel_windows:Array[DraggablePanelContainer]

const DESKTOP_FILE_SCENE = preload("res://Assets/PC/Aplikacje/Ikony/desktop_file.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

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
