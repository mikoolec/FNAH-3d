extends Node

# Sygnały informujące resztę systemu o zmianach
signal connection_changed(is_connected: bool)

var current_wifi_name: String = ""
var is_connected_to_internet: bool = false
var current_speed_multiplier: float = 1.0   # mnożnik czasu sieci: 1.0 normalnie, 2.5 wolno, 0.2 szybko

# --- Dzielenie łącza ---
# Każdy, kto aktualnie coś pobiera z internetu, zgłasza się co klatkę przez report_transfer().
# Transfer, który przestał się zgłaszać (np. nie zdążył wywołać end_transfer), po tym czasie
# przestaje się liczyć.
const TRANSFER_TIMEOUT_MS := 500

var _transfers: Dictionary = {}             # klucz transferu -> czas ostatniego zgłoszenia (ms)


func _process(delta: float) -> void:
	if not current_wifi_name == "" and WifiDatabase.networks[current_wifi_name]["is_available"] == false: disconnect_from_net()


func connect_to_net(wifi_name: String) -> void:
	if WifiDatabase.networks.has(wifi_name):
		var net_data = WifiDatabase.networks[wifi_name]
		current_wifi_name = wifi_name
		if(net_data["speed_multiplier"] != 0.0):
			current_speed_multiplier = net_data["speed_multiplier"]
			is_connected_to_internet = true
		else:
			is_connected_to_internet = false
		connection_changed.emit(true)


func disconnect_from_net() -> void:
	current_wifi_name = ""
	is_connected_to_internet = false
	current_speed_multiplier = 1.0
	_transfers.clear()
	connection_changed.emit(false)


# Wołaj CO KLATKĘ, dopóki trwa przesył. Klucz identyfikuje transfer (np. &"update").
func report_transfer(key: StringName) -> void:
	_transfers[key] = Time.get_ticks_msec()


# Wołaj, gdy przesył się skończył, został przerwany albo wstrzymany.
func end_transfer(key: StringName) -> void:
	_transfers.erase(key)


# Ile transferów korzysta z łącza w tej chwili
func active_transfers() -> int:
	var now := Time.get_ticks_msec()
	var n := 0
	for key in _transfers.keys():
		if now - int(_transfers[key]) <= TRANSFER_TIMEOUT_MS:
			n += 1
		else:
			_transfers.erase(key)
	return n


# Mnożnik czasu uwzględniający podział łącza: szybkość sieci x liczba aktywnych transferów.
# Wołaj PO report_transfer(), żeby transfer liczył też samego siebie.
func effective_multiplier() -> float:
	return current_speed_multiplier * float(maxi(active_transfers(), 1))
