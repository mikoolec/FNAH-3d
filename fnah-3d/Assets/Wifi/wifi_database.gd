extends Node
class_name WifiDatabase

# Definicja sieci Wi-Fi w grze
static var networks = {
	"Domowe_WiFi_2.4G": {
		"password": "haslo_domowe",
		"speed_multiplier": 1.0, # Standardowa prędkość
		"security": "WPA2-Personal",
		"is_available": true # Możesz to zmieniać w locie w grze!
	},
	"Kawiarnia_FREE": {
		"password": "", # Brak hasła = otwarta sieć
		"speed_multiplier": 2.5, # Pobieranie trwa 2.5x dłużej (wolny net)
		"security": "Brak (Niezabezpieczona)",
		"is_available": true
	},
	"UKRYTA_SIEC_CORP": {
		"password": "super_tajne_haslo_123",
		"speed_multiplier": 0.2, # Super szybki internet (pobieranie błyskawiczne)
		"security": "WPA3-Enterprise",
		"is_available": false # Pojawi się np. dopiero po zhackowaniu czegoś
	}
}
