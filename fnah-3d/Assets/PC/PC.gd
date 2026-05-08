extends Node3D

@onready var view_point = $view_point
@onready var player = $"../Player"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func interact():
	if !player.is_using_computer:
		player.enter_computer()

func interact2():
	if player.is_using_computer:
		player.exit_computer()
