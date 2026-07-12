# Global.gd
extends Node

# Zmienna dostępna z każdego miejsca w projekcie
var active_ladder_zones: int = 0

func is_player_in_any_zone() -> bool:
	return active_ladder_zones > 0

func reset_zones() -> void:
	active_ladder_zones = 0
