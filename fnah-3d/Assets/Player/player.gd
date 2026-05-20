extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5

const SENSITIVITY = 0.01

var gravity = 20

#bob variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

var camOffset = PI/2

enum State { FREE, SITTING, TRANSITION }
var current_state = State.FREE
var walk_locked:bool = false
var camera_locked:bool = false

var is_using_computer = false

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var chair = $"../Chair"
@onready var computer = $"../PC"
@onready var collision_shape_chair: CollisionShape3D = $CollisionShape3D
var current_furniture: Node3D = null
var current_sit_point: Node3D = null
var current_exit_point: Node3D = null


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if !camera_locked:
			head.rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-70), deg_to_rad(60))
	
	if current_state == State.SITTING and event.is_action_pressed("jump"):
		stand_up()

func _physics_process(delta: float) -> void:
	%InteractText.hide()
	%Interact2Text.hide()
	if %SeeCast.is_colliding() and !is_using_computer:
		var target = %SeeCast.get_collider()
		if target.has_method("interact"):
			if target == computer:
				if current_state == State.SITTING:	
					%InteractText.show()
					if Input.is_action_just_pressed("interact"):
						target.interact()
			else:
				%InteractText.show()
				if Input.is_action_just_pressed("interact"):
					target.interact()
		if target.has_method("interact2"):
			%Interact2Text.show()
			if Input.is_action_just_pressed("interact2"):
				target.interact2()
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
		#  WSTAW TO:
	match current_state:
		State.SITTING:
			# Obracamy mebel tylko, jeśli nazywa się "Chair" (Twoje obrotowe krzesło)
			if current_furniture and current_furniture.name == "Chair":
				current_furniture.global_rotation.y = $Head.global_rotation.y - camOffset
		State.TRANSITION:
			pass

	if walk_locked:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle sprint.
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction : Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	# Head bob
	t_bob += delta * velocity. length() * float(is_on_floor())
	camera. transform.origin =_headbob(t_bob)

	move_and_slide()

func _headbob (time) -> Vector3:
	var pos = Vector3. ZERO
	pos.y = sin (time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func sit_down_on_furniture(furniture_node: Node3D, target_sit_point: Node3D, target_exit_point: Node3D = null):
	current_state = State.TRANSITION
	walk_locked = true
	
	# Zapamiętujemy mebel i dokładne miejsce siedzenia
	current_furniture = furniture_node
	current_sit_point = target_sit_point
	current_exit_point = target_exit_point
	
	# Wyłączamy kolizje gracza
	$CollisionShape3D.disabled = true
	
	# Jeśli mebel ma swoją własną kolizję główną, też ją wyłączamy, żeby nie było błędów fizyki
	if current_furniture.has_node("CollisionShape3D"):
		current_furniture.get_node("CollisionShape3D").disabled = true
	
	var start_rot_y = $Head.global_rotation.y
	# Obracamy głowę w stronę, w którą patrzy mebel
	var target_rot_y = current_sit_point.global_rotation.y + deg_to_rad(180)

	var tween = create_tween().set_parallel(true)

	# Płynnie przesuwamy gracza do wybranego sit_pointu (działa dla krzesła i każdego punktu kanapy)
	tween.tween_property(self, "global_position", current_sit_point.global_position, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Płynna rotacja głowy gracza
	tween.tween_method(
		func(value: float):
			$Head.global_rotation.y = lerp_angle(start_rot_y, target_rot_y, value),
		0.0, 1.0, 0.5
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Prostowanie wzroku kamery
	tween.tween_property($Head/Camera3D, "rotation:x", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	
	tween.chain().finished.connect(_on_sit_finished)

# Zachowujemy starą funkcję dla kompatybilności z Twoim starym krzesłem:
func sit_down():
	sit_down_on_furniture(chair, chair.sit_point)

func _on_sit_finished():
	current_state = State.SITTING

func stand_up():
	if current_state != State.SITTING:
		return
		
	current_state = State.TRANSITION
	
	var tween2 = create_tween().set_parallel(true)
	
	# Resetujemy rotację mebla TYLKO jeśli to było obrotowe krzesło
	if current_furniture and current_furniture.name == "Chair":
		tween2.tween_property(current_furniture, "rotation:y", deg_to_rad(90), 0.3).set_trans(Tween.TRANS_SINE)
	
	var target_angle = deg_to_rad(180)
	var angle_diff = wrapf(target_angle - head.rotation.y, -PI, PI)
	var shortest_target = head.rotation.y + angle_diff
	
	tween2.tween_property(head, "rotation:y", shortest_target, 0.3).set_trans(Tween.TRANS_SINE)
	await tween2.finished

	# Obliczamy pozycję wyjściową z przodu mebla, na którym aktualnie siedzimy
	var exit_position: Vector3
	if current_exit_point:
		# Jeśli mebel (jak nasza nowa kanapa) ma zdefiniowany punkt wyjścia, użyj go!
		exit_position = current_exit_point.global_position
	else:
		# Jeśli to stare krzesło i nie ma punktu wyjścia, użyj starego automatycznego obliczenia
		var exit_offset = current_furniture.global_transform.basis.z * 1.2
		exit_position = global_position - exit_offset
	
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(self, "global_position", exit_position, 0.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_property($Head/Camera3D, "rotation:x", 0.0, 0.4)

	tween.chain().finished.connect(_on_stand_up_finished)

func _on_stand_up_finished():
	$CollisionShape3D.disabled = false
	if current_furniture and current_furniture.has_node("CollisionShape3D"):
		current_furniture.get_node("CollisionShape3D").disabled = false
		
	current_state = State.FREE
	walk_locked = false
	
	# Czyścimy referencje, bo już stoimy na nogach
	current_furniture = null
	current_sit_point = null
	current_exit_point = null

func enter_computer():
	if is_using_computer: return
	
	is_using_computer = true
	current_state = State.TRANSITION
	
	# Blokujemy myszkę i ruch
	walk_locked = true
	camera_locked = true
	
	var tween = create_tween().set_parallel(true)
	
	# 1. Kamera leci do view_point komputera
	# Używamy global_transform, żeby kamera idealnie pokryła się z punktem w świecie
	tween.tween_property(camera, "global_transform", computer.view_point.global_transform, 0.8)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)

func exit_computer():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var tween = create_tween()
	# Powrót kamery do domyślnej pozycji w głowie (0,0,0 względem Head)
	tween.tween_property(camera, "transform", Transform3D.IDENTITY, 0.6)\
		.set_trans(Tween.TRANS_CUBIC)
	
	tween.finished.connect(func():
		current_state = State.SITTING # Lub SITTING, jeśli siedzisz
		walk_locked = true
		camera_locked = false
		is_using_computer = false
	)
