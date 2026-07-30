# GLOBAL

extends Node

# Wszystko co się może zepsućs

var HarcWifiBroken: bool = false
var KorkiBroken: bool = false
var KorkiKableBroken: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func break_korki() -> void:
	var sources = get_tree().get_nodes_in_group("SabotageSources")
	
	for korki in sources:
		# Upewniamy się, że obiekt ma tę funkcję i ją wywołujemy
		if korki.has_method("break_breakers"):
			
			if !KorkiKableBroken:
				print("Sabotage - zepsuto korki")
			
				var good_break: bool = randi_range(0, 2)
				if !good_break:
					KorkiKableBroken = true
					print("Sabotage - zepsuto kable")
			KorkiBroken = true
			korki.break_breakers()

func off_korki() -> void:
	KorkiBroken = true
	#print("Sabotage - zgaszono korki")

	
func fix_korki_kable() -> void:
	KorkiKableBroken = false
	print("Sabotage - naprawiono kable")

func break_wifi() -> void:
	var sources = get_tree().get_nodes_in_group("SabotageSources")
	
	for router in sources:
		# Upewniamy się, że obiekt ma tę funkcję i ją wywołujemy
		if router.has_method("break_school_wifi"):
			router.break_school_wifi()
			HarcWifiBroken = true
			print("Sabotage - zepsuto wifi")

func does_wifi_work() -> bool:
	var sources = get_tree().get_nodes_in_group("SabotageSources")
	
	for router in sources:
		# Upewniamy się, że obiekt ma tę funkcję i ją wywołujemy
		if router.has_method("does_school_wifi_work"):
			if router.does_school_wifi_work() and !HarcWifiBroken:
				return true
			else:
				return false
	return false

func do_korki_work() -> bool:
	if KorkiBroken || KorkiKableBroken:
		return false
	return true

func fix_wifi() -> void:
	HarcWifiBroken = false
	print("Sabotage - naprawiono wifi")

func force_wifi_fix() -> void:
	var sources = get_tree().get_nodes_in_group("SabotageSources")
	
	for router in sources:
		# Upewniamy się, że obiekt ma tę funkcję i ją wywołujemy
		if router.has_method("force_fix"):
			router.force_fix()
			print("Sabotage - wymuszono naprawę wifi")


func force_korki_kable_fix() -> void:
	KorkiKableBroken = false
	KorkiBroken = false
	print("Sabotage - wymuszono naprawę korków")

func off_wifi() -> void:
	HarcWifiBroken = true
	print("Sabotage - zgaszono wifi")

func fix_korki() -> void:
	if !KorkiKableBroken:
		KorkiBroken = false
		print("Sabotage - naprawiono korki")
	else:
		break_korki()
