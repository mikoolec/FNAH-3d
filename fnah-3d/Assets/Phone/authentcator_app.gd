class_name AuthenticatorApp
extends PanelContainer

# Zmienna statyczna przechowująca czysty kod (6 cyfr bez spacji)
static var current_code: String = ""

@onready var code_label: Label = $VBoxContainer/CodeLabel
@onready var time_progress_bar: ProgressBar = $VBoxContainer/ProgressBar

const CODE_DURATION: float = 10.0
var time_left: float = CODE_DURATION

# --- NOWE WŁAŚCIWOŚCI ---
# Definiujemy kolory: Niebieski (pełny) -> Czerwony (pusty)
var color_full := Color("1a73e8") # Możesz wpisać HEX
var color_empty := Color("d93025") # Możesz wpisać HEX

# Styl wypełnienia paska (wyciągany w gotowości)
var pb_fill_style: StyleBoxFlat

func _ready() -> void:
	# Ustawienia podstawowe paska
	time_progress_bar.min_value = 0.0
	time_progress_bar.max_value = CODE_DURATION
	
	# --- KLUCZOWE: Pobranie i unikalizacja stylu wypełnienia ---
	# Jeśli pasek nie ma stylu, stwórz domyślny Flat
	if not time_progress_bar.has_theme_stylebox_override("fill"):
		time_progress_bar.add_theme_stylebox_override("fill", StyleBoxFlat.new())
		
	# Pobieramy styl i robimy go unikalnym dla TEGO paska (żeby nie zmieniać kolorów w całej grze)
	pb_fill_style = time_progress_bar.get_theme_stylebox("fill").duplicate()
	time_progress_bar.add_theme_stylebox_override("fill", pb_fill_style)
	
	generate_new_code()

func _process(delta: float) -> void:
	time_left -= delta
	
	# Aktualizacja wartości paska
	time_progress_bar.value = time_left
	
	# --- KLUCZOWE: Płynna zmiana koloru ---
	update_progress_bar_color()
	
	if time_left <= 0.0:
		generate_new_code()
		time_left = CODE_DURATION
		time_progress_bar.value = CODE_DURATION

func update_progress_bar_color() -> void:
	# 1. Wyliczamy ratio (współczynnik) postępu od 0.0 do 1.0
	# time_left: 10 -> ratio 1.0 (pełny)
	# time_left: 0 -> ratio 0.0 (pusty)
	var ratio = time_left / CODE_DURATION
	
	# 2. Interpolujemy kolor (płynne przejście między empty i full na podstawie ratio)
	# ratio 1.0 -> color_full
	# ratio 0.0 -> color_empty
	# ratio 0.5 -> idealny fiolet pośrodku
	var current_color = color_empty.lerp(color_full, ratio)
	
	# 3. Nakładamy wyliczony kolor na tło stylu wypełnienia
	pb_fill_style.bg_color = current_color

func generate_new_code() -> void:
	var random_number = randi_range(0, 999999)
	var formatted_code = "%06d" % random_number
	
	# Zapisujemy kod do zmiennej statycznej
	current_code = formatted_code 
	
	if code_label:
		code_label.text = formatted_code.left(3) + " " + formatted_code.right(3)
