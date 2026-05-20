extends Control
@onready var mouse_cursor:Sprite2D = $MouseCursor
@onready var browserWindow = $BrowserWindow
@onready var printerWindow = $PrinterWindow
var pc_mouse_pos:Vector2 = Vector2(512, 512)

@export var panel_windows:Array[DraggablePanelContainer]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_cursor_pos():
	mouse_cursor.position = pc_mouse_pos


func _on_browser_icon_pressed() -> void:
	browserWindow.visible = true

func _on_printer_icon_pressed() -> void:
	printerWindow.visible = true


func _on_close_browser_button_pressed() -> void:
	browserWindow.visible = false

func _on_close_printer_button_pressed() -> void:
	printerWindow.visible = false
