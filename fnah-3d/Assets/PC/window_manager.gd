extends Node

const ERROR_WINDOW_SCENE = preload("res://Assets/PC/ErrorWindow.tscn")

func spawn_error(text: String, use_yes_no: bool = false, count: int = 1) -> void:
	var pc_control = get_tree().root.find_child("PCControl", true, false)
	
	if not pc_control:
		return
		
	for i in range(count):
		var window_instance = ERROR_WINDOW_SCENE.instantiate()
		pc_control.add_child(window_instance)
		pc_control.move_child(window_instance, -1)
		
		# Cała tarcza ustawia się na pełny ekran
		window_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		window_instance.setup(text, use_yes_no)
		
		# Pobieramy nasze wewnętrzne okienko
		var panel = window_instance.get_node_or_null("WindowPanel")
		
		if panel:
			# Domyślnie dajemy je na środek ekranu
			panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			
			# Jeśli jest więcej niż 1 okienko, przesuwamy SAM PANEL (nie całą tarczę)
			if count > 1:
				var random_offset = Vector2(randf_range(-120, 120), randf_range(-120, 120))
				panel.position += random_offset
