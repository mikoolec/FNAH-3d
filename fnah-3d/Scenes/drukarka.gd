extends StaticBody3D

@onready var drukarka = $"."
@onready var mesh = $MeshInstance3D
@onready var mat = mesh.material_override

var kartkaIn:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not mat is StandardMaterial3D:
		mat = StandardMaterial3D.new()
		mesh.material_override = mat
		
	# 3. Zmieniamy kolor Albedo (główny kolor powłoki)
	mat.albedo_color = Color.WHITE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if kartkaIn:
		mat.albedo_color = Color.WHITE
	else:
		mat.albedo_color = Color.RED

func interact():
	kartkaIn = false
		

func interact2():
	kartkaIn = true
