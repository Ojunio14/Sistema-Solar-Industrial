@tool
extends Node3D

# Arraste o Resource PlanetData aqui
@export var planet_data : PlanetData 
# Arraste o Player ou Camera3D aqui
@export var viewer : Node3D 

func _ready():
	generate_planet()

func generate_planet():
	# Limpa filhos antigos para não duplicar
	for child in get_children():
		child.queue_free()
	
	if not planet_data or not viewer:
		return

	# As 6 direções da Cube Sphere
	var directions = [
		Vector3.UP, Vector3.DOWN, 
		Vector3.LEFT, Vector3.RIGHT, 
		Vector3.FORWARD, Vector3.BACK
	]
	
	for dir in directions:
		var root_face = QuadtreeNode.new()
		add_child(root_face)
		
		# INICIALIZAÇÃO DA RAIZ:
		# Origin: (0, 0) -> Começa no canto
		# Size: 1.0 -> Cobre a face inteira (100%)
		# Depth: 0 -> Nível inicial
		root_face.initialize(planet_data, dir, Vector2(0,0), 1.0, 0, self, viewer)
