extends Node

const ERROR_WINDOW_SCENE = preload("res://Assets/PC/ErrorWindow.tscn")

func spawn_error(text: String, use_yes_no: bool = false, randomize_position: bool = true) -> bool:
	var pc_control = get_tree().root.find_child("PCControl", true, false)
	
	if not pc_control:
		return false
		
	var window_instance = ERROR_WINDOW_SCENE.instantiate()
	pc_control.add_child(window_instance)
	pc_control.move_child(window_instance, -1)
	
	# Rozciągamy tło blokujące na cały ekran
	window_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window_instance.setup(text, use_yes_no)
	
	var panel = window_instance.get_node_or_null("WindowPanel")
	if panel:
		# Jeśli włączone jest losowanie pozycji, dodajemy losowy offset od środka
		if randomize_position:
			var random_offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
			panel.position += random_offset

	# Czekamy na odpowiedź z okna
	var result: bool = await window_instance.confirmed
	return result

# Funkcja generująca kaskadę okienek (efekt mętliku/wirusa)
# text - treść błędu
# count - łączna liczba okienek do stworzenia (np. 30)
# delay - odstęp czasowy między pojawianiem się kolejnych okienek (0.0 = natychmiast)
func spawn_window_cascade(text: String, count: int = 25, delay: float = 0.03) -> void:
	var pc_control = get_tree().root.find_child("PCControl", true, false)
	
	if not pc_control:
		print("Błąd: Nie znaleziono pulpitu PCControl!")
		return
		
	# Pobieramy wymiary ekranu komputera
	var screen_size = pc_control.size
	
	# Punkty startowe (lewy górny róg)
	var start_x: float = 20.0
	var start_y: float = 20.0
	
	# Krok przesunięcia dla każdego kolejnego okienka (w dół i w prawo)
	var step_x: float = 25.0
	var step_y: float = 25.0
	
	# Aktualne współrzędne dla nowego okienka
	var current_x = start_x
	var current_y = start_y
	
	for i in range(count):
		var window_instance = ERROR_WINDOW_SCENE.instantiate()
		
		# Dodajemy do ekranu i na sam wierzch
		pc_control.add_child(window_instance)
		pc_control.move_child(window_instance, -1)
		
		# Wymuszamy rozmiar tarczy blokującej na pełny ekran
		window_instance.size = screen_size
		window_instance.position = Vector2.ZERO
		
		# Ustawiamy tekst błędu (zwykłe "OK")
		window_instance.setup(text, false)
		
		var panel = window_instance.get_node_or_null("WindowPanel")
		if panel:
			# Ustawiamy pozycję panelu na wyliczone współrzędne kaskady
			panel.position = Vector2(current_x, current_y)
			
			# Pobieramy rozmiar okienka (jeśli silnik go jeszcze nie ustalił, dajemy szacowany)
			var panel_width = panel.size.x if panel.size.x > 0 else 300.0
			var panel_height = panel.size.y if panel.size.y > 0 else 180.0
			
			# Przesuwamy pozycję dla KOLEJNEGO okienka
			current_x += step_x
			current_y += step_y
			
			# WARUNEK RESTU: Jeśli okienko wyjdzie poza dolną lub prawą krawędź ekranu
			if (current_y + panel_height > screen_size.y - 40.0) or (current_x + panel_width > screen_size.x - 40.0):
				# Zaczynamy nowy rząd przesunięty lekko w prawo od pierwszego startu
				start_x += 60.0
				
				# Jeśli nowa kolumna też wyszłaby poza ekran w prawo, wracamy na sam początek
				if start_x > screen_size.x - panel_width:
					start_x = 20.0
					
				current_x = start_x
				current_y = start_y
		
		# Jeśli podano opóźnienie, czekamy przed zespawnowaniem kolejnego okna
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
