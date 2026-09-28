extends HBoxContainer

signal delivery_selected(company_name: String, price: float)

@onready var company_label: Label = $CompanyNameLabel
@onready var price_label: Label = $PriceLabel
@onready var select_button: Button = $SelectButton

var current_company: String = ""
var current_price: float = 0.0

func setup_option(company_name: String, price: float) -> void:
	current_company = company_name
	current_price = price
	
	company_label.text = company_name
	price_label.text = "%.2f PLN" % price
	
	# Łączymy wciśnięcie przycisku "Wybierz"
	if not select_button.pressed.is_connected(_on_select_pressed):
		select_button.pressed.connect(_on_select_pressed)

func _on_select_pressed() -> void:
	delivery_selected.emit(current_company, current_price)
