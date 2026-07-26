extends Control

signal confirmed(result: bool)

@onready var message_label: Label = $WindowPanel/VBoxContainer/Label
@onready var btn_ok: Button = $WindowPanel/VBoxContainer/HBoxContainerButtons/BtnOk
@onready var btn_yes: Button = $WindowPanel/VBoxContainer/HBoxContainerButtons/BtnYes
@onready var btn_no: Button = $WindowPanel/VBoxContainer/HBoxContainerButtons/BtnNo
@onready var close_button: TextureButton = $WindowPanel/VBoxContainer/HBoxContainer/CloseButton

# Funkcja konfigurująca okienko po jego stworzeniu
func setup(text: String, use_yes_no: bool) -> void:
	message_label.text = text
	
	if use_yes_no:
		btn_ok.hide()
		btn_yes.show()
		btn_no.show()
	else:
		btn_ok.show()
		btn_yes.hide()
		btn_no.hide()

func _ready() -> void:
	btn_ok.pressed.connect(_on_btn_ok_pressed)
	btn_yes.pressed.connect(_on_btn_yes_pressed)
	btn_no.pressed.connect(_on_btn_no_pressed)
	close_button.pressed.connect(_on_btn_exit_pressed)

func _on_btn_ok_pressed() -> void:
	confirmed.emit(true)
	queue_free()

func _on_btn_yes_pressed() -> void:
	confirmed.emit(true)
	queue_free()

func _on_btn_no_pressed() -> void:
	confirmed.emit(false)
	queue_free()

func _on_btn_exit_pressed() -> void:
	confirmed.emit(false)
	queue_free()
