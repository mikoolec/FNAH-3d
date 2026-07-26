# Skrypt podpięty pod TrashIcon
extends TextureButton

# 1. Sprawdzamy, czy to co najechało nad śmietnik, można do niego wrzucić
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Pozwalamy na upuszczenie tylko, jeśli przesyłane dane to plik pulpitu
	if typeof(data) == TYPE_DICTIONARY and data.has("type"):
		return data["type"] == "desktop_file"
	return false

# 2. Reakcja na upuszczenie pliku na śmietnik
func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data.has("node") and is_instance_valid(data["node"]):
		var file_node = data["node"]
		
		# Opcjonalnie: odtwórz dźwięk wyrzucania do kosza, jeśli masz!
		# $TrashSound.play()
		
		# Usuwamy plik z pulpitu
		file_node.queue_free()
		
		print("Plik %s został pomyślnie usunięty!" % data.get("file_name", ""))
