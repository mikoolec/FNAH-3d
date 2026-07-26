# Skrypt podpięty pod TrashIcon
extends TextureButton

# 1. Sprawdzamy, czy przeciągany obiekt to plik dokumentu
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "file_document":
		return true
	return false

# 2. Co się stanie, gdy puszczenie myszki nastąpi nad śmietnikiem
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var dropped_file_name = data.get("file_name", "Plik")
	
	# Jeśli przekazano referencję do węzła pliku, usuwamy go z pulpitu
	if data.has("node") and is_instance_valid(data["node"]):
		data["node"].queue_free()
		print("Usunięto plik: ", dropped_file_name)
	
	# Opcjonalnie: odtwórz dźwięk wyrzucania do kosza, jeśli masz węzeł AudioStreamPlayer
	# if has_node("TrashSound"):
	# 	$TrashSound.play()
