extends Control
class_name WinToggle
## Przełącznik jak w Windows 10 (Wł./Wył.)

signal toggled(on: bool)

const COL_ON := Color(0.0, 0.47, 0.84)
const COL_OFF := Color(0.3, 0.3, 0.33)

@export var on: bool = false:
	set(value):
		on = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(48, 24)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		on = not on
		toggled.emit(on)
		accept_event()


func _draw() -> void:
	var r := size.y / 2.0
	var track := StyleBoxFlat.new()
	track.set_corner_radius_all(int(r))
	if on:
		track.bg_color = COL_ON
	else:
		track.bg_color = Color(0, 0, 0, 0)
		track.border_color = COL_OFF
		track.set_border_width_all(2)
	draw_style_box(track, Rect2(Vector2.ZERO, size))
	var x := size.x - r if on else r
	draw_circle(Vector2(x, r), r * 0.5, Color.WHITE if on else COL_OFF)
