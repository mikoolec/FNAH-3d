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
	"allegro.pl": "res://Assets/PC/Websites/allegro.tscn",
	"wagrowiec.zhp.wlkp.pl": "res://Assets/PC/Websites/hufiecStrona.tscn",
	"noIntenet": "res://Assets/PC/Websites/noInternet.tscn",
	"404": "res://Assets/PC/Websites/error_404.tscn" # Strona, gdy link nie istnieje
}

var current_page_node: Node = null
var current_page_url: String = ""

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
	current_page_url = url
	
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

var _load_id: int = 0   # nowe ładowanie wypiera stare

func loadProgress(load_time: float):
	_load_id += 1
	var my_id := _load_id
	progress_bar.value = 0.0
	progress_bar.show()

	var progress := 0.0   # 0..1
	while progress < 1.0:
		if my_id != _load_id:
			return NetworkManager.is_connected_to_internet   # wyparte przez nowsze ładowanie

		# W dowolnym momencie może wypaść internet
		if not NetworkManager.is_connected_to_internet:
			NetworkManager.end_transfer(&"browser_page")
			progress_bar.hide()
			return false

		NetworkManager.report_transfer(&"browser_page")
		progress += get_process_delta_time() / (load_time * NetworkManager.effective_multiplier())
		progress_bar.value = 100.0 * sin(clampf(progress, 0.0, 1.0) * PI / 2.0)
		await get_tree().process_frame

	NetworkManager.end_transfer(&"browser_page")
	progress_bar.hide()

	if not NetworkManager.is_connected_to_internet:
		return false

	return true
