extends Control

signal purchase_completed(item_title: String, item_price: int)

# Ładowanie sceny pojedynczej opcji dostawy
@export var delivery_option_scene: PackedScene

@onready var step1_invoice: VBoxContainer = $VBoxContainer/Step1_Invoice
@onready var step_2_delivery: VBoxContainer = $VBoxContainer/Step2_Delivery
@onready var step3_blik: VBoxContainer = $VBoxContainer/Step3_BLIK

# Pola faktury
@onready var name_input: LineEdit = $VBoxContainer/Step1_Invoice/NameInput
@onready var nip_input: LineEdit = $VBoxContainer/Step1_Invoice/NIPInput
@onready var address_input: LineEdit = $VBoxContainer/Step1_Invoice/AddressInput
@onready var city_input: LineEdit = $VBoxContainer/Step1_Invoice/CityInput
@onready var next_button: Button = $VBoxContainer/Step1_Invoice/NextToDeliveryButton
@onready var error_label2: Label = $VBoxContainer/Step1_Invoice/ErrorLabel

# Pola dostawy
@onready var delivery_list_container: VBoxContainer = $VBoxContainer/Step2_Delivery/ScrollContainer/DeliveryListContainer

# Pola BLIK (poprawione ścieżki do Step3_BLIK)
@onready var blik_input: LineEdit = $VBoxContainer/Step3_BLIK/BLIKInput
@onready var pay_button: Button = $VBoxContainer/Step3_BLIK/PayButton
@onready var error_label: Label = $VBoxContainer/Step3_BLIK/ErrorLabel
@onready var info_label: Label = $VBoxContainer/Step3_BLIK/InfoLabel

@onready var browser: MarginContainer = get_node("../../../../..")

var current_item_title: String = ""
var current_item_price: int = 0
var current_delivery_price: int = 0
var total_price: int = 0
var selected_courier: String = ""

const COURIERS: Array[String] = ["INPOST", "ORLEN", "DHL", "DPD", "ALLEGRO", "PP"]

func _ready() -> void:
	hide()
	if is_instance_valid(error_label):
		error_label.text = ""
	if is_instance_valid(error_label2):
		error_label2.hide()
	
	# Podłączenie przycisków przez gui_input
	next_button.gui_input.connect(_on_next_button_gui_input)
	pay_button.gui_input.connect(_on_pay_button_gui_input)

func start_checkout(title: String, price: int) -> void:
	current_item_title = title
	current_item_price = price
	current_delivery_price = 0
	total_price = price
	selected_courier = ""
	
	# Czyszczenie pól
	name_input.clear()
	nip_input.clear()
	address_input.clear()
	city_input.clear()
	blik_input.clear()
	
	if is_instance_valid(error_label):
		error_label.text = ""
	if is_instance_valid(error_label2):
		error_label2.hide()
		
	# Pokazujemy Krok 1, ukrywamy resztę
	step1_invoice.show()
	step_2_delivery.hide()
	step3_blik.hide()
	show()

# KROK 1 -> KROK 2
func _on_next_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var success = await browser.loadProgress(1.5)
	
		if !success:
			browser.load_page("noIntenet")
			return
		
		# Walidacja danych do faktury
		'''if name_input.text.strip_edges().is_empty() or address_input.text.strip_edges().is_empty():
			if is_instance_valid(error_label2):
				error_label2.text = "Wypełnij dane do faktury!"
				error_label2.show()
			return
			
		if is_instance_valid(error_label2):
			error_label2.hide()'''
		
		# Wygenerowanie dostawców i przejście do kroku 2
		_generate_delivery_options()
		step1_invoice.hide()
		step_2_delivery.show()
		step3_blik.hide()

# KROK 2: Generowanie listy kurierów z losowymi cenami
func _generate_delivery_options() -> void:
	for child in delivery_list_container.get_children():
		child.queue_free()
		
	for courier in COURIERS:
		var price = randi_range(8, 22)
		
		if delivery_option_scene:
			var item = delivery_option_scene.instantiate()
			delivery_list_container.add_child(item)
			item.setup_option(courier, price)
			item.delivery_selected.connect(_on_delivery_selected)

# KROK 2 -> KROK 3 (Po wybraniu firmy kurierskiej)
func _on_delivery_selected(company_name: String, price: int) -> void:
	selected_courier = company_name
	current_delivery_price = price
	total_price = current_item_price + current_delivery_price
	
	if is_instance_valid(info_label):
		info_label.text = "Przedmiot: %d PLN\nDostawa (%s): %d PLN\nRazem: %d PLN" % [
			current_item_price, selected_courier, current_delivery_price, total_price
		]
	
	step1_invoice.hide()
	step_2_delivery.hide()
	step3_blik.show()

# KROK 3: Płatność BLIK
func _on_pay_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var entered_code = blik_input.text.strip_edges()
		
		# Pobranie całościowej kwoty (przedmiot + dostawa)
		var result = BankManager.verify_and_pay(entered_code, total_price)
		
		if result["success"]:
			process_successful_payment()
		else:
			if is_instance_valid(error_label):
				error_label.text = result["error"]

func process_successful_payment() -> void:
	hide()
	
	# Wysyłka SMS
	var sms_text = "Allegro: Zakupiono " + current_item_title + " (" + str(total_price) + " zł z dostawą " + selected_courier + "). Faktura VAT dla NIP: " + nip_input.text
	SMSManager.receive_sms("Allegro", sms_text)
	
	purchase_completed.emit(current_item_title, total_price, COURIERS.find(selected_courier))
	browser.load_page("allegro.pl")
