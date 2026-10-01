# Global.gd
extends Node

var money: float = 1000.0
var phone_transaction: float = 0

enum paczko_firmy { INPOST, ORLEN, DHL, DPD, ALLEGRO, PP, NONE }
enum paczka_zawartosc { C, M, Y, K, Shit }
enum paczkomat_state {CLOSED, OPENED}

class paczka:
	var firma: paczko_firmy
	var kod: int
	var zawartosc: paczka_zawartosc
	
	func _init(p_firma: paczko_firmy, p_kod: int, p_zawartosc: paczka_zawartosc):
		firma = p_firma
		kod = p_kod
		zawartosc = p_zawartosc

class stan_paczkomatu:
	var firma: paczko_firmy
	var stan: paczkomat_state
	
	func _init(p_firma: paczko_firmy, p_stan: paczkomat_state):
		firma = p_firma
		stan = p_stan

# Zmienna dostępna z każdego miejsca w projekcie
var active_ladder_zones: int = 0

var paczkomaty: Array[stan_paczkomatu] = []
var paczki: Array[paczka] = []

#----------------------------------------------------------

signal wyslij_paczke(p: paczka)

# Słownik aktywnych paczek i ich timerów
var aktywne_paczki: Array[paczka] = []

# Funkcja dodająca paczkę do kolejki i uruchamiająca odliczanie
func zarejestruj_paczke(nowa_paczka: paczka, min_czas: float = 5.0, max_czas: float = 20.0) -> void:
	aktywne_paczki.append(nowa_paczka)
	
	var losowy_czas = randf_range(min_czas, max_czas)
	print("Paczka [kod: %d] oczekuje na wysyłkę (%d sek)..." % [nowa_paczka.kod, losowy_czas])
	
	# Uruchamiamy niezależne odliczanie dla tej konkretnej instancji paczki
	_odliczaj_dla_paczki(nowa_paczka, losowy_czas)

func _odliczaj_dla_paczki(p: paczka, czas: float) -> void:
	# Czekamy w tle określoną liczbę sekund
	await get_tree().create_timer(czas).timeout
	
	# Sprawdzamy czy paczka nadal znajduje się w liście aktywnych (czy nie została anulowana)
	if p in aktywne_paczki:
		aktywne_paczki.erase(p)
		print("Czas minął! Emituję event wysłania dla paczki o kodzie: ", p.kod)
		wyslij_paczke.emit(p)
		paczki.append(p)
		SMSManager.receive_sms("Allegro", "Kod paczki: %d" % p.kod)
		print(paczki, p.firma)

# Opcjonalna funkcja do anulowania odliczania paczki (np. anulowanie zamówienia)
func anuluj_paczke(p: paczka) -> void:
	if p in aktywne_paczki:
		aktywne_paczki.erase(p)
		print("Anulowano wysyłkę paczki o kodzie: ", p.kod)

#----------------------------------------------------------

func _ready() -> void:
	fill_paczkomaty()
	prepare_package(paczko_firmy.INPOST, 111111, paczka_zawartosc.K)
	prepare_package(paczko_firmy.DPD, 111111, paczka_zawartosc.C)
	prepare_package(paczko_firmy.DHL, 111111, paczka_zawartosc.Y)
	prepare_package(paczko_firmy.ORLEN, 111111, paczka_zawartosc.Shit)
	prepare_package(paczko_firmy.PP, 111111, paczka_zawartosc.Shit)
	prepare_package(paczko_firmy.ALLEGRO, 111111, paczka_zawartosc.C)

func is_player_in_any_zone() -> bool:
	return active_ladder_zones > 0

func reset_zones() -> void:
	active_ladder_zones = 0

func prepare_package( firma: paczko_firmy, kod_otwarcia: int , zawartosc: paczka_zawartosc ):
		paczki.append(paczka.new(firma, kod_otwarcia, zawartosc))

func fill_paczkomaty() -> void:
	for i in range (0,6):
		paczkomaty.append(stan_paczkomatu.new(i, paczkomat_state.CLOSED))

func close_paczkomat(firma: paczko_firmy) -> void:
	for i in range (0,6):
		if (paczkomaty[i].firma == firma):
			paczkomaty[i].stan = paczkomat_state.CLOSED

func open_paczkomat(firma: paczko_firmy) -> void:
	for i in range (0,6):
		if (paczkomaty[i].firma == firma):
			paczkomaty[i].stan = paczkomat_state.OPENED

func check_paczkomat(firma: paczko_firmy) -> String:
	for i in range (0,6):
		if (paczkomaty[i].firma == firma):
			if (paczkomaty[i].stan == paczkomat_state.CLOSED):
				return "closed"
			else:
				return "opened"
	return "n"
