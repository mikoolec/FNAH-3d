# ItemSlot.gd
extends Area3D # Możesz też użyć StaticBody3D, jeśli wolisz

# Typy slotów do wyboru w edytorze
enum SlotType { SPAWNER, SINGLE, TRASH, PRINTER, BIGTRASH }

@export var slot_type: SlotType = SlotType.SINGLE
@export var default_item: String = ItemDB.NONE # Jaki przedmiot tu leży na starcie?

var current_item: String = ItemDB.NONE
var trash_capacity: int = 0

@onready var drukarka: StaticBody3D = $"../Drukarka"


func _ready() -> void:
	current_item = default_item
	_update_visuals()

func _update_visuals() -> void:
	# Usuwamy stary model, który aktualnie wyświetlał slot
	for child in get_children():
		# Usuwamy tylko instancje modeli, zostawiamy CollisionShape3D!
		if child != $CollisionShape3D: 
			child.queue_free()
	
	# Jeśli w slocie coś leży, tworzymy tego model
	if ( current_item != ItemDB.NONE ) && ( slot_type != SlotType.TRASH ):
		var scene = ItemDB.get_item_scene(current_item)
		if scene:
			var item_instance = scene.instantiate()
			add_child(item_instance)
			
			# Wyłączamy kolizję samego przedmiotu, bo to SLOT ma swoją własną kolizję do klikania
			if item_instance.has_node("CollisionShape3D"):
				item_instance.get_node("CollisionShape3D").disabled = true
	elif slot_type == SlotType.TRASH:
		var filler = $"../TrashFiller"
		filler.scale.y = (float(trash_capacity)/10)
# Główna funkcja interakcji wywoływana przez gracz_process
func interact(player) -> void:
	match slot_type:
		SlotType.SPAWNER:
			# Gracz ma wolną rękę i spawner coś oferuje
			if player.holding_item == ItemDB.NONE and current_item != ItemDB.NONE:
				player.collect_item(current_item)
				
		SlotType.SINGLE:
			# Opcja A: Slot ma przedmiot, gracz ma wolną rękę -> Podnosimy
			if current_item != ItemDB.NONE and player.holding_item == ItemDB.NONE:
				player.collect_item(current_item)
				current_item = ItemDB.NONE
				_update_visuals()
				
			# Opcja B: Slot jest pusty, gracz trzyma przedmiot -> Odkładamy
			elif current_item == ItemDB.NONE and player.holding_item != ItemDB.NONE:
				current_item = player.drop_item()
				_update_visuals()

		SlotType.TRASH:
			# Jeśli gracz coś trzyma, śmietnik to zabiera i bezpowrotnie niszczy
			if ( player.holding_item != ItemDB.NONE ) && ( player.holding_item != ItemDB.TRASHBAG ) :
				if trash_capacity <= 10:
					var destroyed_item = player.drop_item()
					_handle_failsafe(destroyed_item)
					if trash_capacity == 10:
						player.collect_item(current_item)
						trash_capacity = 0
					else:
						trash_capacity += 1
						print("wyrzucono cos, aktualne zapelnienie to", trash_capacity)
			elif ( trash_capacity > 0 ):
				player.collect_item(current_item)
				print("podniesiono smieci - oprozniono smietnik")
				trash_capacity = 0
			_update_visuals()
		
		SlotType.BIGTRASH:
			if ( player.holding_item != ItemDB.NONE ):
				var destroyed_item = player.drop_item()
				_handle_failsafe(destroyed_item)
				var bigtrash = $"../BigTrash".get_child(3)
				bigtrash.play("Throw")
				
			
		SlotType.PRINTER:
			if ( player.holding_item == ItemDB.KEY ) :
				var destroyed_item = player.drop_item()
				_handle_failsafe(destroyed_item)
				print("Drukarka kartka in")
				drukarka.kartkaIn = true
				
			_update_visuals()

# Failsafe: szuka w całej grze slotu typu SINGLE, który zgubił ten przedmiot i go respi
func _handle_failsafe(item_id: String) -> void:
	# Przeszukujemy całe drzewo gry w poszukiwaniu innych slotów
	var all_slots = get_tree().get_nodes_in_group("slots")
	for slot in all_slots:
		if slot.slot_type == SlotType.SINGLE and slot.default_item == item_id:
			if slot.current_item == ItemDB.NONE: # Respi się tylko jeśli nie wrócił na miejsce
				slot.current_item = item_id
				slot._update_visuals()
				break
