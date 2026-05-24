extends PanelContainer

@onready var file_name_label: Label = $VBoxContainer/FileNameLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar

# Zmienna, którą możesz dowolnie modyfikować, aby zmienić czas pobierania (w sekundach)
@export var download_time: float = 3.0

var target_file_name: String = ""
var pulpit_ref: Control = null # Referencja do Twojego pulpitu

func start_download(file_name: String, pulpit: Control) -> void:
	target_file_name = file_name
	pulpit_ref = pulpit
	file_name_label.text = "Pobieranie: " + file_name
	progress_bar.value = 0.0
	visible = true
	
	# Płynna animacja paska postępu za pomocą Tweena
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100.0, download_time)\
		.set_trans(Tween.TRANS_LINEAR)
		
	# Wywołanie funkcji po zakończeniu pobierania
	tween.finished.connect(_on_download_finished)

func _on_download_finished() -> void:
	if pulpit_ref and pulpit_ref.has_method("spawn_file_on_desktop"):
		pulpit_ref.spawn_file_on_desktop(target_file_name)
	visible = false
	queue_free() # Zamykamy okienko pobierania
