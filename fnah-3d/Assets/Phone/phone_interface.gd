extends Control

@onready var sub_viewport: SubViewport = $PhonePanel/ScreenViewportContainer/ScreenViewport

func _ready() -> void:
	# Upewniamy się, że interfejs w CanvasLayer jest widoczny w tle,
	# aby SubViewport mógł wyrenderować ekran dla modelu 3D
	visible = true

# Funkcja przekazująca wyrenderowaną teksturę do PhoneModel.gd
func get_screen_texture() -> ViewportTexture:
	return sub_viewport.get_texture()

func _input(event: InputEvent) -> void:
	# Przekazujemy ruchy i kliknięcia myszy bezpośrednio do wnętrza SubViewport
	if event is InputEventMouse:
		# Pobieramy pozycję myszy względem kontenera ekranu telefonu
		var viewport_container = $PhonePanel/ScreenViewportContainer
		var local_pos = viewport_container.get_local_mouse_override() if viewport_container.has_method("get_local_mouse_override") else viewport_container.get_local_mouse_position()
		
		# Tworzymy kopię zdarzenia i przypisujemy jej pozycję wewnątrz SubViewport
		var cloned_event = event.duplicate()
		cloned_event.position = local_pos
		cloned_event.global_position = local_pos
		
		# Wszywamy zdarzenie do wnętrza widoku SubViewport
		sub_viewport.push_input(cloned_event)
