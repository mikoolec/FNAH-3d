extends AnimatableBody3D

# Ścieżka prowadzi bezpośrednio do drzwi_G, bo to Twój bezpośredni rodzic
@onready var core = $".." 

func _ready() -> void:
	set_as_top_level(false)

# Ta funkcja odpala się, gdy gracz celuje w tego "ducha"
func interact() -> void:
	if core and core.has_method("toggle_doors"):
		core.toggle_doors()