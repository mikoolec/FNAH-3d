extends PanelContainer

@onready var file_name_label: Label = $VBoxContainer/FileNameLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var input_blocker: Control = $"../InputBlocker"


# Zmienna, którą możesz dowolnie modyfikować, aby zmienić czas pobierania (w sekundach)
@export var download_time: float = 3.0

var target_file_name: String = ""
var pulpit_ref: Control = null # Referencja do Twojego pulpitu

var current_download_tween: Tween

var _download_id: int = 0   # nowe pobieranie unieważnia stare

func start_download(file_name: String, pulpit: Control) -> void:
	target_file_name = file_name
	pulpit_ref = pulpit
	file_name_label.text = "Pobieranie: " + file_name
	progress_bar.value = 0.0
	visible = true
	input_blocker.show()

	_download_id += 1
	var my_id := _download_id

	# Losujemy, czy to pobieranie zakończy się błędem (30% szans) i w którym momencie
	var fail_chance: float = 0.3
	var will_fail: bool = randf() < fail_chance
	var fail_at_percent: float = 100.0
	if will_fail:
		fail_at_percent = randf_range(10.0, 90.0)

	# Postęp liczony ręcznie: tempo zależy od szybkości sieci i od liczby transferów dzielących łącze
	var progress := 0.0
	while progress < 100.0:
		if my_id != _download_id:
			return   # rozpoczęto nowsze pobieranie - to jest nieaktualne
		if not NetworkManager.is_connected_to_internet:
			_cancel_download("Pobieranie przerwane: brak połączenia z siecią.")
			return
		if progress >= fail_at_percent and will_fail:
			_cancel_download("Błąd pobierania pliku!")
			return

		NetworkManager.report_transfer(&"browser_download")
		progress += get_process_delta_time() / (download_time * NetworkManager.effective_multiplier()) * 100.0
		progress_bar.value = progress
		await get_tree().process_frame

	NetworkManager.end_transfer(&"browser_download")
	_on_download_finished()

# Funkcja pomocnicza w razie błędu/anulowania
func _cancel_download(reason: String) -> void:
	NetworkManager.end_transfer(&"browser_download")
	if current_download_tween and current_download_tween.is_running():
		current_download_tween.kill()
	
	visible = false
	hide()
	print(reason)
	input_blocker.hide()
	
	var chance: float = randf()
	
	if chance < 0.3:
		WindowManager.spawn_window_cascade("CRITICAL SYSTEM ERROR 0x000000", randi_range(10, 20), 0.03)
	else:
		for i in range(randi_range(3, 6)):
			WindowManager.spawn_error("Nie udało się pobrać pliku.")
			await get_tree().create_timer(0.1).timeout

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
		if pulpit_ref and pulpit_ref.get_desktop_file_count() == 0:
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
