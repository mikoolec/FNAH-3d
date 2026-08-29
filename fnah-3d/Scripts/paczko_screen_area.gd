extends Area3D

# Referencje dla mechaniki wejścia w panel
@export var view_point: Node3D
@export var main_area_collision: CollisionShape3D # InteractCollision

# NOWA ZMIENNA: Główna kolizja całego modelu paczkomatu (StaticBody3D)
@export var static_body_collision: CollisionShape3D 

# Referencje dla mechaniki klikania po UI
@export var screen_area: Area3D           
@export var viewport: SubViewport         
@export var screen_mesh: MeshInstance3D   

# Używamy settera, aby wykryć, kiedy gracz wciska ESC i wychodzi
var is_player_focused: bool = false:
	set(value):
		is_player_focused = value
		# Kiedy skrypt gracza zdejmuje focus (ustawia na false), włączamy z powrotem kolizję paczkomatu
		if not value and static_body_collision:
			static_body_collision.set_deferred("disabled", false)

var is_cover_open: bool = false 
var player_ref: CharacterBody3D = null

func _ready() -> void:
	player_ref = get_tree().get_first_node_in_group("Player")
	
	if screen_area:
		screen_area.input_event.connect(_on_screen_input_event)

func interact() -> void:
	if is_player_focused:
		return
	focus_player()

func focus_player() -> void:
	if not player_ref or not player_ref.has_method("enter_panel"):
		return
		
	# To odpali nasz setter, ale ponieważ to true, zignoruje włączanie kolizji
	is_player_focused = true 
	
	if main_area_collision:
		main_area_collision.set_deferred("disabled", true)
		
	# Wyłączamy główną kolizję bryły, aby nie zasłaniała myszki
	if static_body_collision:
		static_body_collision.set_deferred("disabled", true)
		
	player_ref.enter_panel(self)

func _on_screen_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not is_player_focused:
		return

	if event is InputEventMouse:
		var local_pos = screen_mesh.global_transform.affine_inverse() * event_position
		var mesh_size = screen_mesh.mesh.size
		
		var percent_x = (local_pos.x + (mesh_size.x / 2.0)) / mesh_size.x
		var percent_y = ((mesh_size.y / 2.0) - local_pos.y) / mesh_size.y
		
		var viewport_pos = Vector2(percent_x * viewport.size.x, percent_y * viewport.size.y)
		
		var ev2d = event.duplicate()
		ev2d.position = viewport_pos
		ev2d.global_position = viewport_pos
		
		viewport.push_input(ev2d)
