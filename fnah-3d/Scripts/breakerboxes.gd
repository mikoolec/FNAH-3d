extends Area3D

enum ElementType { BREAKER, SCREW, CABLE_LEFT, CABLE_RIGHT , PANEL_COLLIDER }

@export var type: ElementType
@export var id: int = 0

# Ta funkcja sprawi, że gracz ZOBACZY prompt i wywoła kliknięcie:
func interact() -> void:
	# Szukamy głównego węzła tabletu w górze drzewa i wywołujemy na nim interakcję
	var tablet_main = owner # lub get_node("/path/do/tabletu")
	if tablet_main and tablet_main.has_method("interact_with_element"):
		tablet_main.interact_with_element(self)
