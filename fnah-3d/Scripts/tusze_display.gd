extends Node3D

# Referencje do pasków wewnątrz Viewportu
@onready var barc: ProgressBar = $SubViewport/VBoxContainer/BarC
@onready var barm: ProgressBar = $SubViewport/VBoxContainer/BarM
@onready var bary: ProgressBar = $SubViewport/VBoxContainer/BarY
@onready var bark: ProgressBar = $SubViewport/VBoxContainer/BarK

# Obiekt dostarczający dane (przypinasz w Inspektorze)
@onready	 var data_source: StaticBody3D = $"../.."

func _ready() -> void:
	# 1. Pobieramy istniejący materiał lub tworzymy nowy, jeśli go nie ma
	var mat: StandardMaterial3D
	var existing_mat = $ScreenMesh.get_active_material(0)
	
	if existing_mat:
		mat = existing_mat.duplicate()
	else:
		mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # Nie zaciemnia ekranu
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED           # Widoczny z obu stron

	# 2. Wpinamy dynamiczną teksturę z Viewportu
	mat.albedo_texture = $SubViewport.get_texture()

	# 3. Przypisujemy materiał do siatki
	$ScreenMesh.set_surface_override_material(0, mat)
	
	_setup_bar_outlines()
	

func _process(_delta: float) -> void:
	if not data_source:
		print("Brak przypisanego data_source w Inspektorze!")
		return
	
	# Pobieranie wartości z drugiego skryptu (zastąp nazwami swoich zmiennych)
	# Wartości ProgressBar domyślnie przyjmują zakres 0.0 - 100.0
	barc.value = data_source.tusze_level(data_source.kolory.CYAN)
	barm.value = data_source.tusze_level(data_source.kolory.MAGENTA)
	bary.value = data_source.tusze_level(data_source.kolory.YELLOW)
	bark.value = data_source.tusze_level(data_source.kolory.KEY)

func _setup_bar_outlines() -> void:
	var bars = [barc, barm, bary, bark]
	
	for bar in bars:
		if not bar:
			continue
			
		# Tworzymy tło z jasnym obrysem
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.4, 0.4, 0.4, 1.0) # Ciemne tło wewnątrz
		bg_style.border_color = Color(0.8, 0.8, 0.8, 1.0) # Jasny obrys
		bg_style.set_border_width_all(5)                  # Grubość obrysu: 2px
		bg_style.set_corner_radius_all(3)                # Zaokrąglenie: 3px
		
		var fill_style: StyleBoxFlat
		var current_fill = bar.get_theme_stylebox("fill")
		if current_fill is StyleBoxFlat:
			fill_style = current_fill.duplicate()
		else:
			fill_style = StyleBoxFlat.new()
		fill_style.border_color = Color(0.8, 0.8, 0.8, 1.0)
		fill_style.set_border_width_all(5)
		fill_style.set_corner_radius_all(3) 
		bar.add_theme_stylebox_override("fill", fill_style)
		
		bar.add_theme_stylebox_override("background", bg_style)
