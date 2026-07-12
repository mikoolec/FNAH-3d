# ZoneArea3D.gd (skrypt przypisany do obiektów Area3D)
extends Area3D

func _ready() -> void:
	# Podłączamy sygnały automatycznie w kodzie, 
	# żeby nie klikać tego ręcznie dla każdej strefy w edytorze
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		GameplayNumbers.active_ladder_zones += 1
		print("Gracz wszedł do strefy. Suma stref: ", GameplayNumbers.active_ladder_zones)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		GameplayNumbers.active_ladder_zones -= 1
		print("Gracz wyszedł ze strefy. Suma stref: ", GameplayNumbers.active_ladder_zones)
