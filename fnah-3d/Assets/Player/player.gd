extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5

const SENSITIVITY = 0.01

var gravity = 20
var climb_speed = 5

const DAMPING_UPHILL = 10.0  # Mocne hamowanie przy potknięciu pod górę
const DAMPING_DOWNHILL = 1.2 # Małe hamowanie, pozwala sturlać się na sam dół
const DAMPING_FLAT = 8.0     # Standardowe hamowanie na płaskim

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
var player_climbing = false

@onready var head = $Head
@onready var camera_roll = $Head/CameraRoll
@onready var camera = $Head/CameraRoll/Camera3D
@onready var chair = $"../Chair"
@onready var computer = $"../PC"
@onready var collision_shape_chair: CollisionShape3D = $CollisionShape3D
var current_furniture: Node3D = null
var current_sit_point: Node3D = null
var current_exit_point: Node3D = null

@onready var hand = $Head/CameraRoll/Camera3D/Hand

# Zmienna trzymająca ID przedmiotu, który gracz aktualnie niesie
var holding_item: String = ItemDB.NONE

var is_ragdolling: bool = false
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

# W skrypcie gracza (Player.gd) lub zarządcy telefonu
@onready var phone_model = $Head/CameraRoll/Camera3D/PhoneModel
@onready var phone_interface_ui = $CanvasLayer/PhoneInterface

# --- Pozycje telefonu w przestrzeni 3D (współrzędne lokalne wewnątrz Camera3D) ---
const PHONE_POS_HIDDEN  = Vector3(0.2, -1, -0.6)  # Schowany pod ekranem
const PHONE_POS_ACTIVE  = Vector3(0.0, -0.15, -0.65) # Na wprost oczu gracza
const PHONE_POS_PEEKING = Vector3(0.2, -0.6, -0.65) # Lekko opuszczony po prawej

# Kąt patrzenia w dół (w stopniach) potrzebny do przywrócenia telefonu z pozycji PEEKING
const PEEK_LOOK_DOWN_THRESHOLD: float = -50.0 

enum PhoneState { HIDDEN, ACTIVE, PEEKING }
var current_phone_state: PhoneState = PhoneState.HIDDEN

var active_tween: Tween

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_phone_state(PhoneState.HIDDEN)
	if phone_model and phone_interface_ui:
		phone_model.setup_screen(phone_interface_ui)

func _unhandled_input(event):
	if event.is_action_pressed("ui_focus_next") and not is_using_computer and not is_using_panel: # ui_focus_next to domyślnie TAB
		toggle_phone()
		get_viewport().set_input_as_handled()
		return
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		if !camera_locked:
			head.rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-70), deg_to_rad(60))
	
	if current_state == State.SITTING and event.is_action_pressed("jump"):
		stand_up()
	
	if is_using_panel and event.is_action_pressed("ui_cancel"):
		exit_panel()

