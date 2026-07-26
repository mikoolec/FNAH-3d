# ItemDB.gd
extends Node

# Tutaj wpisujesz unikalne nazwy (ID) swoich przedmiotów.
# Używaj dokładnie takich samych nazw w całym projekcie.
const KNIFE = "noz"
const SHEET = "kartka"
const FILLEDSHEET = "kartkazapis"
const KEY = "klucz"
const NONE = "brak"
const TRASHBAG = "woreksmieci"
const TUSZC = "tuszC"
const TUSZM = "tuszM"
const TUSZY = "tuszY"
const TUSZK = "tuszK"

# Słownik, który łączy tekstowe ID z plikiem sceny .tscn
# WPISZ TUTAJ SWOJE DOKŁADNE ŚCIEŻKI DO PLIKÓW!
const ITEM_SCENES = {
	KEY: "res://Scenes/Items/Klucz.tscn",
	TRASHBAG: "res://Scenes/Items/WorekSmieci.tscn",
	SHEET: "res://Scenes/Items/kartka.tscn",
	FILLEDSHEET: "res://Scenes/Items/kartkazapis.tscn",
	TUSZC: "res://Scenes/Items/tusz_c.tscn",
	TUSZM: "res://Scenes/Items/tusz_m.tscn",
	TUSZY: "res://Scenes/Items/tusz_y.tscn",
	TUSZK: "res://Scenes/Items/tusz_k.tscn"
}

# Bezpieczna funkcja do pobierania sceny
func get_item_scene(item_id: String) -> PackedScene:
	if ITEM_SCENES.has(item_id):
		return load(ITEM_SCENES[item_id])
	return null
