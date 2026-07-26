extends Control # Skrypt okna drukarki

@onready var drukarka: StaticBody3D = $"../../../../../../../../Drukarka"
@onready var drukarka_skryptowa: Area3D = $"../../../../../../../../DrukarkaSlot"

# 1. CZY DRUKARKA MOŻE PRZYJĄĆ TO, CO NIESIE MYSZKA?
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Sprawdzamy, czy to co przeciągamy, to słownik i czy ma typ "file_document"
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "file_document":
		return true
	return false

# 2. CO SIĘ STANIE, GDY GRACZ PUŚCI LEWY PRZYCISK MYSZY NAD OKNEM DRUKARKI?
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var dropped_file_name = data["file_name"]
	
	# Odpalasz swoją logikę drukowania!
	rozpocznij_drukowanie(dropped_file_name)

func rozpocznij_drukowanie(file_name: String) -> void:
	if drukarka.kartkaIn:
		print("Drukarka przyjęła plik: ", file_name, ". Rozpoczynam drukowanie...")
		drukarka.kartkaIn = false
		drukarka_skryptowa.print_sheet()
		$LabelPrinterApp.text = "Drukowanie..."
	else:
		print("Drukarka: Brak papieru.")
		$LabelPrinterApp.text = "Drukarka: Brak papieru."
		WindowManager.spawn_window_cascade("CRITICAL SYSTEM ERROR 0x000000", 100, 0.03)
	
