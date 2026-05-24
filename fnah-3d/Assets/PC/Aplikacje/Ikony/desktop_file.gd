extends Button # lub TextureRect

var file_name: String = ""

func set_file_data(new_name: String) -> void:
	file_name = new_name
	text = new_name # Ustawia nazwę pliku jako tekst pod ikoną

# 1. ROZPOCZĘCIE PRZECIĄGANIA (Ta funkcja odpala się automatycznie, gdy klikniesz i pociągniesz)
func _get_drag_data(at_position: Vector2) -> Variant:
	# Dane, które "niesie" ze sobą myszka podczas przeciągania
	var drag_data = {
		"type": "file_document",
		"file_name": file_name
	}
	
	# Tworzymy podgląd pod kursorem myszy podczas przeciągania
	var preview = Label.new()
	preview.text = "📄 " + file_name
	set_drag_preview(preview)
	
	return drag_data
