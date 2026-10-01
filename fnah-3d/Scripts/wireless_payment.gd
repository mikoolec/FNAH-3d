extends Area3D

@onready var pay_punkt: Node3D = $pay_punkt

func interact(player = null) -> void:
	# Przekazuje wywołanie do rodzica (glównego Node3D)
	print("mony in")
	if get_parent().has_method("wireless_pay") and GameplayNumbers.phone_transaction > 0.0:
		get_parent().player.pay_wireless(pay_punkt)
		
		await get_tree().create_timer(0.45).timeout
		
		get_parent().wireless_pay()
		
		print("mony up")
