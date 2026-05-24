extends MarginContainer

@onready var url_input: LineEdit = $App/PasekAdresu/UrlInput
@onready var content_zone: Control = $App/ContentZone

# Rejestr stron: "wpisywany link": "ścieżka do sceny"
const INTERNET_PAGES = {
	"google.pl": "res://Assets/PC/Websites/google_pl.tscn",
	"skibidi.pl": "res://Assets/PC/Websites/skibidi_pl.tscn",
	"sharepoint.com": "res://Assets/PC/Websites/sharepoint.tscn",
	"404": "res://Assets/PC/Websites/error_404.tscn" # Strona, gdy link nie istnieje
}

var current_page_node: Node = null

func _ready() -> void:
	# Podłączamy wciśnięcie Enter w pasku adresu
	url_input.text_submitted.connect(_on_url_submitted)
	# Ładujemy stronę startową na początek
	load_page("google.pl")

func _on_url_submitted(new_url: String) -> void:
	# Czyszczenie wpisu z wielkich liter i spacji
	var clean_url = new_url.strip_edges().to_lower()
	load_page(clean_url)

func load_page(url: String) -> void:
	# 1. Usunięcie starej strony z ekranu, jeśli jakaś jest
	if current_page_node:
		current_page_node.queue_free()
	
	# 2. Sprawdzenie, czy strona istnieje w naszym "internecie"
	var page_path = ""
	if INTERNET_PAGES.has(url):
		page_path = INTERNET_PAGES[url]
	else:
		page_path = INTERNET_PAGES["404"] # Jeśli nie ma, daj błąd 404
		
	# 3. Załadowanie nowej sceny (instancjonowanie)
	var page_scene = load(page_path)
	if page_scene:
		current_page_node = page_scene.instantiate()
		content_zone.add_child(current_page_node)
		url_input.text = url # Aktualizujemy pasek adresu
