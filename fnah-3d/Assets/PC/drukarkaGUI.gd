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
		

# Wywoływane przez pc_control, gdy plik upuszczono na okno drukarki
func accept_file(dropped_file_name: String) -> void:
	if file_load_window.visible:   # trwa wgrywanie/drukowanie
		return
	if plikWgrany:
		WindowManager.spawn_window_cascade("CRITICAL SYSTEM ERROR 0x000000", randi_range(10, 20), 0.03)
		return

	file_load_window.start_download(dropped_file_name, false)
	fileName = dropped_file_name

func rozpocznij_drukowanie(file_name: String) -> void:
	if not drukarka.kartkaIn:
		print("Drukarka: Brak papieru.")
		#$LabelPrinterApp.text = "Drukarka: Brak papieru."
		WindowManager.spawn_window_cascade("CRITICAL SYSTEM ERROR 0x000000", randi_range(10, 20), 0.03)
		return
	
	var tusz:bool = true
	for i in range(4):
		if drukarka.tusze[i] < 10:
			tusz = false
			WindowManager.spawn_window_cascade("DAJ MNIE %s" % drukarka.kolory.keys()[i], randi_range(1, 3), 0.03)
	
	if not tusz: return
	
	
	print("Drukarka przyjęła plik: ", file_name, ". Rozpoczynam drukowanie...")
	drukarka.kartkaIn = false
	$LabelPrinterApp.text = "Drukowanie..."
	file_load_window.start_download(file_name, true)


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
		drukarka_skryptowa.print_sheet("blank")
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
