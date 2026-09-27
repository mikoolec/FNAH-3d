extends Control

@export var auction_item_scene: PackedScene # Przypisz scenę AuctionItem.tscn w Inspectorze

@onready var items_container: VBoxContainer = $VBoxContainer/ScrollContainer/ItemsContainer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var checkout_view: Control = $VBoxContainer/CheckoutView

@onready var browser: MarginContainer = get_node("../../..")

var item_pending_purchase: Node = null

func _ready() -> void:
	GameplayNumbers.wyslij_paczke.connect(_on_wyslij_paczke)
	
	# Podłączamy sygnał zakończenia zakupu z widoku CheckoutView
	if checkout_view:
		checkout_view.purchase_completed.connect(_on_purchase_completed)
	
	# Generujemy początkową listę przedmiotów (np. 5 na start)
	for i in range(10):
		add_random_auction()
	
	# Konfiguracja timera dla losowego pojawiania się nowych aukcji
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	schedule_next_spawn()

func open_checkout(title: String, price: int, item_node: Node) -> void:
	var success = await browser.loadProgress(1.5)
	
	if !success:
		browser.load_page("noIntenet")
		return
	
	item_pending_purchase = item_node
	
	# Pokazujemy widok zakupu i przekazujemy mu dane aukcji
	if checkout_view:
		checkout_view.start_checkout(title, price)
		items_container.hide()

# Reakcja na udaną płatność BLIK
func _on_purchase_completed(_title: String, _price: int, _firma: int) -> void:
	var p = GameplayNumbers.paczka.new(_firma, randi_range(100000, 999999), get_zawartosc_by_name(_title))
	
	# Dajemy paczce losowy czas odliczania np. od 3 do 10 sekund
	GameplayNumbers.zarejestruj_paczke(p, 3.0, 10.0)
	
	# Jeśli kupiony przedmiot wciąż istnieje na liście, usuwamy go
	if is_instance_valid(item_pending_purchase):
		item_pending_purchase.queue_free()
		item_pending_purchase = null
	
	

func add_random_auction() -> void:
	var auction_data = AllegroDatabase.generate_random_auction()
	var new_item = auction_item_scene.instantiate()
	
	# Dodajemy nowy przedmiot na górę listy (index 0) lub na dół
	items_container.add_child(new_item)
	items_container.move_child(new_item, 0) # Nowe aukcje pojawiają się na samej górze
	
	new_item.setup_auction(auction_data)

func _on_spawn_timer_timeout() -> void:
	# Losujemy ile przedmiotów ma się pojawić (np. od 1 do 3)
	var items_to_spawn = randi_range(1, 5)
	for i in range(items_to_spawn):
		add_random_auction()
	
	# Planujemy kolejny losowy czas pojawienia się ofert
	schedule_next_spawn()

func schedule_next_spawn() -> void:
	# Nowe oferty będą się pojawiać losowo co 3 do 8 sekund
	var random_delay = randf_range(30.0, 60.0)
	spawn_timer.start(random_delay)


func _on_wyslij_paczke(p: GameplayNumbers.paczka) -> void:
	print("Wysyłam paczkę z zawartością: ", p.zawartosc, " ", p.firma)
	# Tutaj podpinasz swoją własną logikę wysyłania!

static func get_zawartosc_by_name(item_name: String):
	for item in AllegroDatabase.items_catalog:
		if item["name"] == item_name:
			# Pobieramy wartość klucza "zawartosc", a jeśli go nie ma, zwracamy null
			return item.get("zawartosc", null)
	
	# Jeśli przedmiot o takiej nazwie w ogóle nie istnieje w katalogu
	return null
