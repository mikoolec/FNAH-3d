extends Node3D

@export var screen_mesh: MeshInstance3D # Wskaż Twój ScreenMesh w Inspektorze
var phone_viewport: SubViewport

func setup_screen(phone_interface_node: Control) -> void:
	# Zapamiętujemy referencję do SubViewporta
	phone_viewport = phone_interface_node.find_child("ScreenViewport", true, false) as SubViewport
	
	# Podpinamy teksturę na ekran 3D
	var material = StandardMaterial3D.new()
	material.albedo_texture = phone_viewport.get_texture()
	material.emission_enabled = true
	material.emission_texture = phone_viewport.get_texture()
	screen_mesh.material_override = material


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if phone_viewport == null:
		return

	# 1. Pobieramy lokalną pozycję trafienia promienia na obiekcie ekranu
	var local_pos = screen_mesh.global_transform.affine_inverse() * event_position
	
	# 2. Zakładamy, że ekran to QuadMesh w płaszczyźnie XY z punktem (0,0) w środku.
	# Przestawiamy współrzędne z zakresu [-size/2, size/2] na zakres [0, 1] (UV)
	var mesh_size = screen_mesh.mesh.size # pobiera rozmiar siatki QuadMesh
	var uv_x = (local_pos.x / mesh_size.x) + 0.5
	var uv_y = 1.0 - ((local_pos.y / mesh_size.y) + 0.5) # Oś Y w 2D jest odwrócona!

	# 3. Przeliczamy UV [0..1] na piksele w SubViewport [0..viewport_size]
	var vp_size = phone_viewport.size
	var local_2d_pos = Vector2(uv_x * vp_size.x, uv_y * vp_size.y)

	# 4. Klonujemy zdarzenie wejścia i podmieniamy w nim pozycję myszy na tę na ekranie telefonu
	var cloned_event = event.duplicate()
	if cloned_event is InputEventMouse:
		cloned_event.position = local_2d_pos
		cloned_event.global_position = local_2d_pos
		
		# Przepychamy kliknięcie/ruch bezpośrednio do SubViewporta 2D!
		phone_viewport.push_input(cloned_event)