func _process(_delta: float) -> void:
	if current_phone_state == PhoneState.HIDDEN:
		return

	# 3. Wykrywanie myszki przy górnej krawędzi (przejście do PEEKING)
	if current_phone_state == PhoneState.ACTIVE:
		var mouse_y = get_viewport().get_mouse_position().y
		if mouse_y <= 100.0: # Myszka przy samej górze
			set_phone_state(PhoneState.PEEKING)

	# 4. Wykrywanie spojrzenia w dół (powrót do ACTIVE)
	elif current_phone_state == PhoneState.PEEKING:
		# Odczytujemy dokładną lokalną rotację osi X z kamery
		var camera_pitch_deg = rad_to_deg(camera.rotation.x)
		
		# Patrzenie w dół w Godocie to kąt ujemny (np. -20 stopni jest niżej niż -15)
		if camera_pitch_deg < PEEK_LOOK_DOWN_THRESHOLD:
			set_phone_state(PhoneState.ACTIVE)

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
				# Dla wszystkich innych obiektów (sloty, krzesła itp.)
				%InteractText.show()
				if Input.is_action_just_pressed("interact"):
					# Sprawdzamy, czy obiekt to nasz slot (czy oczekuje argumentu 'player')
					if target.has_method("_update_visuals"): # Tylko ItemSlot ma tę funkcję
						target.interact(self)
					else:
						target.interact() # Dla krzesła i reszty świata bez argumentu

		if target.has_method("interact2"):
			%Interact2Text.show()
			if Input.is_action_just_pressed("interact2"):
				target.interact2()
	
	# Dodawanie grawitacji (Naprawiony podwójny minus)
	if not is_on_floor():
		if !player_climbing:
			velocity.y -= gravity * delta
	
	# Logika siedzenia (Wcięcia wyciągnięte całkowicie w lewo)
	match current_state:
		State.SITTING:
			if current_furniture and current_furniture.name == "Chair":
				current_furniture.global_rotation.y = $Head.global_rotation.y - deg_to_rad(90)
		State.TRANSITION:
			pass
	
	if walk_locked:
		if is_ragdolling:
			# Wyznaczamy aktualne tarcie na podstawie nachylenia terenu
			var current_damping = DAMPING_FLAT
			
			if is_on_floor():
				# Pobieramy wektor normalny podłoża (pokazuje, w którą stronę nachylona jest płaszczyzna)
				var floor_normal = get_floor_normal()
				# Sprawdzamy relację między kierunkiem ruchu (velocity) a nachyleniem podłoża
				var slope_direction = velocity.dot(floor_normal)
				
				if slope_direction < -0.1:
					# Ruch pod górę (prędkość idzie "przeciw" nachyleniu) -> szybkie zatrzymanie
					current_damping = DAMPING_UPHILL
				elif slope_direction > 0.1:
					# Ruch w dół (prędkość pokrywa się ze spadkiem) -> długie staczanie
					current_damping = DAMPING_DOWNHILL

			# Aplikujemy dynamicznie wyliczone tarcie
			velocity.x = move_toward(velocity.x, 0.0, current_damping * delta)
			velocity.z = move_toward(velocity.z, 0.0, current_damping * delta)
			
			move_and_slide()
		else:
			velocity.x = 0.0
			velocity.z = 0.0
		return

	# Skakanie i bieg
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("jump") and GameplayNumbers.is_player_in_any_zone():
		player_climbing = true
		velocity.y = climb_speed
	else:
		player_climbing = false
	
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Ruch gracza
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction : Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

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
	tween.tween_property($Head/CameraRoll/Camera3D, "rotation:x", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	
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
	
	# Jeśli to krzesło, resetujemy jego rotację do wartości domyślnej (np. 90 stopni)
	if current_furniture and current_furniture.name == "Chair":
		# Tutaj wpisz kąt domyślny krzesła, gdy nikt na nim nie siedzi (u Ciebie było to deg_to_rad(90))
		tween2.tween_property(current_furniture, "rotation:y", deg_to_rad(90), 0.3).set_trans(Tween.TRANS_SINE)
	
	# Obracamy głowę gracza do pozycji stojącej (180 stopni względem pokoju)
	var target_angle = deg_to_rad(180)
	var angle_diff = wrapf(target_angle - head.rotation.y, -PI, PI)
	var shortest_target = head.rotation.y + angle_diff
	
	tween2.tween_property(head, "rotation:y", shortest_target, 0.3).set_trans(Tween.TRANS_SINE)
	await tween2.finished

	# --- TUTAJ JEST REWELACJA ---
	# Ponieważ dodałeś stand_point do krzesła, ta sekcja (którą pisaliśmy wcześniej)
	# automatycznie i idealnie postawi gracza na punkcie stand_point krzesła!
	var exit_position: Vector3
	if current_exit_point:
		exit_position = current_exit_point.global_position
	else:
		var exit_offset = current_furniture.global_transform.basis.z * 1.2
		exit_position = global_position - exit_offset
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", exit_position, 0.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_property($Head/CameraRoll/Camera3D, "rotation:x", 0.0, 0.4)
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


func collect_item(item_id: String) -> void:
	holding_item = item_id
	
	# Na wszelki wypadek czyścimy rękę, jeśli coś tam było
	for child in hand.get_children():
		child.queue_free()
	
	# Ładujemy scenę z naszej bazy danych
	var scene = ItemDB.get_item_scene(item_id)
	if scene:
		var item_instance = scene.instantiate()
		hand.add_child(item_instance)
		
		# WAŻNE: Jeśli Twoja scena przedmiotu ma własny skrypt, kolizje lub fizykę,
		# tutaj możemy je wyłączyć, żeby przedmiot w ręce nie blokował gracza.
		if item_instance.has_node("CollisionShape3D"):
			item_instance.get_node("CollisionShape3D").disabled = true

func drop_item() -> String:
	var dropped = holding_item
	holding_item = ItemDB.NONE
	
	# Usuwamy model z ręki
	for child in hand.get_children():
		child.queue_free()
		
	return dropped
	
func start_ragdoll() -> void:
	if is_ragdolling:
		return
		
	is_ragdolling = true
	walk_locked = true
	
	set_phone_state(PhoneState.HIDDEN)
	get_viewport().set_input_as_handled()
	
	# 1. Pobieramy kierunek ruchu na podstawie aktualnej prędkości (obcinamy oś Y)
	var move_direction = Vector3(velocity.x, 0.0, velocity.z).normalized()
	
	# Jeśli gracz stał w miejscu, domyślnie leci w przód
	if move_direction == Vector3.ZERO:
		move_direction = -head.global_transform.basis.z.normalized()
	
	# 2. Nadajemy impuls fizyczny w stronę faktycznego ruchu
	velocity.x = move_direction.x * SPRINT_SPEED
	velocity.z = move_direction.z * SPRINT_SPEED
	velocity.y = 1.5 # Lekkie podbicie ciała na początku potknięcia

	# 3. Przeliczamy kierunek ruchu na lokalną przestrzeń głowy
	var local_dir = head.global_transform.basis.inverse() * move_direction
	
	var target_pos_z = local_dir.z * 0.6
	var target_pos_x = local_dir.x * 0.6

	# 4. Wykopyrtka kamery za pomocą Tweena na węźle CameraRoll
	var tween = create_tween().set_parallel(true)
	
	# Pozycja zmieniana na CameraRoll
	tween.tween_property(camera_roll, "position:z", target_pos_z, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera_roll, "position:x", target_pos_x, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera_roll, "position:y", -1.2, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	var target_rot_x = deg_to_rad(-60) * max(0.2, -local_dir.z)
	var target_rot_z = deg_to_rad(45) * -local_dir.x
	
	if local_dir.z > 0.5:
		target_rot_x = deg_to_rad(30)

	# Podział rotacji: X (przód/tył) na Camera3D, Z (przechył na bok) na CameraRoll
	tween.tween_property(camera, "rotation:x", target_rot_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(camera_roll, "rotation:z", target_rot_z, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Odliczanie do momentu wstania
	get_tree().create_timer(1.2).timeout.connect(stop_ragdoll)

func stop_ragdoll() -> void:
	var tween = create_tween().set_parallel(true)
	
	# Reset pozycji i rotacji Z na CameraRoll
	tween.tween_property(camera_roll, "position", Vector3.ZERO, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(camera_roll, "rotation:z", 0.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Reset rotacji X na Camera3D
	tween.tween_property(camera, "rotation:x", 0.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	# Sztywne zerowanie dla pewności, zapobiega błędom zaokrągleń
	camera_roll.rotation.z = 0.0
	camera_roll.rotation.y = 0.0
	camera_roll.rotation.x = 0.0
	
	# Przywrócenie sterowania i reset prędkości
	velocity = Vector3.ZERO
	is_ragdolling = false
	walk_locked = false

var is_using_panel: bool = false
var current_panel: Node3D = null

func enter_panel(panel_node: Node3D) -> void:
	if is_using_panel:
		return
		
	is_using_panel = true
	current_panel = panel_node
	current_state = State.TRANSITION
	
	# Zatrzymujemy postać i obracanie głową
	walk_locked = true
	camera_locked = true
	
	# Uwalniamy kursor myszy do klikania śrubek, korków i kabli
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Jeśli panel ma wyznaczony punkt widoku (np. view_point / CameraPoint), leci tam kamera.
	# W przeciwnym razie ustawia się na wprost panela.
	var target_transform: Transform3D
	if panel_node.has_node("view_point"):
		target_transform = panel_node.get_node("view_point").global_transform
	else:
		target_transform = panel_node.global_transform
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(camera, "global_transform", target_transform, 0.6)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)

func exit_panel() -> void:
	if not is_using_panel:
		return
		
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var tween = create_tween()
	tween.tween_property(camera, "transform", Transform3D.IDENTITY, 0.5)\
		.set_trans(Tween.TRANS_CUBIC)
		
	tween.finished.connect(func():
		current_state = State.FREE
		walk_locked = false
		camera_locked = false
		is_using_panel = false
		
		if current_panel:
			if current_panel.is_cover_open and current_panel.has_method("close_cover"):
				current_panel.close_cover()
			
			# Przywracamy stan początkowy tabletu dopiero po odejściu gracza:
			current_panel.is_player_focused = false
			if current_panel.main_area_collision:
				current_panel.main_area_collision.disabled = false
				
			current_panel = null
	)

# --- Zmiana stanów i animacje ---

func toggle_phone() -> void:
	if current_phone_state == PhoneState.HIDDEN:
		set_phone_state(PhoneState.ACTIVE)
	else:
		set_phone_state(PhoneState.HIDDEN)

func set_phone_state(new_state: PhoneState) -> void:
	current_phone_state = new_state
	var target_pos: Vector3

	match current_phone_state:
		PhoneState.HIDDEN:
			target_pos = PHONE_POS_HIDDEN
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Przypisujemy mysz do gry

		PhoneState.ACTIVE:
			target_pos = PHONE_POS_ACTIVE
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # Uwalniamy kursor do klikania w ekran

		PhoneState.PEEKING:
			target_pos = PHONE_POS_PEEKING
			
			# Wyprostowanie wzroku kamery do poziomu (rotation.x = 0)
			var cam_tween = create_tween()
			cam_tween.tween_property(camera, "rotation:x", 0.0, 0.15)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
			# Przypisujemy mysz do gry dopiero po zresetowaniu kąta
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_animate_phone_to(target_pos)

func _animate_phone_to(target_position: Vector3) -> void:
	if active_tween and active_tween.is_running():
		active_tween.kill()

	active_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(phone_model, "position", target_position, 0.25)
