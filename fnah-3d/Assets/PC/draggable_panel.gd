extends PanelContainer
class_name DraggablePanelContainer

var dragging := false
var drag_offset := Vector2.ZERO

var is_focused: bool = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		'''for x in get_parent().panel_windows:
			if x != self:
				x.z_index = 0
				x.is_focused = false
		self.z_index = 1
		is_focused = true'''
		get_parent().move_child(self, get_parent().get_child_count())
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = event.position
		else:
			dragging = false

	elif event is InputEventMouseMotion and dragging:
		position += event.relative

		# Clamp to viewport bounds
		var viewport_size = get_viewport().size
		position.x = clamp(position.x, 0, viewport_size.x - size.x)
		position.y = clamp(position.y, 0, viewport_size.y - size.y - 50.0)
