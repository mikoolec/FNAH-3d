extends Node

# Sygnały informujące resztę systemu o zmianach
signal connection_changed(is_connected: bool)

var current_wifi_name: String = ""
var is_connected_to_internet: bool = false
var current_speed_multiplier: float = 1.0

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
	connection_changed.emit(false)
