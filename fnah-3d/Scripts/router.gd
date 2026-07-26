extends Node3D

var isWifiWorking = true
var isRouterOn = false
@onready var light_mat: StandardMaterial3D = $LIGHT.get_active_material(0).duplicate()
@onready var anim_player = $AnimationPlayer

func _ready() -> void:
	# Przypisujemy zduplikowany materiał z powrotem do węzła
	$LIGHT.material_override = light_mat
	light_mat.albedo_color = Color(1,0,0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func interact():
	if anim_player:
		if ( !anim_player.is_playing() ):
			if isRouterOn:
				isRouterOn = false
				light_mat.albedo_color = Color(1,0,0)
				anim_player.play("Press")
			else:
				isRouterOn = true
				isWifiWorking = true
				light_mat.albedo_color = Color(0,1,0)
				anim_player.play("Press")

func break_wifi():
	isWifiWorking = false
	
	
