extends Area3D

func _physics_process(_delta: float) -> void:
	# Pobieramy listę wszystkich obiektów, które aktualnie stoją w strefie
	var bodies = get_overlapping_bodies()
	
	for body in bodies:
		# Sprawdzamy czy to gracz i czy właśnie sprintuje
		if "speed" in body and body.speed == body.SPRINT_SPEED:
			if body.has_method("start_ragdoll") and not body.walk_locked:
				body.start_ragdoll()
