extends Area3D

func interact(player = null) -> void:
	# Przekazuje wywołanie do rodzica (glównego Node3D)
	if get_parent().has_method("interact"):
		get_parent().interact()
