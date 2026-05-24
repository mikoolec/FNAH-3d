extends Node3D

@onready var anim_player = $"AnimationPlayer"

var open: bool = false

func toggle_doors() -> void:
	if anim_player:
		if !open:
			anim_player.play("Open")
		else:
			anim_player.play("Close")
		open = !open