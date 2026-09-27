extends Node3D

var has_money: bool = false

var rand: int
var chosen_position: int
var pos1: int
var pos2: int 
var pos3: int
var spinning: bool = false

var multiplier: float
var money_input: float

@export var wh1: MeshInstance3D
@export var wh2: MeshInstance3D
@export var wh3: MeshInstance3D
@export var lev: MeshInstance3D
@export var animation: AnimationPlayer

var step_angle: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	step_angle = TAU / float(6)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func wireless_pay() -> void:
	money_input += GameplayNumbers.phone_transaction
	if ( money_input > 0 ):
		has_money = true
		BankManager.account_balance -= GameplayNumbers.phone_transaction
		BankManager.balance_changed.emit(BankManager.account_balance)
		GameplayNumbers.phone_transaction = 0

func interact(player = null) -> void:
	if ( ! spinning && has_money ):
		spin_slots()
		spin_lever()
	else:
		print ("no mony")

func spin_slots():
	spinning = true
	#has_money = false
	var reels: Array[MeshInstance3D] = [wh1, wh2, wh3]
	pos1 = randi() % 6
	pos2 = randi() % 6
	pos3 = randi() % 6
	var targets: Array[int] = [pos1, pos2, pos3]
	
	for i in range(reels.size()):
		var reel = reels[i]
		if not reel:
			continue
			
		var target_idx = targets[i]
		# Każdy kolejny bęben robi więcej obrotów (np. 6, 8, 10), żeby stawać po kolei
		var extra_spins = 6 + (i * 2)
		
		# Ostatni bęben po zatrzymaniu odblokowuje maszynę
		var is_last = (i == reels.size() - 1)
		_spin_single_reel(reel, target_idx, extra_spins, is_last)
		
		# Minimalne opóźnienie przed puszczeniem kolejnego bębna
		await get_tree().create_timer(0.05).timeout
	
	


func _spin_single_reel(reel: MeshInstance3D, target_index: int, full_spins: int, is_last_reel: bool = false) -> void:
	var tween = create_tween()
	
	# Docelowy kąt: stan obecny + pełne obroty + indeks symbolu
	var final_target_angle: float = reel.rotation.z + (full_spins * TAU) + (target_index * step_angle)
	# Punkt kończący fazę szybkiego kręcenia (1 pełny obrót przed metą)
	var fast_spin_end: float = final_target_angle - TAU

	# 1. Lekkie cofnięcie bębna (efekt naciągu sprężyny)
	tween.tween_property(reel, "rotation:z", reel.rotation.z - deg_to_rad(15.0), 0.15)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	# 2. Superszybki obrót ze stałą prędkością
	# Czas skaluje się z liczbą obrotów, żeby prędkość była spójna
	var fast_duration: float = 0.15 * full_spins
	tween.tween_property(reel, "rotation:z", fast_spin_end, fast_duration)\
		.set_trans(Tween.TRANS_LINEAR)

	# 3. Płynne dohamowanie z lekkim sprężynowaniem (overshoot)
	tween.tween_property(reel, "rotation:z", final_target_angle, 0.85)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	# 4. Czyszczenie kąta i callback zakończenia
	tween.tween_callback(func():
		reel.rotation.z = fposmod(reel.rotation.z, TAU)
		#on_complete.call()
		if (is_last_reel):
			spinning = false
			if ( pos1 == pos2 && pos2 == pos3 ):
				multiplier = 1.5
			elif (pos1 == pos2 || pos1 == pos3 || pos2 == pos3):
				multiplier = 1
			else:
				multiplier = 0.5
			multiplier += check_pos(pos1)
			multiplier += check_pos(pos2)
			multiplier += check_pos(pos3)
			money_input *= multiplier
	)

func payout() -> void:
	print(money_input)
	if ( money_input > 0 ):
		BankManager.account_balance += money_input
		money_input = 0
		animation.play("Animation")
		has_money = false
			

func check_pos(pos: int) -> float:
	match pos:
		0:
			return 0.1
		1:
			return 0.05
		2:
			return 0.02
		3:
			return 0.015
		4:
			return 0.01
		5:
			return 0.0
	return 0.0
		

func spin_lever():
	if not lev:
		return
	
	var lever_tween = create_tween()
	var original_rot: float = lev.rotation.z
	var pull_angle: float = original_rot + deg_to_rad(150.0) # Kąt wychylenia w dół

	# 1. Szybki, mocny skok w dół
	lever_tween.tween_property(lev, "rotation:z", pull_angle, 0.08)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
		
	# 2. Wolny, płynny powrót w górę na sprężynie
	lever_tween.tween_property(lev, "rotation:z", original_rot, 1)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
