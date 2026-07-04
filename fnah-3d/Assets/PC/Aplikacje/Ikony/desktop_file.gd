extends VBoxContainer

# Usuwamy @onready dla labela stąd i pobierzemy go bezpośrednio w funkcji
@onready var icon_texture: TextureRect = $IconTexture

var file_name: String = ""

func set_file_data(new_name: String) -> void:
	file_name = new_name
	
	# Pobieramy węzeł bezpośrednio i od razu przypisujemy tekst
	# Upewnij się, że "FileNameLabel" to dokładna nazwa Twojego węzła Label!
	get_node("FileNameLabel").text = new_name

# ROZPOCZĘCIE PRZECIĄGANIA
func _get_drag_data(at_position: Vector2) -> Variant:
	var drag_data = {
		"type": "file_document",
		"file_name": file_name
	}
	
	# 1. Tworzymy kontener na podgląd
	var preview = VBoxContainer.new()
	
	# 2. Tworzymy miniaturkę obrazka
	var preview_texture = TextureRect.new()
	preview_texture.texture = icon_texture.texture
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture.custom_minimum_size = Vector2(60, 60)
	preview.add_child(preview_texture)
	
	# 3. Tworzymy napis pod ikoną
	var preview_label = Label.new()
	preview_label.text = file_name
	preview_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(preview_label)
	
	# 4. Stylizacja
	preview.modulate.a = 0.6
	
	# KLUCZOWE ROZWIĄZANIE:
	# Mówimy podglądowi, żeby rysował się nad wszystkim (top_level)...
	preview.top_level = true
	# ...ale NIE dodajemy go przez add_child(). Oddajemy go w całości silnikowi:
	set_drag_preview(preview)
		
	return drag_data
