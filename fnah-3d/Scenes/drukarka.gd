extends StaticBody3D

@onready var drukarka = $"."
@onready var mesh = $printer
@onready var anim_player = $printer/AnimationPlayer

var kartkaIn:bool = false
var kartkaSave:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim_player.play("Use")
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if kartkaIn and !kartkaSave:
		kartkaSave = true
		anim_player.play("Load")
	elif !kartkaIn and kartkaSave:
		kartkaSave = false
		anim_player.play("Use")
