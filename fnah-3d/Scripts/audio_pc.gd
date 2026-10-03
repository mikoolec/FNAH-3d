extends AudioStreamPlayer3D

# Podaj ścieżkę do Gracza lub Kamery (np. %Player lub %Camera3D)
@export var listener: Node3D 

# Głośność gdy dźwięk jest otwarty (w dB) oraz gdy zasłonięty ścianą
@export var normal_db: float = 0.0
@export var muffled_db: float = -12.0

func _process(_delta: float) -> void:
	if not playing or not listener:
		return
		
	# Tworzymy bezpośrednie zapytanie fizyczne (Raycast) z pozycji dźwięku do gracza
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, listener.global_position)
	
	# Możesz dodać wyjątek, aby promień nie trafiał w samego gracza/komputer
	query.exclude = [self] 
	
	var result = space_state.intersect_ray(query)

	# Jeśli promień w coś trafił przed dotarciem do gracza = na drodze stoi ściana
	if result:
		# Tłumimy dźwięk (zmniejszamy głośność)
		volume_db = lerp(volume_db, muffled_db, 0.1)
		
		# Opcjonalnie: Jeśli używasz efektu LowPassFilter na Busie 1
		# AudioServer.set_bus_effect_enabled(1, 0, true) 
	else:
		# Dźwięk wraca do normy (brak przeszkód)
		volume_db = lerp(volume_db, normal_db, 0.1)
		
		# AudioServer.set_bus_effect_enabled(1, 0, false)
