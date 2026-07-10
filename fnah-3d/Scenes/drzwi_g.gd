extends Node3D

@onready var anim_player = $"AnimationPlayer"

var open: bool = false

func _ready() -> void:
	if anim_player:
		anim_player.play("Close");

func toggle_doors() -> void:
	if anim_player:
		if ( !anim_player.is_playing() ):
			if !open:
				anim_player.play("Open")
			else:
				anim_player.play("Close")
			open = !open
