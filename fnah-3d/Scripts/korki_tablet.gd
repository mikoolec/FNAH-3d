extends Node3D

signal panel_completed # Sygnał wyemitowany, gdy wszystkie 4 kable są poprawnie połączone

@onready var main_area_collision: CollisionShape3D = $Area3D/CollisionShape3D # Dostosuj ścieżkę do swojego węzła
@onready var skeleton: Skeleton3D = $"MAIN ARMATURE/Skeleton3D"
@onready var anim_player: AnimationPlayer = $AnimationPlayer # Dostosuj ścieżkę do AnimationPlayera

var is_closing: bool = false
var is_player_focused: bool = false
# Pamięć pozycji restowych dla osi mieszania (np. osi Y)
var base_left_cable_positions: Array[Vector3] = []
var base_right_cable_positions: Array[Vector3] = []
var cables_initialized: bool = false

var active_cable_attachment: Node3D = null
# --- STANY ELEMENTÓW ---
var breaker_states: Array[bool] = []
var saved_breaker_states: Array[bool] = [] # Kopia zapasowa do odtworzenia po zamknieciu na Esc
var screw_states: Array[bool] = [false, false, false, false] # false = wkręcona, true = wykręcona

var is_cover_open: bool = false
var is_panel_solved: bool = false

# --- MIESZANIE I KABLE ---
var left_cable_positions: Array[int] = [0, 1, 2, 3] # Mapowanie indeksów kabli do pozycji
var right_cable_positions: Array[int] = [0, 1, 2, 3]
var cable_connected: Array[bool] = [false, false, false, false]

# Dragging kabla
var active_dragging_cable_id: int = -1
var drag_plane: Plane

# Nazwy kości śrub i korków w Skeleton3D (Upewnij się, że nazwy zgadzają się z rgiem z Blendera!)
var screw_bone_names: Array[String] = ["LU screw", "RU screw", "LD screw", "RD screw"]
var left_cable_tip_bones: Array[String] = ["Cable1", "Cable2", "Cable3", "Cable4"]
var right_cable_bones: Array[String] = ["RCap1", "RCap2", "RCap3", "RCap4"]

var breaker_bone_names: Array[String] = [
	"Bre11", "Bre12", "Bre13", "Bre14", "Bre15", "Bre16",
	"Bre21", "Bre22", "Bre23", "Bre24", "Bre25", "Bre26"
]

func _ready() -> void:
	breaker_states.resize(12)
	breaker_states.fill(true)
	saved_breaker_states = breaker_states.duplicate()
	
	# Zapamiętujemy fabryczne pozycje podstaw kabli z Blendera (Cap1..Cap4 oraz RCap1..RCap4)
	for i in range(4):
		var left_cap_idx = skeleton.find_bone("Cap" + str(i + 1))
		var right_rcap_idx = skeleton.find_bone(right_cable_bones[i])
		
		if left_cap_idx != -1:
			base_left_cable_positions.append(skeleton.get_bone_rest(left_cap_idx).origin)
		if right_rcap_idx != -1:
			base_right_cable_positions.append(skeleton.get_bone_rest(right_rcap_idx).origin)

func _input(event: InputEvent) -> void:
	# Przerwanie przeciągania przy puszczeniu LPM
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if active_dragging_cable_id != -1:
			_drop_cable(active_dragging_cable_id)

	# KLIKNIĘCIE LPM W TRYBIE FOCUSU:
	if is_player_focused and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_raycast_from_mouse_click()

	# ZAMYKANIE NA ESC W TRYBIE FOCUSU:
	if is_player_focused and event.is_action_pressed("ui_cancel"):
		if is_cover_open:
			close_cover()
			# Zjadamy zdarzenie Input, żeby skrypt gracza nie wywołał exit_panel()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	# Jeśli gracz ciągnie kabel, aktualizujemy pozycję kości-końcówki względem myszki
	if active_dragging_cable_id != -1 and is_cover_open:
		_update_dragged_cable_position()

# --- GŁÓWNA OBSŁUGA INTERAKCJI (Wywoływana przez Raycast gracza) ---
func interact_with_element(element: Area3D) -> void:
	if not "type" in element:
		return

	var player = get_tree().get_first_node_in_group("Player")

	# PIERWSZY KLIK: Wchodzimy w tryb focusu
	if player and not player.is_using_panel:
		is_player_focused = true
		
		# Wyłączamy główny collider, żeby promień trafiał bezpośrednio w korki/śruby/kable
		if main_area_collision:
			main_area_collision.disabled = true
			
		player.enter_panel(self)
		return

	# 2. KOLEJNE KLIKNIĘCIA (gdy gracz jest już zablokowany w trybie panela):
	match element.type:
		0: # BREAKER (Korki)
			if not is_cover_open:
				_toggle_breaker(element.id)
		1: # SCREW (Śrubki)
			if not is_cover_open:
				_toggle_screw(element.id)
		2: # CABLE_LEFT (Złapanie kabla)
			if is_cover_open and not cable_connected[element.id]:
				_start_dragging_cable(element.id, element)

