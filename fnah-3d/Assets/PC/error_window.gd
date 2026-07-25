extends Control

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
	# Podpięcie zamykania okienka pod przyciski
	btn_ok.pressed.connect(queue_free)
	btn_yes.pressed.connect(queue_free)
	btn_no.pressed.connect(queue_free)
	close_button.pressed.connect(queue_free)
	
	# Jeśli masz przycisk X na pasku tytułowym:
	# $VBoxContainer/TitleBar/CloseButton.pressed.connect(queue_free)
