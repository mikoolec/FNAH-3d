extends AnimatableBody3D

@onready var core = $"../../../.." 

func _ready() -> void:
	set_as_top_level(false)

func _physics_process(_delta: float) -> void:
	global_transform = get_parent().global_transform

func interact() -> void:
	if core and core.has_method("toggle_doors"):
		core.toggle_doors()