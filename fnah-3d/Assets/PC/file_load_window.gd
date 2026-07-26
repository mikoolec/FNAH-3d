extends PanelContainer

@onready var file_name_label: Label = $VBoxContainer/FileNameLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var input_blocker: Control = $"../InputBlocker"
@onready var grid_container: GridContainer = $"../../GridContainer"

@onready var drukarka: Control = $"../MarginContainer/App/GUI"
@onready var label_printer: Label = $"../MarginContainer/App/GUI/LabelPrinterApp"
@onready var drukarkaBody: StaticBody3D = $"../../../../../../Drukarka"


# Zmienna, którą możesz dowolnie modyfikować, aby zmienić czas pobierania (w sekundach)
@export var download_time: float = 10.0

var target_file_name: String = ""

var current_download_tween: Tween

var Stage: bool = false

func start_download(file_name: String, stage: bool) -> void:
	target_file_name = file_name
	Stage = stage
	if !stage: file_name_label.text = "Wgrywanie: " + file_name
	else: file_name_label.text = "Drukowanie: " + file_name
	progress_bar.value = 0.0
	visible = true
	input_blocker.show()
	
	# Jeśli poprzednie pobieranie jakimś cudem jeszcze działa, zabijamy je
	if current_download_tween and current_download_tween.is_running():
		current_download_tween.kill()
	
	# Płynna animacja paska postępu
	current_download_tween = create_tween()
	current_download_tween.tween_property(progress_bar, "value", 100.0, download_time)\
		.set_trans(Tween.TRANS_LINEAR)
		
	# Pętla monitorująca połączenie z siecią "Drukarka" w każdej klatce gry
	while current_download_tween and current_download_tween.is_running():
		# Jeśli w trakcie pobierania gracz straci połączenie z Drukarką:
		if not NetworkManager.current_wifi_name == "Drukarka":
			if !stage: _cancel_download("Pobieranie przerwane: brak połączenia z drukarką.")
			else: _cancel_download("Drukowanie przerwane: brak połączenia z drukarką.")
			for i in range(randi_range(3, 6)):
				if !stage: WindowManager.spawn_error("Pobieranie przerwane: brak połączenia z drukarką.")
				else: WindowManager.spawn_error("Drukowanie przerwane: brak połączenia z drukarką.")
				await get_tree().create_timer(0.1).timeout
			drukarka.plikWgrany = false
			label_printer.text = "Upuść tu plik"
			return # Przerywamy wykonywanie funkcji
			
		# Czekamy na następną klatkę przed kolejnym sprawdzeniem
		await get_tree().process_frame
		
	# Jeśli pętla zakończyła się naturalnie (pasek postępu osiągnął 100%)
	_on_download_finished()

# Funkcja pomocnicza w razie błędu/anulowania
func _cancel_download(reason: String) -> void:
	if current_download_tween and current_download_tween.is_running():
		current_download_tween.kill()
		
	visible = false
	hide()
	print(reason)
	input_blocker.hide()

# Funkcja wywoływana po pomyślnym zakończeniu ładowania
func _on_download_finished() -> void:
	visible = false
	hide()
	input_blocker.hide()
	
	if !Stage: drukarka.plikWgrany = true
	else: drukarka.plikWgrany = false
	
	for i in range(randi_range(3, 6)):
				if !Stage: WindowManager.spawn_error("Plik wgrany do drukarki.")
				else:
					WindowManager.spawn_error("Plik wydrukowany.")
					label_printer.text = "Upuść tu plik"
				await get_tree().create_timer(0.1).timeout
