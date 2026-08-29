extends Node3D

var rng = RandomNumberGenerator.new()
@export var slot_scene: PackedScene

@export var viewport: SubViewport       # Upewnij się, że masz to przypisane
@export var screen_mesh: MeshInstance3D # Upewnij się, że masz to przypisane

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var material = screen_mesh.get_active_material(0)

	if material:
		# Wciskamy wygenerowaną teksturę z Viewportu prosto do albedo
		material.albedo_texture = viewport.get_texture()
	
	 # Replace with function body.
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func open( srodek: GameplayNumbers.paczka_zawartosc ) -> void:
	print("lepszy kod")
	var x = -1
	var y = -1
	while ( (x == 3 and y == 3) or ( x == 3 and y == 4 ) or ( x<1 and y<1 ) ):
		x = randi()%8+1
		y = randi()%5+1
	print("x ",x," y ",y)
	
	var nazwa_mesha = "D" + str(y) + str(x)
	var drzwiczki = get_node_or_null(nazwa_mesha)
	var tween = create_tween()
	if drzwiczki:
		tween.tween_property(drzwiczki, "rotation_degrees:y", -90.0, 0.5).set_trans(Tween.TRANS_SINE)
		print("rotato rotato")
	else:
		print("blad brak drzwiczek")
	
	var punkt_spawnu = get_node_or_null("miejsca/M" + str(y) + str(x) )
	if punkt_spawnu:
		if slot_scene:
			var new_slot = slot_scene.instantiate()

			# Konfiguracja nowego slota
			new_slot.slot_type = new_slot.SlotType.PARCEL
			
			match srodek:
				GameplayNumbers.paczka_zawartosc.C:
					new_slot.default_item = ItemDB.TUSZC
				GameplayNumbers.paczka_zawartosc.M:
					new_slot.default_item = ItemDB.TUSZM
				GameplayNumbers.paczka_zawartosc.Y:
					new_slot.default_item = ItemDB.TUSZY
				GameplayNumbers.paczka_zawartosc.K:
					new_slot.default_item = ItemDB.TUSZK
				GameplayNumbers.paczka_zawartosc.Shit:
					new_slot.default_item = ItemDB.SHIT
					
			new_slot.current_item = new_slot.default_item
			
			new_slot.add_to_group("slots")
			# Dodajemy do sceny (jako dziecko głównego węzła paczkomatu)
			# 1. Dodajemy slot do głównej sceny (root), żeby operował w przestrzeni całego świata
			get_tree().current_scene.add_child(new_slot)
			
			var obrocona_pozycja_m = global_basis * punkt_spawnu.position
			new_slot.global_position = global_position + obrocona_pozycja_m
			new_slot.global_rotation = global_rotation + punkt_spawnu.rotation
			
			# 2. Ręcznie przypisujemy mu globalną transformację markera M...
			#   new_slot.global_position = $".".global_position + punkt_spawnu.global_position
			
			print("Globalna pozycja po wymuszeniu: ", new_slot.global_position)
			print("Próba postawienia na: ", punkt_spawnu.global_position)

			print("postawiono slota ig bruv")

		else:
			print("nie ma slot scene")
	else:
		print("Nie znaleziono markera: x", x,", y",y)
