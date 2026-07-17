extends MarginContainer

@onready var url_input: LineEdit = $App/PasekAdresu/UrlInput
@onready var content_zone: Control = $App/ContentZone
@onready var progress_bar: ProgressBar = $App/PasekAdresu/UrlInput/PageProgressBar

var current_tween: Tween
var is_loading_page = false

# Rejestr stron: "wpisywany link": "ścieżka do sceny"
const INTERNET_PAGES = {
	"google.pl": "res://Assets/PC/Websites/google_pl.tscn",
	"skibidi.pl": "res://Assets/PC/Websites/skibidi_pl.tscn",
	"sharepoint.com": "res://Assets/PC/Websites/sharepoint.tscn",
	"email.com": "res://Assets/PC/Websites/email.tscn",
	"noIntenet": "res://Assets/PC/Websites/noInternet.tscn",
	"404": "res://Assets/PC/Websites/error_404.tscn" # Strona, gdy link nie istnieje
}

var current_page_node: Node = null

func _ready() -> void:
	progress_bar.value = 0.0
	progress_bar.hide()
	# Podłączamy wciśnięcie Enter w pasku adresu
	url_input.text_submitted.connect(_on_url_submitted)
	# Ładujemy stronę startową na początek
	#load_page("google.pl")

func _on_url_submitted(new_url: String) -> void:
	# Czyszczenie wpisu z wielkich liter i spacji
	var clean_url = new_url.strip_edges().to_lower()
	load_page(clean_url)

func load_page(url: String) -> void:
	if is_loading_page: return
	# 1. Usunięcie starej strony z ekranu, jeśli jakaś jest
	if current_page_node:
		current_page_node.queue_free()
	
	# 2. Sprawdzenie, czy strona istnieje w naszym "internecie"
	var page_path = ""
	if INTERNET_PAGES.has(url):
		page_path = INTERNET_PAGES[url]
	else:
		page_path = INTERNET_PAGES["404"] # Jeśli nie ma, daj błąd 404
	
	if not NetworkManager.is_connected_to_internet: 
		page_path = INTERNET_PAGES["noIntenet"]
		@warning_ignore("confusable_local_declaration")
		var page_scene = load(page_path)
		if page_scene:
			current_page_node = page_scene.instantiate()
			content_zone.add_child(current_page_node)
		return
		
	is_loading_page = true
	var success = await loadProgress(1.5)
	
	if !success: page_path = INTERNET_PAGES["noIntenet"]
	
	var page_scene = load(page_path)
	if page_scene:
		current_page_node = page_scene.instantiate()
		content_zone.add_child(current_page_node)
		url_input.text = url # Aktualizujemy pasek adresu
	
	is_loading_page = false

func _on_search_pressed() -> void:
	_on_url_submitted(url_input.text)

func loadProgress(load_time: float):
	if current_tween and current_tween.is_running():
		current_tween.kill()
		
	var final_load_time = load_time * NetworkManager.current_speed_multiplier
	
	progress_bar.value = 0.0
	progress_bar.show()
	
	current_tween = create_tween()
	current_tween.tween_property(progress_bar, "value", 100.0, final_load_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	
	# Monitorujemy proces ręcznie w pętli
	while current_tween and current_tween.is_running():
		# KLUCZ: Jeśli w dowolnym momencie (klatce) wypadnie internet:
		if not NetworkManager.is_connected_to_internet:
			current_tween.kill() # Natychmiast zabijamy tweena
			progress_bar.hide()  # Ukrywamy pasek
			return false         # Przerywamy funkcję i zwracamy porażkę
			
		# Czekamy dokładnie jedną klatkę fizyki/procesu przed kolejnym sprawdzeniem
		await get_tree().process_frame
	
	progress_bar.hide()
	
	if not NetworkManager.is_connected_to_internet: return false
	
	return true
