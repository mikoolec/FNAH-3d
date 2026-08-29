extends Node3D

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func open( srodek: GameplayNumbers.paczka_zawartosc ) -> void:
	print("lepszy kod")
	var x = -1
	var y = -1
	while ( (x == 3 and y == 3) or ( x == 3 and y == 4 ) or ( x<1 and y<1 ) ):
		x = randi()%8+1
		y = randi()%5+1
	print("x ",x," y ",y)
	
	var nazwa_mesha = "D" + str(y) + str(x)
	var drzwiczki = get_node_or_null(nazwa_mesha)
	var tween = create_tween()
	if drzwiczki:
		tween.tween_property(drzwiczki, "rotation_degrees:y", -90.0, 0.5).set_trans(Tween.TRANS_SINE)
		print("rotato rotato")
	else:
		print("blad brak drzwiczek")
	
