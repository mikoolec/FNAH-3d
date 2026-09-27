extends Node

signal balance_changed(new_balance: int)

var account_balance: int = 1500
var current_blik_code: String = ""

func generate_new_blik() -> String:
	var code = randi_range(100000, 999999)
	current_blik_code = str(code)
	return current_blik_code

func verify_and_pay(code: String, amount: int) -> Dictionary:
	# 1. Sprawdzamy, czy podany kod zgadza się z aktualnym kodem BLIK
	#if code.strip_edges() != current_blik_code or current_blik_code.is_empty():
		#return {"success": false, "error": "Niepoprawny lub wygasły kod BLIK!"}
	
	# 2. Sprawdzamy, czy gracz ma wystarczająco środków na koncie
	if account_balance < amount:
		return {"success": false, "error": "Brak wystarczających środków na koncie!"}
	
	# 3. Pobieramy pieniądze i unieważniamy użyty kod BLIK
	print("Stan konta PRZED: ", account_balance)
	account_balance -= amount
	print("Stan konta PO: ", account_balance)
	current_blik_code = "" # Kod BLIK jest jednorazowy
	balance_changed.emit(account_balance)
	
	return {"success": true, "error": ""}
