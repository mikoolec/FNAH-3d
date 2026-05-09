extends Node3D

@onready var view_point = $view_point
@onready var player = $"../Player"
@onready var subview = $PC/SubViewport
@onready var pc_control: Control = $PC/SubViewport/PCControl
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#player = get_tree().get_first_node_in_group("player")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func interact():
	if !player.is_using_computer:
		player.enter_computer()

func _input(event: InputEvent) -> void:
	if !player.is_using_computer: return
	
	if event is InputEventKey:
		if Input.is_action_just_pressed("escape"): player.exit_computer()
		else: subview.push_input(event)
	elif event is InputEventMouseMotion:
		pc_control.pc_mouse_pos += event.relative
		pc_control.pc_mouse_pos.x = clamp(pc_control.pc_mouse_pos.x, 0.0, subview.size.x - 10.0)
		pc_control.pc_mouse_pos.y = clamp(pc_control.pc_mouse_pos.y, 0.0, subview.size.y - 10.0)
		pc_control.update_cursor_pos()