func _raycast_from_mouse_click() -> void:
	# Jeśli gracz właśnie ciągnie kabel, nie przetwarzamy nowych kliknięć
	if active_dragging_cable_id != -1:
		return

	var camera = get_viewport().get_camera_3d()
	if not camera:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var ray_length = 10.0

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * ray_length)
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)

	if result and result.collider is Area3D:
		var hit_area = result.collider as Area3D
		# Wywołujemy naszą istniejącą logikę przełączania dla trafionego elementu
		interact_with_element(hit_area)

# --- LOGIKA KORKÓW ---
func _toggle_breaker(id: int) -> void:
	breaker_states[id] = not breaker_states[id]
	var bone_idx = skeleton.find_bone(breaker_bone_names[id])
	
	if bone_idx != -1:
		# Odczytujemy aktualną i domyślną rotację
		var start_rot = skeleton.get_bone_pose_rotation(bone_idx)
		
		# Kąt obrotu: np. 35 stopni w dół gdy włączony, 0 stopni gdy wyłączony
		var angle_deg = -170.0 if breaker_states[id] else -10.0
		# Jeśli przełącznik wygina się w złą stronę, zmień Vector3.RIGHT na Vector3.LEFT lub Vector3.FORWARD
		var target_rot = Quaternion(Vector3.FORWARD, deg_to_rad(angle_deg))
		
		var tween = create_tween()
		tween.tween_method(func(rot: Quaternion):
			skeleton.set_bone_pose_rotation(bone_idx, rot),
			start_rot, target_rot, 0.15)

# --- LOGIKA ŚRUBUJĄCA ---
func _toggle_screw(id: int) -> void:
	screw_states[id] = not screw_states[id]
	var bone_name = screw_bone_names[id]
	var bone_idx = skeleton.find_bone(bone_name)
	
	if bone_idx != -1:
		var start_pos = skeleton.get_bone_pose_position(bone_idx)
		var start_rot = skeleton.get_bone_pose_rotation(bone_idx)
		
		var target_z = 0.04 if screw_states[id] else 0.0
		var target_pos = Vector3(start_pos.x, start_pos.y, target_z)
		
		var target_rot_z = deg_to_rad(720) if screw_states[id] else 0.0
		var target_rot = Quaternion(Vector3.FORWARD, target_rot_z)
		
		var tween = create_tween().set_parallel(true)
		
		# Animacja przesunięcia
		tween.tween_method(func(pos: Vector3): 
			skeleton.set_bone_pose_position(bone_idx, pos), 
			start_pos, target_pos, 0.4)
			
		# Animacja obrotu (slerp)
		tween.tween_method(func(rot: Quaternion): 
			skeleton.set_bone_pose_rotation(bone_idx, rot), 
			start_rot, target_rot, 0.4)
		
		tween.chain().finished.connect(_check_screws_unlocked)

func _check_screws_unlocked() -> void:
	if is_closing:
		return
		
	# Otwieramy pokrywę TYLKO wtedy, gdy wszystkie 4 śruby są ustawione na true (wykręcone)
	if screw_states == [true, true, true, true] and not is_cover_open:
		open_cover()

# --- POKRYWA I MIESZANIE ---
func open_cover() -> void:
	is_cover_open = true
	saved_breaker_states = breaker_states.duplicate() # Zapisujemy stan korków
	
	anim_player.play("cover fall") # Twoja animacja opadania z Blendera
	_shuffle_cables()

func close_cover() -> void:
	is_cover_open = false
	is_closing = true
	# USUNIĘTO: is_player_focused = false (gracz nadal patrzy na panel!)
	
	# 1. Odpalenie animacji zamykania pokrywy
	anim_player.play("cover rise")
	
	# 2. Sztywne zresetowanie tablicy śrub w pamięci
	screw_states = [false, false, false, false]
	
	# 3. Przywrócenie kości śrub w szkiełku do pozycji fabrycznej (wkręcone)
	for i in range(4):
		var bone_idx = skeleton.find_bone(screw_bone_names[i])
		if bone_idx != -1:
			var rest_pos = skeleton.get_bone_rest(bone_idx).origin
			var rest_rot = skeleton.get_bone_rest(bone_idx).basis.get_rotation_quaternion()
			skeleton.set_bone_pose_position(bone_idx, rest_pos)
			skeleton.set_bone_pose_rotation(bone_idx, rest_rot)

	# 4. Czekamy, aż animacja zamykania pokrywy dobiegnie końca
	if anim_player.is_playing():
		await anim_player.animation_finished

	# 5. PO ZAMKNIĘCIU POKRYWY: Reset połączeń i pozycji kabli
	for i in range(4):
		cable_connected[i] = false
		var bone_idx = skeleton.find_bone(left_cable_tip_bones[i])
		if bone_idx != -1:
			var rest_pos = skeleton.get_bone_rest(bone_idx).origin
			skeleton.set_bone_pose_position(bone_idx, rest_pos)

	# 6. Przywrócenie zapisanych korków
	for i in range(12):
		if breaker_states[i] != saved_breaker_states[i]:
			_toggle_breaker(i)

	# Odblokowanie otwierania
	is_closing = false
	# USUNIĘTO: if main_area_collision: main_area_collision.disabled = false

