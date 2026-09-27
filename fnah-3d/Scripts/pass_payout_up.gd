extends Area3D

func interact(player = null) -> void:
	# Przekazuje wywołanie do rodzica (glównego Node3D)
	print("mony out")
	if get_parent().has_method("payout"):
		get_parent().payout()
		print("mony bum")
