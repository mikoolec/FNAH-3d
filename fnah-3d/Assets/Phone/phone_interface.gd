extends Control

@onready var sub_viewport: SubViewport = $PhonePanel/ScreenViewportContainer/ScreenViewport

func _ready() -> void:
	# Upewniamy się, że interfejs w CanvasLayer jest widoczny w tle,
	# aby SubViewport mógł wyrenderować ekran dla modelu 3D
	visible = true

# Funkcja przekazująca wyrenderowaną teksturę do PhoneModel.gd
func get_screen_texture() -> ViewportTexture:
	return sub_viewport.get_texture()
