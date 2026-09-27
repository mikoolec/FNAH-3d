extends PanelContainer


# Czas ważności kodu BLIK w sekundach
@export var blik_duration: float = 30.0
var current_time_left: float = 0.0
var current_blik_code: String = ""

# Referencje do UI
@onready var main_bank_view: VBoxContainer = $VBoxContainer/MainBankView
@onready var balance_label: Label = $VBoxContainer/MainBankView/BalanceLabel
@onready var open_blik_button: TextureButton = $VBoxContainer/MainBankView/HBoxContainer/OpenBlikButton

@onready var wireless_pay_button: TextureButton = $VBoxContainer/MainBankView/HBoxContainer/WirelessPay
@onready var wireless_view: VBoxContainer = $VBoxContainer/WirelessView
@onready var wireless_amount_input: LineEdit = $VBoxContainer/WirelessView/Amount
@onready var wireless_back_button: Button = $VBoxContainer/WirelessView/BackButton
@onready var wireless_progress_bar: ProgressBar = $VBoxContainer/WirelessView/TimeProgressBar


@onready var blik_view: VBoxContainer = $VBoxContainer/BlikView
@onready var blik_code_label: Label = $VBoxContainer/BlikView/BlikCodeLabel
@onready var time_progress_bar: ProgressBar = $VBoxContainer/BlikView/TimeProgressBar
@onready var blik_back_button: Button = $VBoxContainer/BlikView/BackButton

# Zmienne dla odliczania WirelessPay
var wireless_tween: Tween
var is_wireless_cancelled: bool = false

func _ready() -> void:
	# Podłączenie sygnału zmiany stanu konta
	if not BankManager.balance_changed.is_connected(_on_balance_changed):
		BankManager.balance_changed.connect(_on_balance_changed)
	
	update_balance_display()
	
	# Pokaż tylko ekran główny banku na start
	main_bank_view.show()
	blik_view.hide()
	wireless_view.hide()
	
	# Podłączenie przycisków głównych przez gui_input
	open_blik_button.gui_input.connect(_on_open_blik_gui_input)
	wireless_pay_button.gui_input.connect(_on_wireless_pay_gui_input)
	
	# Podłączenie przycisków powrotu
	blik_back_button.gui_input.connect(_on_back_to_main_gui_input)
	wireless_back_button.gui_input.connect(_on_back_to_main_gui_input)
	
	# Obsługa zatwierdzenia kwoty w LineEdit (po wciśnięciu Enter)
	wireless_amount_input.text_submitted.connect(_on_wireless_amount_submitted)

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
	if wireless_tween and wireless_tween.is_running() and GameplayNumbers.phone_transaction == 0:
		end_wireless_payment()

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

func _on_wireless_pay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		wireless_amount_input.clear()
		wireless_progress_bar.value = 0
		
		main_bank_view.hide()
		blik_view.hide()
		wireless_view.show()

# Funkcja porównująca wpisaną kwotę ze stanem konta
func _on_wireless_amount_submitted(new_text: String) -> void:
	var entered_amount = new_text.strip_edges().to_int()
	
	if entered_amount <= 0:
		print("Wpisz poprawną kwotę!")
		wireless_amount_input.clear()
		wireless_amount_input.placeholder_text = "Liczba majster."
		return
	
	# Porównanie ze stanem konta w BankManagerze
	if entered_amount <= BankManager.account_balance:
		print("Płatność zbliżeniowa zaakceptowana: ", entered_amount, " PLN")
		
		GameplayNumbers.phone_transaction += entered_amount
		
		if wireless_tween and wireless_tween.is_running():
			wireless_tween.kill()

		# Ustawiamy zakres paska od 0 do 10
		wireless_progress_bar.max_value = 10.0
		wireless_progress_bar.value = 10.0

		# Tworzymy nowy Tween
		wireless_tween = create_tween()
		
		# Animujemy właściwość 'value' paska od 10.0 do 0.0 w czasie 10.0 sekund
		wireless_tween.tween_property(wireless_progress_bar, "value", 0.0, 10.0)
		
		# Po zakończeniu 10 sekund wywołujemy funkcję weryfikującą
		wireless_tween.tween_callback(_on_wireless_timer_finished)
	else:
		print("Brak wystarczających środków na koncie!")
		wireless_amount_input.clear()
		wireless_amount_input.placeholder_text = "Brak środków!"

func _on_wireless_timer_finished() -> void:
	# Warunek sprawdzający zmienną przerywającą
	if is_wireless_cancelled:
		print("Odliczanie zostało przerwane – anulowano akcję!")
		wireless_amount_input.clear()
		wireless_amount_input.placeholder_text = "PLN"
		return

	print("Czas minął! Anulowanie płatności zbliżeniowej z powodu limitu czasu.")
	GameplayNumbers.phone_transaction = 0
	wireless_amount_input.clear()
	wireless_amount_input.placeholder_text = "Timed out."

# Funkcja do ręcznego przerwania odliczania w dowolnym momencie
func end_wireless_payment() -> void:
	is_wireless_cancelled = true
	if wireless_tween and wireless_tween.is_running():
		wireless_tween.kill()
		wireless_progress_bar.value = 0
	print("Płatność zakonczona")
	wireless_amount_input.placeholder_text = "PLN"
	wireless_amount_input.clear()

# --- POWRÓT ---
func _on_back_to_main_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_show_main_view()

func _show_main_view() -> void:
	blik_view.hide()
	wireless_view.hide()
	main_bank_view.show()
	update_balance_display()
