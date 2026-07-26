extends Control # Skrypt okna drukarki

@onready var drukarka: StaticBody3D = $"../../../../../../../../Drukarka"
@onready var drukarka_skryptowa: Area3D = $"../../../../../../../../DrukarkaSlot"
@onready var file_load_window: PanelContainer = $"../../../FileLoadWindow"
@onready var print_btn: Button = $PrintBtn

var plikWgrany:bool = false
var fileName:String = ""

func _process(delta: float) -> void:
	if plikWgrany:
		if print_btn.visible == false:
			$LabelPrinterApp.text = "Plik wgrany."
			print_btn.visible = true
	else: print_btn.visible = false
		

# 1. CZY DRUKARKA MOŻE PRZYJĄĆ TO, CO NIESIE MYSZKA?
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Sprawdzamy, czy to co przeciągamy, to słownik i czy ma typ "file_document"
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "file_document":
		return true
	return false

# 2. CO SIĘ STANIE, GDY GRACZ PUŚCI LEWY PRZYCISK MYSZY NAD OKNEM DRUKARKI?
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var dropped_file_name = data["file_name"]
	if plikWgrany:
		WindowManager.spawn_window_cascade("CRITICAL SYSTEM ERROR 0x000000", 10, 0.03)
		return
	
	file_load_window.start_download(dropped_file_name, false)
	fileName = dropped_file_name
	# Odpalasz swoją logikę drukowania!
	#rozpocznij_drukowanie(dropped_file_name)

func rozpocznij_drukowanie(file_name: String) -> void:
	if drukarka.kartkaIn:
		print("Drukarka przyjęła plik: ", file_name, ". Rozpoczynam drukowanie...")
		drukarka.kartkaIn = false
		drukarka_skryptowa.print_sheet()
		$LabelPrinterApp.text = "Drukowanie..."
		file_load_window.start_download(file_name, true)
	else:
		print("Drukarka: Brak papieru.")
		$LabelPrinterApp.text = "Drukarka: Brak papieru."
		WindowManager.spawn_window_cascade("CRITICAL SYSTEM ERROR 0x000000", 10, 0.03)
	


func _on_print_btn_pressed() -> void:
	var popups_count: int = randi_range(3, 6)
	
	# Tworzymy słownik przechowujący stan procesu
	var state = {
		"cancelled": false,
		"active_popups": popups_count
	}
	
	# Odpalamy losowe okienka jedno po drugim w krótkich odstępach czasu
	for i in range(popups_count):
		_process_popup(state)
		await get_tree().create_timer(0.08).timeout # Krótkie opóźnienie sprawia, że okna wyskakują kaskadowo
	
	# Czekamy w tle, aż wszystkie okienka zostaną rozwiązane przez gracza
	while state.active_popups > 0:
		await get_tree().process_frame
	
	# Jeśli gracz nie przerwał operacji w żądnym z okien, dodajemy plik na pulpit
	if not state.cancelled:
		rozpocznij_drukowanie(fileName)
	else:
		plikWgrany = false
		drukarka.kartkaIn = false
		$LabelPrinterApp.text = "Upuść tu plik"


# Funkcja pomocnicza – każde okienko działa niezależnie w tle
func _process_popup(state: Dictionary) -> void:
	var chance: float = randf()
	var should_cancel: bool = false
	
	if chance < 0.5:
		var result = await WindowManager.spawn_error("Czy chcesz zniszczyć kartkę?", true)
		if result:
			should_cancel = true
	else:
		var result = await WindowManager.spawn_error("Czy chcesz wydrukować ten plik?", true)
		if not result:
			should_cancel = true
			
	if should_cancel:
		state.cancelled = true
		
	# Zmniejszamy licznik aktywnych okienek po zamknięciu tego konkretnego
	state.active_popups -= 1
