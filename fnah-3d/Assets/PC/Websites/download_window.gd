extends PanelContainer

@onready var file_name_label: Label = $VBoxContainer/FileNameLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var input_blocker: Control = $"../InputBlocker"
@onready var grid_container: GridContainer = $"../../GridContainer"


# Zmienna, którą możesz dowolnie modyfikować, aby zmienić czas pobierania (w sekundach)
@export var download_time: float = 3.0

var target_file_name: String = ""
var pulpit_ref: Control = null # Referencja do Twojego pulpitu

var current_download_tween: Tween

func start_download(file_name: String, pulpit: Control) -> void:
	target_file_name = file_name
	pulpit_ref = pulpit
	file_name_label.text = "Pobieranie: " + file_name
	progress_bar.value = 0.0
	visible = true
	input_blocker.show()
	
	# Jeśli poprzednie pobieranie jakimś cudem jeszcze działa, zabijamy je
	if current_download_tween and current_download_tween.is_running():
		current_download_tween.kill()
	
	# Obliczamy czas pobierania
	var final_time = download_time * NetworkManager.current_speed_multiplier
	
	# Płynna animacja paska postępu
	current_download_tween = create_tween()
	current_download_tween.tween_property(progress_bar, "value", 100.0, final_time)\
		.set_trans(Tween.TRANS_LINEAR)
		
	# Pętla monitorująca połączenie w każdej klatce gry
	while current_download_tween and current_download_tween.is_running():
		# Jeśli w trakcie pobierania gracz straci połączenie:
		if not NetworkManager.is_connected_to_internet:
			_cancel_download("Pobieranie przerwane: brak połączenia z siecią.")
			return # Przerywamy wykonywanie funkcji
			
		# Czekamy na następną klatkę przed kolejnym sprawdzeniem
		await get_tree().process_frame
		
	# Jeśli pętla zakończyła się naturalnie (sukces)
	_on_download_finished()

# Funkcja pomocnicza w razie błędu/anulowania
func _cancel_download(reason: String) -> void:
	if current_download_tween and current_download_tween.is_running():
		current_download_tween.kill()
		
	visible = false
	hide()
	print(reason)
	input_blocker.hide()
	# Tutaj możesz ewentualnie wywołać jakieś małe okienko z błędem na pulpicie,
	# informujące gracza, że pobieranie się nie udało.

func _on_download_finished() -> void:
	visible = false
	hide()
	input_blocker.hide()
	
	var random_num: int = randi_range(3, 6)
	# Tworzymy słownik, który posłuży jako przekazywany przez referencję stan
	var state = {
		"cancelled": false,
		"active_popups": random_num
	}
	
	for i in range(random_num):
		_process_popup(state)
		await get_tree().create_timer(0.1).timeout
	
	# Czekamy, aż wszystkie 5 okienek zostanie zamkniętych
	while state.active_popups > 0:
		await get_tree().process_frame
	
	# Jeśli gracz nie przerwał procesu w żadnym okienku, tworzymy plik
	if not state.cancelled:
		if grid_container.get_child_count() == 0:
			if pulpit_ref and pulpit_ref.has_method("spawn_file_on_desktop"):
				pulpit_ref.spawn_file_on_desktop(target_file_name)
		else:
			for i in range(randi_range(3, 6)):
				WindowManager.spawn_error("Brak miejsca na dysku.")


# Funkcja pomocnicza – każde okienko żyje własnym życiem w tle
func _process_popup(state: Dictionary) -> void:
	var chance: float = randf()
	var should_cancel: bool = false
	
	if chance < 0.5:
		var result = await WindowManager.spawn_error("Czy chcesz usunąć ten plik?", true)
		if result:
			should_cancel = true
	else:
		var result = await WindowManager.spawn_error("Czy chcesz zachować ten plik?", true)
		if not result:
			should_cancel = true
			
	if should_cancel:
		state.cancelled = true
		
	# Zmniejszamy licznik aktywnych okienek po zamknięciu tego konkretnego
	state.active_popups -= 1