func _shuffle_cables() -> void:
	if base_left_cable_positions.size() < 4 or base_right_cable_positions.size() < 4:
		return

	# Tworzymy losowe kolejności indeksów (np. [2, 0, 3, 1])
	left_cable_positions.shuffle()
	right_cable_positions.shuffle()

	# Przypisujemy kościom podstawowe pozycje z zapamiętanych według losowego klucza
	for i in range(4):
		var left_cap_idx = skeleton.find_bone("Cap" + str(i + 1))
		var right_rcap_idx = skeleton.find_bone(right_cable_bones[i])

		if left_cap_idx != -1:
			var target_pos = base_left_cable_positions[left_cable_positions[i]]
			skeleton.set_bone_pose_position(left_cap_idx, target_pos)

		if right_rcap_idx != -1:
			var target_pos = base_right_cable_positions[right_cable_positions[i]]
			skeleton.set_bone_pose_position(right_rcap_idx, target_pos)
	
	# Tutaj możesz dodatkowo zaaplikować przesunięcie pozycji bazowych kości kabli w zależności od wylosowanej kolejności

# --- FIZYKA PRZECIĄGANIA KABLI ---
func _start_dragging_cable(cable_id: int, area_node: Area3D) -> void:
	active_dragging_cable_id = cable_id
	active_cable_attachment = area_node.get_parent() as Node3D
	
	if active_cable_attachment:
		# Płaszczyzna z normalną Z (globalne XY) przechodząca przez kabel
		drag_plane = Plane(Vector3.FORWARD, active_cable_attachment.global_position)

func _update_dragged_cable_position() -> void:
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	
	# Zderzamy promień z płaszczyzną globalnego XY
	var hit_world_pos = drag_plane.intersects_ray(ray_origin, ray_dir)
	
	if hit_world_pos:
		var bone_idx = skeleton.find_bone(left_cable_tip_bones[active_dragging_cable_id])
		if bone_idx != -1:
			var bone_global_pose = skeleton.get_bone_global_pose(bone_idx)
			# Konwertujemy pozycję trafienia ze świata do szkieletu
			bone_global_pose.origin = skeleton.to_local(hit_world_pos)
			skeleton.set_bone_global_pose(bone_idx, bone_global_pose)

func _drop_cable(cable_id: int) -> void:
	var rca_node_name = "RCa" + str(cable_id + 1)
	var target_rca_attachment: Node3D = null
	
	if skeleton.has_node(rca_node_name):
		target_rca_attachment = skeleton.get_node(rca_node_name) as Node3D
	else:
		target_rca_attachment = skeleton.get_node(right_cable_bones[cable_id]) as Node3D

	var bone_idx = skeleton.find_bone(left_cable_tip_bones[cable_id])

	if bone_idx == -1 or not target_rca_attachment:
		active_dragging_cable_id = -1
		active_cable_attachment = null
		return

	# Odczyt pozycji z przestrzeni globalnej świata
	var current_bone_world_pos = skeleton.global_transform * skeleton.get_bone_global_pose(bone_idx).origin
	var dist = current_bone_world_pos.distance_to(target_rca_attachment.global_position)
	
	if dist < 0.1: # Snap Radius
		cable_connected[cable_id] = true
		
		# 1. Pobieramy obecny pose kości w świecie (globalny)
		var target_pose = skeleton.get_bone_global_pose(bone_idx)
		
		# 2. Ustawiamy jego pozycję w świecie dokładnie na pozycję prawego gniazda
		target_pose.origin = skeleton.to_local(target_rca_attachment.global_position)
		
		# 3. Konwertujemy tę globalną pozycję szkieletu na lokalny układ współrzędnych kości (uwzględniając parenta)
		var parent_idx = skeleton.get_bone_parent(bone_idx)
		var target_local_pos: Vector3
		
		if parent_idx != -1:
			# Jeśli kość ma parenta, odejmujemy globalny pose parenta
			var parent_global_pose = skeleton.get_bone_global_pose(parent_idx)
			target_local_pos = parent_global_pose.affine_inverse() * target_pose.origin
		else:
			target_local_pos = target_pose.origin
		
		var start_pos = skeleton.get_bone_pose_position(bone_idx)
		
		var tween = create_tween()
		tween.tween_method(func(pos: Vector3): 
			skeleton.set_bone_pose_position(bone_idx, pos), 
			start_pos, target_local_pos, 0.1)
			
		_check_win_condition()
	else:
		# Porażka - powrót do Rest Pose
		var start_pos = skeleton.get_bone_pose_position(bone_idx)
		var rest_pos = skeleton.get_bone_rest(bone_idx).origin
		
		var tween = create_tween()
		tween.tween_method(func(pos: Vector3): 
			skeleton.set_bone_pose_position(bone_idx, pos), 
			start_pos, rest_pos, 0.25)
		
	active_dragging_cable_id = -1
	active_cable_attachment = null

func _check_win_condition() -> void:
	if not cable_connected.has(false):
		is_panel_solved = true
		emit_signal("panel_completed")
		print("PANEL ROZWIAZANY PRAWIDŁOWO!")
