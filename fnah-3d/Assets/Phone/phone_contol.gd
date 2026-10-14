extends Control

# Odwołania do elementów interfejsu
@onready var authenticator_app: Control = $AuthentcatorApp
@onready var authenticator_icon: TextureButton = $AuthenticatorIcon
@onready var home_button: TextureButton = $ControlBar/HomeButton
@onready var zegar: Label = $Zegar

var czas: String = "00:00"

func _ready() -> void:
	GameManager.time_changed.connect(func(t): czas = t)

func _process(delta: float) -> void:
	zegar.text = czas

func _on_back_button_pressed() -> void:
	pass # Replace with function body.
