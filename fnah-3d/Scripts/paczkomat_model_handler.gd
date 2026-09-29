extends Node3D

var rng = RandomNumberGenerator.new()
@export var slot_scene: PackedScene

@export var viewport: SubViewport       # Upewnij się, że masz to przypisane
@export var screen_mesh: MeshInstance3D # Upewnij się, że masz to przypisane

var laststate: String = "closed"

var firma: GameplayNumbers.paczko_firmy

# Tablica przechowująca pary: { "door": Node3D, "spawn": Node3D }
var lockers: Array[Dictionary] = []
# Referencja do aktualnie otwartych drzwiczek (żeby zamykać tylko te, które są otwarte)
var active_door: Node3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var material = screen_mesh.get_active_material(0)
	firma = $SubViewport/PaczkomatUI.firma
	if material:
		# Wciskamy wygenerowaną teksturę z Viewportu prosto do albedo
		material.albedo_texture = viewport.get_texture()
	
	var miejsca_node = get_node_or_null("miejsca")
	if miejsca_node:
		for marker in miejsca_node.get_children():
			if marker.name.begins_with("M"):
				var suffix = marker.name.substr(1) # Wyciąga sam numer, np. "12", "34"
				var door = get_node_or_null("D" + suffix)
				if door:
					lockers.append({ "door": door, "spawn": marker })



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ( GameplayNumbers.check_paczkomat(firma) != laststate ):
		if ( laststate == "opened" ):
			laststate = "closed"
			close()
		else:
			laststate = "opened"
	
func close() -> void:
	if active_door:
		var tween = create_tween()
		tween.tween_property(active_door, "rotation_degrees:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		active_door = null


func open( srodek: GameplayNumbers.paczka_zawartosc ) -> void:
	#print("lepszy kod")
	
	if lockers.is_empty():
		print("Brak skonfigurowanych skrytek w modelu!")
		return

	# Losujemy jedną wolną/dowolną skrytkę z naszej tablicy
	var chosen_locker: Dictionary = lockers.pick_random()
	var drzwiczki: Node3D = chosen_locker["door"]
	var punkt_spawnu: Node3D = chosen_locker["spawn"]

	active_door = drzwiczki
	var tween = create_tween()
	tween.tween_property(drzwiczki, "rotation_degrees:y", -90.0, 0.5).set_trans(Tween.TRANS_SINE)
	
	
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
			new_slot.paczkomat_origin = firma
			new_slot.add_to_group("slots")
			# Dodajemy do sceny (jako dziecko głównego węzła paczkomatu)
			# 1. Dodajemy slot do głównej sceny (root), żeby operował w przestrzeni całego świata
			get_tree().current_scene.add_child(new_slot)
			
			var obrocona_pozycja_m = global_basis * punkt_spawnu.position
			new_slot.global_position = global_position + obrocona_pozycja_m
			new_slot.global_rotation = global_rotation + punkt_spawnu.rotation
			
			# 2. Ręcznie przypisujemy mu globalną transformację markera M...
			#   new_slot.global_position = $".".global_position + punkt_spawnu.global_position
			
			#print("Globalna pozycja po wymuszeniu: ", new_slot.global_position)
			#print("Próba postawienia na: ", punkt_spawnu.global_position)

			print("postawiono paczkę ", srodek)
			
			
			
		else:
			print("nie ma slot scene")
	else:
		print("Nie znaleziono markera spawn")
