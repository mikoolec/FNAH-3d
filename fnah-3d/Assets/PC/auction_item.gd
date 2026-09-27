extends PanelContainer

@onready var title_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/TitleLabel
@onready var seller_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/SellerLabel
@onready var price_label: Label = $MarginContainer/HBoxContainer/VBoxContainer2/PriceLabel
@onready var buy_button: Button = $MarginContainer/HBoxContainer/VBoxContainer2/BuyButton

var time_remaining: float = 0.0
var price_value: int = 0

func setup_auction(data: Dictionary) -> void:
	title_label.text = data["title"]
	seller_label.text = "Sprzedawca: " + data["seller"]
	price_value = data["price"]
	price_label.text = str(price_value) + " zł"
	time_remaining = data["duration"]
	
	# Połączenie guzika (pamiętaj o obsłudze gui_input jeśli jesteś w SubViewport)
	buy_button.gui_input.connect(_on_buy_button_gui_input)

func _process(delta: float) -> void:
	if time_remaining > 0:
		time_remaining -= delta
		if time_remaining <= 0:
			# Czas minął – przedmiot znika z listy
			queue_free()

func _on_buy_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Znajdujemy stronę Allegro i uruchamiamy proces zakupu
		var allegro_page = get_tree().current_scene.find_child("AllegroPage", true, false)
		if allegro_page:
			allegro_page.open_checkout(title_label.text, price_value, self)
