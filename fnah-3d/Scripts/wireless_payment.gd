extends Area3D

func interact(player = null) -> void:
	# Przekazuje wywołanie do rodzica (glównego Node3D)
	print("mony in")
	if get_parent().has_method("wireless_pay") and GameplayNumbers.phone_transaction > 0.0:
		get_parent().wireless_pay()
		print("mony up")
