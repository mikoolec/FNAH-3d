extends Control

@onready var chat_list: ItemList = $VBoxContainer/ChatList
@onready var chat_view: VBoxContainer = $VBoxContainer/ChatView
@onready var back_button: Button = $VBoxContainer/ChatView/PanelContainer/BackButton
@onready var contact_name_label: Label = $VBoxContainer/ChatView/PanelContainer/ContactNameLabel
@onready var messages_container: VBoxContainer = $VBoxContainer/ChatView/ScrollContainer/MessagesContainer
@onready var title_label: Label = $VBoxContainer/TitleLabel

@export var incoming_bubble_scene: PackedScene # Przypisz MessageBubble.tscn
@export var outgoing_bubble_scene: PackedScene # Przypisz MessageBubbleOutgoing.tscn

var current_active_chat: String = ""

func _ready() -> void:
	# Podłączamy się pod sygnał globalnego menedżera
	SMSManager.sms_received.connect(_on_sms_received)
	
	# Podłączenie zdarzeń UI
	chat_list.item_selected.connect(_on_chat_selected)
	if back_button:
		back_button.gui_input.connect(_on_back_button_gui_input)
	
	# Początkowy stan widoku
	chat_view.hide()
	chat_list.show()
	title_label.show()
	refresh_chat_list()

func _on_sms_received(_sender: String, _message: String) -> void:
	refresh_chat_list()
	if current_active_chat == _sender:
		open_chat(_sender)

func refresh_chat_list() -> void:
	chat_list.clear()
	# Dodajemy do listy wszystkich nadawców ze słownika
	for sender in SMSManager.chats.keys():
		chat_list.add_item(sender)
	
	chat_list.deselect_all()

func _on_chat_selected(index: int) -> void:
	var sender_name = chat_list.get_item_text(index)
	open_chat(sender_name)

func open_chat(sender_name: String) -> void:
	current_active_chat = sender_name
	contact_name_label.text = sender_name
	
	# Czyszczenie starych dymków
	for child in messages_container.get_children():
		child.queue_free()
	
	# 1. Wyliczamy limit 75% szerokości obszaru wiadomości
	var max_width: float = messages_container.size.x * 0.75
	if max_width <= 0:
		max_width = 250.0 # Wartość awaryjna, jeśli kontener nie jest jeszcze widoczny
	
	var history = SMSManager.chats.get(sender_name, [])
	for msg in history:
		var bubble
		if sender_name == "Ty":
			bubble = outgoing_bubble_scene.instantiate()
		else:
			bubble = incoming_bubble_scene.instantiate()
		
		# Dodajemy dymek do drzewa najpierw, aby Godot wyliczył rozmiary tekstu
		messages_container.add_child(bubble)
		
		var msg_label: Label = bubble.get_node("MarginContainer/Label")
		msg_label.text = msg
		msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		# 2. Wyłączamy chwilowo autowrap, aby sprawdzić naturalną szerokość tekstu w jednej linii
		msg_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		var natural_size = msg_label.get_combined_minimum_size().x
		
		# 3. Jeśli tekst jest szerszy niż 75% ekranu, włączamy autowrap i ograniczamy szerokość
		if natural_size > max_width:
			msg_label.custom_minimum_size.x = max_width
			msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			# Krótka wiadomość: szerokość dopasowuje się dokładnie do tekstu
			msg_label.custom_minimum_size.x = 0
			msg_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	chat_list.hide()
	chat_view.show()
	title_label.hide()

func _on_back_button_gui_input(event: InputEvent) -> void:
	# Wyzwalamy akcję od razu w momencie wciśnięcia lewego przycisku myszy
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_back_pressed()

func _on_back_pressed() -> void:
	print("POWRÓT DO LISTY CZATÓW")
	current_active_chat = ""
	chat_list.deselect_all()
	chat_view.hide()
	chat_list.show()
	title_label.show()
