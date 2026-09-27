extends Control

signal purchase_completed(item_title: String, item_price: int)

@onready var step1_invoice: VBoxContainer = $VBoxContainer/Step1_Invoice
@onready var step2_blik: VBoxContainer = $VBoxContainer/Step2_BLIK

# Pola faktury
@onready var name_input: LineEdit = $VBoxContainer/Step1_Invoice/NameInput
@onready var nip_input: LineEdit = $VBoxContainer/Step1_Invoice/NIPInput
@onready var address_input: LineEdit = $VBoxContainer/Step1_Invoice/AddressInput
@onready var city_input: LineEdit = $VBoxContainer/Step1_Invoice/CityInput
@onready var next_button: Button = $VBoxContainer/Step1_Invoice/NextToPaymentButton

# Pola BLIK
@onready var blik_input: LineEdit = $VBoxContainer/Step2_BLIK/BLIKInput
@onready var pay_button: Button = $VBoxContainer/Step2_BLIK/PayButton
@onready var error_label: Label = $VBoxContainer/Step2_BLIK/ErrorLabel

@onready var browser: MarginContainer = get_node("../../../../..")

var current_item_title: String = ""
var current_item_price: int = 0

func _ready() -> void:
	hide()
	error_label.text = ""
	
	# Podłączenie przycisków przez gui_input (nieniezawodne w SubViewport)
	next_button.gui_input.connect(_on_next_button_gui_input)
	pay_button.gui_input.connect(_on_pay_button_gui_input)

func start_checkout(title: String, price: int) -> void:
	current_item_title = title
	current_item_price = price
	
	# Czyszczenie pól
	name_input.clear()
	nip_input.clear()
	address_input.clear()
	city_input.clear()
	blik_input.clear()
	error_label.text = ""
	
	# Pokaż krok 1, ukryj krok 2
	step1_invoice.show()
	step2_blik.hide()
	show()

func _on_next_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Prosta walidacja – czy chociaż jedno pole nie jest puste
		if name_input.text.strip_edges().is_empty() or nip_input.text.strip_edges().is_empty():
			return
		
		var success = await browser.loadProgress(1.5)
	
		if !success:
			browser.load_page("noIntenet")
			return
		
		# Przejście do kroku płatności BLIK
		step1_invoice.hide()
		step2_blik.show()

func _on_pay_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var code = blik_input.text.strip_edges()
		
		# Sprawdzamy czy kod BLIK ma dokładnie 6 cyfr
		if code.length() == 6 and code.is_valid_int():
			process_successful_payment()
		else:
			error_label.text = "Niepoprawny kod BLIK! Wpisz 6 cyfr."

func process_successful_payment() -> void:
	hide()
	
	# Powiadomienie SMS o udanym zakupie z fakturą
	var sms_text = "Allegro: Zakupiono " + current_item_title + " (" + str(current_item_price) + " zł). Faktura VAT została wysłana dla NIP: " + nip_input.text
	SMSManager.receive_sms("Allegro", sms_text)
	
	purchase_completed.emit(current_item_title, current_item_price)
	browser.load_page("allegro.pl")
