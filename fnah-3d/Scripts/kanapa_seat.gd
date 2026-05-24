extends Area3D

@export var player: CharacterBody3D 

@onready var sit_point = $sit_point
@onready var exit_point = $stand_point

func _ready() -> void:
	# Pamiętaj o przypisaniu gracza w Inspektorze dla każdego Seat1, Seat2 itd.
	# lub użyj automatycznego szukania, jeśli wolisz:
	if not player and has_node("/root/Main/Player"):
		player = get_node("/root/Main/Player")

func interact() -> void:
	if not player:
		return
		
	if player.current_state == player.State.FREE:
		# ZAMIAST get_parent(), przekazujemy 'self' (czyli to konkretne Seat).
		# Dzięki temu gracz wyłączy CollisionShape3D tego konkretnego poduszkowca,
		# w który kliknąłeś, i nic go nie zablokuje przy dolatywaniu do sit_point.
		player.sit_down_on_furniture(self, sit_point, exit_point)