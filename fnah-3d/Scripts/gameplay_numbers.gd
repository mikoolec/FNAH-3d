# Global.gd
extends Node

enum paczko_firmy { INPOST, ORLEN, ALLEGRO, DHL, PP, DPD }
enum paczka_zawartosc { C, M, Y, K, Shit }

class paczka:
	var firma: paczko_firmy
	var kod: int
	var zawartosc: paczka_zawartosc
	
	func _init(p_firma: paczko_firmy, p_kod: int, p_zawartosc: paczka_zawartosc):
		firma = p_firma
		kod = p_kod
		zawartosc = p_zawartosc

# Zmienna dostępna z każdego miejsca w projekcie
var active_ladder_zones: int = 0

var paczki: Array[paczka] = []

func _ready() -> void:
	prepare_package(paczko_firmy.INPOST, 123654, paczka_zawartosc.K)

func is_player_in_any_zone() -> bool:
	return active_ladder_zones > 0

func reset_zones() -> void:
	active_ladder_zones = 0

func prepare_package( firma: paczko_firmy, kod_otwarcia: int , zawartosc: paczka_zawartosc ):
		paczki.append(paczka.new(firma, kod_otwarcia, zawartosc))
