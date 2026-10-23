extends PanelContainer
class_name DraggablePanelContainer
## Okno aplikacji w PC. Klik w dowolne miejsce okna przenosi je na wierzch,
## chwycenie za ramkę (pasek tytułu + obrzeża) przeciąga je.

# Szerokości ramki wokół zawartości (zgodne z MarginContainer okien: 8 / 32 / 8 / 8)
const DEFAULT_MARGINS := Vector4(8, 32, 8, 8)   # lewo, góra, prawo, dół

var dragging := false
var drag_offset := Vector2.ZERO
var is_focused: bool = false


func _ready() -> void:
	# okno schowane w trakcie przeciągania nie może "zostać złapane"
	visibility_changed.connect(func():
		if not visible:
			dragging = false)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not _pointer_in_window(event.position):
				return
			bring_to_front()
			if _in_frame(event.position) and not _over_button():
				dragging = true
		else:
			dragging = false

	elif event is InputEventMouseMotion and dragging:
		position += event.relative
		var viewport_size = get_viewport().size
		position.x = clamp(position.x, 0, viewport_size.x - size.x)
		position.y = clamp(position.y, 0, viewport_size.y - size.y - 50.0)   # 50 = pasek zadań


# Przenosi okno tuż nad najwyższe okno (pod menu, listą wifi i komunikatami błędów)
func bring_to_front() -> void:
	var p := get_parent()
	if p == null:
		return
	var top: Node = null
	for i in range(p.get_child_count() - 1, -1, -1):
		var c := p.get_child(i)
		if c is DraggablePanelContainer:
			top = c
			break
	if top == null or top == self:
		return
	p.move_child(self, top.get_index())


# Czy kursor jest nad TYM oknem (a nie nad inną warstwą leżącą nad nim)?
func _pointer_in_window(pos: Vector2) -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered != null:
		return hovered == self or is_ancestor_of(hovered)
	# awaryjnie (gdy silnik nic nie zwróci): geometria + brak wyższego okna nad punktem
	if not get_global_rect().has_point(pos):
		return false
	var p := get_parent()
	for i in range(get_index() + 1, p.get_child_count()):
		var other := p.get_child(i) as DraggablePanelContainer
		if other and other.visible and other.get_global_rect().has_point(pos):
			return false
	return true


# Ramka = całe okno poza białą zawartością
func _in_frame(pos: Vector2) -> bool:
	var rect := get_global_rect()
	if not rect.has_point(pos):
		return false
	var l := DEFAULT_MARGINS.x
	var t := DEFAULT_MARGINS.y
	var r := DEFAULT_MARGINS.z
	var b := DEFAULT_MARGINS.w
	var m := get_node_or_null("MarginContainer") as MarginContainer
	if m:
		l = m.get_theme_constant("margin_left")
		t = m.get_theme_constant("margin_top")
		r = m.get_theme_constant("margin_right")
		b = m.get_theme_constant("margin_bottom")
	var body := Rect2(rect.position + Vector2(l, t), rect.size - Vector2(l + r, t + b))
	return not body.has_point(pos)


# Kliknięcie w przycisk (np. X) nie ma zaczynać przeciągania okna
func _over_button() -> bool:
	return get_viewport().gui_get_hovered_control() is BaseButton
