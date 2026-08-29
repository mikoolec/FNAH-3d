extends Control

@onready var display: Label = $VBoxContainer/DisplayLabel
@export var firma: GameplayNumbers.paczko_firmy
var entered_code: String = ""

func _ready() -> void:
	for button in $VBoxContainer/GridContainer.get_children():
		if button is Button:
			button.pressed.connect(_on_button_pressed.bind(button.text))

func _on_button_pressed(digit: String) -> void:
	if digit == "C":
		entered_code = ""
	else:
		entered_code += digit
	display.text = entered_code
	
	if entered_code.length() == 6:
		for i in range (0, GameplayNumbers.paczki.size() ):
			if entered_code.to_int() == GameplayNumbers.paczki[i].kod and firma == GameplayNumbers.paczki[i].firma:
				print("dobry kod")
				$"../..".open(GameplayNumbers.paczki[i].zawartosc)
				GameplayNumbers.paczki.remove_at(i)
				break
		entered_code = ""
	
	display.text = entered_code
