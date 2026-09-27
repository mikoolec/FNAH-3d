extends PanelContainer


# Czas ważności kodu BLIK w sekundach
@export var blik_duration: float = 30.0
var current_time_left: float = 0.0
var current_blik_code: String = ""

# Referencje do UI
@onready var main_bank_view: VBoxContainer = $VBoxContainer/MainBankView
@onready var balance_label: Label = $VBoxContainer/MainBankView/BalanceLabel
@onready var open_blik_button: TextureButton = $VBoxContainer/MainBankView/HBoxContainer/OpenBlikButton
@onready var wireless_pay: TextureButton = $VBoxContainer/MainBankView/HBoxContainer/WirelessPay

@onready var blik_view: VBoxContainer = $VBoxContainer/BlikView
@onready var blik_code_label: Label = $VBoxContainer/BlikView/BlikCodeLabel
@onready var time_progress_bar: ProgressBar = $VBoxContainer/BlikView/TimeProgressBar
@onready var back_button: Button = $VBoxContainer/BlikView/BackButton

func _ready() -> void:
	update_balance_display()
	blik_view.hide()
	main_bank_view.show()
	
	if not BankManager.balance_changed.is_connected(_on_balance_changed):
		BankManager.balance_changed.connect(_on_balance_changed)
	
	# Podłączenie przycisków przez gui_input (bezproblemowe w SubViewport)
	open_blik_button.gui_input.connect(_on_open_blik_gui_input)
	back_button.gui_input.connect(_on_back_gui_input)

func _process(delta: float) -> void:
	# Odliczanie czasu BLIK-a tylko gdy widok jest aktywny
	if blik_view.visible and current_time_left > 0:
		current_time_left -= delta
		time_progress_bar.value = current_time_left
		
		# Zmiana koloru paska na czerwony, gdy zostaje mało czasu
		update_progress_bar_color()
		
		# Gdy czas minie, generujemy nowy kod automatycznie
		if current_time_left <= 0:
			generate_new_blik()
	update_balance_display()

func update_balance_display() -> void:
	balance_label.text = "%d PLN" % BankManager.account_balance

func generate_new_blik() -> void:
	var code = BankManager.generate_new_blik()
	blik_code_label.text = code.left(3) + " " + code.right(3)
	
	current_time_left = blik_duration
	time_progress_bar.max_value = blik_duration
	time_progress_bar.value = blik_duration

func _on_balance_changed(_new_balance: int) -> void:
	update_balance_display()

func update_progress_bar_color() -> void:
	var ratio = current_time_left / blik_duration
	var fill_style = time_progress_bar.get_theme_stylebox("fill")
	
	if fill_style is StyleBoxFlat:
		if ratio > 0.5:
			fill_style.bg_color = Color.GREEN
		elif ratio > 0.2:
			fill_style.bg_color = Color.ORANGE
		else:
			fill_style.bg_color = Color.RED

# Obsługa kliknięć
func _on_open_blik_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		generate_new_blik()
		main_bank_view.hide()
		blik_view.show()

func _on_back_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		blik_view.hide()
		main_bank_view.show()
