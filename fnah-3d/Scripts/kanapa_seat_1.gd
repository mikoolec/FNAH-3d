extends Area3D

@export var player: CharacterBody3D 

@onready var sit_point = $sit_point
@onready var exit_point = $stand_point # Łapiemy nasz nowy punkt wyjścia

func interact():
	if not player:
		return
		
	if player.current_state == player.State.FREE:
		# Przekazujemy teraz TRZY rzeczy: mebel, punkt siadania i punkt wstawania
		player.sit_down_on_furniture(get_parent(), sit_point, exit_point)