extends AnimatableBody3D

@onready var animPlayer = $"../../../../AnimationPlayer"

var open:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_as_top_level(false)

func _physics_process(delta: float) -> void:
	global_transform = get_parent().global_transform

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func interact():
	if !open: animPlayer.play("Open Door")
	else: animPlayer.play("Close Door")
	open = !open
