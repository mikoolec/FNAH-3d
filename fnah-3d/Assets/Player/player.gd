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
	
	match current_state:
		State.SITTING:
			chair.global_rotation.y = $Head.global_rotation.y - camOffset
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

func sit_down():
	current_state = State.TRANSITION
	walk_locked = true
	# 1. Wyłączamy kolizje, żeby gracz nie utknął w krześle
	$CollisionShape3D.disabled = true
	collision_shape_chair.disabled = true
	
	# Pobieramy kąt startowy głowy i kąt docelowy krzesła
	var start_rot_y = $Head.global_rotation.y
	var target_rot_y = chair.global_rotation.y + deg_to_rad(90)

	# Tworzymy Tween
	var tween = create_tween().set_parallel(true)

	# 1. Płynne przesuwanie pozycji (to co masz w kodzie)
	tween.tween_property(self, "global_position", chair.sit_point.global_position, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 2. NOWOŚĆ: Płynna rotacja głowy z gwarancją NAJKRÓTSZEJ drogi
	tween.tween_method(
		func(value: float):
			# lerp_angle automatycznie wybiera obrót w lewo lub w prawo, 
			# zależnie od tego, co ma bliżej (droga nigdy nie przekroczy 180 stopni)
			$Head.global_rotation.y = lerp_angle(start_rot_y, target_rot_y, value),
		0.0, # Wartość startowa suwaka 'value'
		1.0, # Wartość końcowa suwaka 'value'
		0.5  # Czas trwania w sekundach
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 3. Płynne wyprostowanie wzroku kamery (oś X na zero), żeby nie patrzyła w podłogę
	tween.tween_property($Head/Camera3D, "rotation:x", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE)
	
	tween.chain().finished.connect(_on_sit_finished)

func _on_sit_finished():
	current_state = State.SITTING

func stand_up():
	if current_state != State.SITTING:
		return
		
	current_state = State.TRANSITION # Blokujemy sterowanie na czas wstawania
	
	var tween2 = create_tween().set_parallel(true) # Pozwala animować kilka rzeczy naraz
	# Obracamy krzesło
	tween2.tween_property(chair, "rotation:y", deg_to_rad(90), 0.3).set_trans(Tween.TRANS_SINE)
	# Obracamy kamerę/głowę gracza do tej samej rotacji
	# Zakładamy, że player.head to węzeł kontrolujący obrót głowy
	var target_angle = deg_to_rad(180)
	# Obliczamy najkrótszą drogę (wynik będzie w zakresie -PI do PI)
	var angle_diff = wrapf(target_angle - head.rotation.y, -PI, PI)
	# Nowy cel to: obecna rotacja + najkrótsza droga
	var shortest_target = head.rotation.y + angle_diff
	
	tween2.tween_property(head, "rotation:y", shortest_target, 0.3).set_trans(Tween.TRANS_SINE)
	await tween2.finished

	# Obliczamy pozycję końcową: 1.2 metra przed krzesłem (w stronę jego przodu)
	# Używamy transformacji krzesła, aby wiedzieć, gdzie jest jego przód
	var exit_offset = chair.global_transform.basis.z * 1.2
	var exit_position = global_position - exit_offset
	
	# Tworzymy Tween dla płynnego wstawania
	var tween = create_tween().set_parallel(true)
	
	# 1. Płynnie przesuwamy gracza na nogi przed krzesło
	tween.tween_property(self, "global_position", exit_position, 0.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 2. Opcjonalnie: upewnij się, że wzrok wraca do poziomu (oś X kamery)
	tween.tween_property($Head/Camera3D, "rotation:x", 0.0, 0.4)

	# Po zakończeniu animacji przywracamy wolność
	tween.chain().finished.connect(_on_stand_up_finished)

func _on_stand_up_finished():
	$CollisionShape3D.disabled = false # Włączamy fizykę z powrotem
	collision_shape_chair.disabled = false
	current_state = State.FREE
	walk_locked = false

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
