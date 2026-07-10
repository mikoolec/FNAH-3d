extends TextureButton

# Załaduj swoje tekstury (ikona aktywnego wifi i braku sieci)
@export var wifi_connected_icon: Texture2D
@export var wifi_disconnected_icon: Texture2D

@onready var wifi_popup: PanelContainer = $WifiPopup # Małe menu, domyślnie ukryte

func _ready() -> void:
	wifi_popup.hide()
	pressed.connect(_on_icon_pressed)
	
	# Słuchamy globalnego menedżera sieci i zmieniamy ikonę
	NetworkManager.connection_changed.connect(_update_icon)
	_update_icon(NetworkManager.is_connected_to_internet)

func _on_icon_pressed() -> void:
	if wifi_popup.visible:
		wifi_popup.hide()
	else:
		wifi_popup.show()
		_build_wifi_list()

func _update_icon(connected: bool) -> void:
	if connected:
		texture_normal = wifi_connected_icon
		tooltip_text = "Połączono z: " + NetworkManager.current_wifi_name
	else:
		texture_normal = wifi_disconnected_icon
		tooltip_text = "Brak dostępu do internetu"

# Dynamiczne budowanie listy sieci w wyskakującym okienku
func _build_wifi_list() -> void:
	var list_container = $WifiPopup/VBoxContainer/ScrollContainer/List # Wyszukaj swój VBox na listę
	
	# Czyszczenie starej listy
	for child in list_container.get_children():
		child.queue_free()
		
	# Sprawdzamy bazę danych
	for wifi_name in WifiDatabase.networks.keys():
		var data = WifiDatabase.networks[wifi_name]
		
		# Pokazujemy tylko sieci, które są aktualnie "dostępne" w grze
		if data["is_available"]:
			var btn = Button.new()
			btn.text = wifi_name #+ " (" + data["security"] + ")"
			
			# Jeśli to aktualna sieć, zaznacz ją
			if NetworkManager.current_wifi_name == wifi_name:
				btn.text += " [POŁĄCZONO]"
				
			btn.pressed.connect(func(): _attempt_connect(wifi_name, data))
			list_container.add_child(btn)

func _attempt_connect(wifi_name: String, data: Dictionary) -> void:
	# Jeśli sieć wymaga hasła i nie jesteśmy z nią połączeni
	if data["password"] != "" and NetworkManager.current_wifi_name != wifi_name:
		# Tutaj możesz wywołać małe okienko LineEdit do wpisania hasła.
		# Jeśli wpisane hasło == data["password"], wywołujesz:
		NetworkManager.connect_to_net(wifi_name)
	else:
		# Sieć otwarta
		NetworkManager.connect_to_net(wifi_name)
		
	wifi_popup.hide()
