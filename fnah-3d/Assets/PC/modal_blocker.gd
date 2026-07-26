extends Button

@onready var audio_player: AudioStreamPlayer = $"../AudioStreamPlayer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio_player.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_down() -> void:
	audio_player.play()
