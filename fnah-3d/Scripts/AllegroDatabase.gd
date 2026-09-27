extends Node

# Baza możliwych sprzedawców
static var sellers: Array[String] = [
	"SuperTech_PL",
	"Elektronika24",
	"Janusz_Biznesu",
	"MagaStore",
	"Okazje_Gamer",
	"PiotrEx",
	"Lombard_Online"
]

# Baza możliwych przedmiotów z sugerowanym zakresem cenowym [cena_min, cena_max]
static var items_catalog: Array[Dictionary] = [
	{"name": "Laptop Gamingowy RTX 4060", "min_price": 3200, "max_price": 4500},
	{"name": "Smartfon 6.7\" 120Hz 256GB", "min_price": 1200, "max_price": 2200},
	{"name": "Klawiatura Mechaniczna RGB", "min_price": 150, "max_price": 350},
	{"name": "Myszka Bezprzewodowa 26k DPI", "min_price": 180, "max_price": 290},
	{"name": "Słuchawki Wokółuszne ANC", "min_price": 250, "max_price": 600},
	{"name": "Monitor 27\" IPS 165Hz", "min_price": 650, "max_price": 950},
	{"name": "Konsola do gier 1TB", "min_price": 1800, "max_price": 2400},
	{"name": "Karta Graficzna 12GB VRAM", "min_price": 1600, "max_price": 2300},
	{"name": "Pendrive 256GB USB 3.2", "min_price": 45, "max_price": 90},
	{"name": "Fotel Ergonomiczny Biurowy", "min_price": 400, "max_price": 850}
]

# Funkcja generująca losową ofertę
static func generate_random_auction() -> Dictionary:
	var item_data = items_catalog.pick_random()
	var seller = sellers.pick_random()
	
	var price = randi_range(item_data["min_price"], item_data["max_price"])
	# Wylosowanie czasu trwania oferty (np. od 15 do 60 sekund)
	var duration = randf_range(40.0, 70.0)
	
	return {
		"title": item_data["name"],
		"seller": seller,
		"price": price,
		"duration": duration
	}
