extends StaticBody3D

@onready var player = $"../Player"
@onready var sit_point = $SitPoint

func interact():
	if player.current_state == player.State.FREE:
		player.sit_down()
	else:
		player.stand_up()
