# Global.gd
extends Node

enum paczko_firmy { INPOST, ORLEN, ALLEGRO, DHL, PP, DPD }
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

func _ready() -> void:
	fill_paczkomaty()
	prepare_package(paczko_firmy.INPOST, 111111, paczka_zawartosc.K)
	prepare_package(paczko_firmy.DPD, 111111, paczka_zawartosc.C)
	prepare_package(paczko_firmy.DHL, 111111, paczka_zawartosc.Y)
	prepare_package(paczko_firmy.ORLEN, 111111, paczka_zawartosc.M)

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
