extends Node3D

var isWifiWorking = true
var isRouterOn = false
var isPressing = false
var canBreakWifi = true
@onready var light_mat: StandardMaterial3D = $LIGHT.get_active_material(0).duplicate()
@onready var anim_player = $AnimationPlayer

func _ready() -> void:
	add_to_group("SabotageSources")
	
	# Przypisujemy zduplikowany materiał z powrotem do węzła
	$LIGHT.material_override = light_mat
	light_mat.albedo_color = Color(1,0,0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if isPressing:
		if ( !anim_player.is_playing() ) and isRouterOn:
			anim_player.play("Up")
			light_mat.albedo_color = Color(0,1,0)
			isPressing = false
			canBreakWifi = true
			
			isWifiWorking = true
			Sabotages.fix_wifi()
		elif ( !anim_player.is_playing() ) and !isRouterOn:
			anim_player.play("Up")
			light_mat.albedo_color = Color(1,0,0)
			isPressing = false
			canBreakWifi = true
			
			Sabotages.off_wifi()
		
	
	if !isRouterOn or !isWifiWorking: WifiDatabase.networks["Harcówka"]["is_available"] = false
	else: WifiDatabase.networks["Harcówka"]["is_available"] = true

func interact():
	if anim_player:
		if ( !anim_player.is_playing() ):
			canBreakWifi = false
			if isRouterOn:
				
				isPressing = true
				isRouterOn = false
				anim_player.play("Press")
			else:
				isRouterOn = true
				isPressing = true
				anim_player.play("Press")

func force_fix():
	isRouterOn = true
	isWifiWorking = true
	Sabotages.fix_wifi()
	isPressing = true
	anim_player.play("Press")

func break_school_wifi():
	if canBreakWifi:
		isWifiWorking = false

func does_school_wifi_work():
	if isRouterOn:
		return isWifiWorking
	else:
		return false
	
	
