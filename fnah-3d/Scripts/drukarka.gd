extends StaticBody3D

@onready var drukarka = $"."
@onready var mesh = $printer
@onready var anim_player = $printer/AnimationPlayer
@onready var ink_player = $printer/printer_inks_animations/AnimationPlayer

var kartkaIn:bool = false
var kartkaSave:bool = false

var animki: Array[String] = [ "PourC", "PourM", "PourY", "PourK" ]
var tusze:Array[int] = [100, 100, 100, 100]
enum kolory { CYAN, MAGENTA, YELLOW, KEY }

var pouring: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim_player.play("Use")
	ink_player.play("Reset")
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if kartkaIn and !kartkaSave:
		kartkaSave = true
		anim_player.play("Load")
	elif !kartkaIn and kartkaSave:
		kartkaSave = false
		anim_player.play("Use")
		
		for i in range(4):
			tusze[i] -= randi_range(5, 20)
			if tusze[i] < 0: tusze[i] = 0
			print("%d" % tusze[i])

func tusze_level(type: kolory) -> int:
	for i in range(4):
		if ( i == type ):
			return tusze[i]
	return 0

func fill_tusz_old(type: kolory) -> void:
	for i in range(4):
		if ( i == type ):
			
			ink_player.play(animki[i])
			tusze[i] = clamp(tusze[i]+75,0,100)
			for j in range(4):
				if tusze[j] < 0: tusze[j] = 0
				print("%d" % tusze[j])


func fill_tusz(type: kolory) -> void:
	for i in range(4):
		if i == type:
			pouring = true
			var anim_name = animki[i]
			ink_player.play(anim_name)
			
			ink_player.animation_finished.connect(func(finished_anim: StringName):
				if finished_anim == anim_name:
					pouring = false
			, CONNECT_ONE_SHOT)
			
			# --- PARAMETRY CZASOWE I ILOŚCIOWE ---
			var delay_start: float = 1.2   # 'n' - opóźnienie od startu animacji
			
			var seg1_duration: float = 0.4 # 'm' - czas trwania 1. nalewania
			var seg1_amount: float = 15.0  # ile dolewa w 1. etapie
			
			var wait_time: float = 1.05     # 'k' - pauza między nalewaniami
			
			var seg2_duration: float = 1.3 # czas trwania 2. nalewania
			var seg2_amount: float = 60.0  # ile dolewa w 2. etapie
			# -------------------------------------
			
			var v0: float = float(tusze[i])
			var v1: float = clampf(v0 + seg1_amount, 0.0, 100.0)
			var v2: float = clampf(v1 + seg2_amount, 0.0, 100.0)
			
			var tween = create_tween()
			
			# 1. Start po opóźnieniu 'n' i pierwsze nalewanie przez 'm' sekund (+25)
			tween.tween_method(
				func(val: float): tusze[i] = int(round(val)),
				v0, v1, seg1_duration
			).set_delay(delay_start).set_trans(Tween.TRANS_LINEAR)
			
			# 2. Pauza na 'k' sekund
			tween.tween_interval(wait_time)
			
			# 3. Drugie nalewanie (+50)
			tween.tween_method(
				func(val: float): tusze[i] = int(round(val)),
				v1, v2, seg2_duration
			).set_trans(Tween.TRANS_LINEAR)
			
			
			
			break
