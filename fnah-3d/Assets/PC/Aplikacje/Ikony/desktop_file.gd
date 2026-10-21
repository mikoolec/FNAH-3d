extends VBoxContainer
class_name DesktopIcon

enum Kind { FILE, APP, SYSTEM }   # FILE = dokument, APP = aplikacja, SYSTEM = np. kosz

signal activated(icon: DesktopIcon)      # dwuklik
signal drag_released(icon: DesktopIcon)  # puszczono przeciąganą ikonę

const DOUBLE_CLICK_MS := 400

@onready var icon_texture: TextureRect = $IconTexture

var kind: Kind = Kind.FILE
var icon_id: StringName = &""
var file_name: String = ""
var grid_cell: Vector2i = Vector2i(-1, -1)

var _dragging: bool = false
var _last_click_ms: int = -10000


# Wywołuj przed lub po add_child - działa w obu przypadkach.
func setup(p_kind: Kind, p_id: StringName, p_label: String, p_texture: Texture2D = null) -> void:
	kind = p_kind
	icon_id = p_id
	if kind == Kind.FILE:
		file_name = p_label
	$FileNameLabel.text = p_label
	if p_texture:
		$IconTexture.texture = p_texture


func _gui_input(event: InputEvent) -> void:
	# push_input z PC.gd nie ustawia double_click, więc mierzymy czas sami
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var now := Time.get_ticks_msec()
		if now - _last_click_ms <= DOUBLE_CLICK_MS:
			_last_click_ms = -10000
			activated.emit(self)
		else:
			_last_click_ms = now


func _get_drag_data(_at_position: Vector2) -> Variant:
	_dragging = true
	modulate.a = 0.4   # oryginał blednie, jak w Windows

	var preview := VBoxContainer.new()
	var preview_texture := TextureRect.new()
	preview_texture.texture = icon_texture.texture
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture.custom_minimum_size = Vector2(60, 60)
	preview.add_child(preview_texture)

	var preview_label := Label.new()
	preview_label.text = $FileNameLabel.text
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(preview_label)

	preview.modulate.a = 0.6
	preview.top_level = true
	set_drag_preview(preview)

	return {
		"type": "desktop_icon",
		"kind": kind,
		"id": icon_id,
		"file_name": file_name,
		"node": self,
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0
		if _dragging:
			_dragging = false
			drag_released.emit(self)
