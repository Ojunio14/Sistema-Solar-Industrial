extends Node3D
class_name QuadtreeNode

# Dados passados pelo pai
var planet_data : PlanetData
var parent_planet : Node3D 
var player_camera : Node3D 

# Propriedades do Chunk
var depth : int = 0
var normal : Vector3
var chunk_origin : Vector2
var chunk_size : float

# Controle da Árvore
var children : Array[QuadtreeNode] = []
var mesh_instance : PlanetMeshFace = null
var is_split : bool = false

# --- CONFIGURAÇÃO DE LOD ---
const MAX_DEPTH = 8
# REDUZI DE 2.0 PARA 1.25
# Isso faz com que partes longe parem de se dividir, economizando performance
# e criando o efeito visual de "resolução menor ao longe".
const SPLIT_MULTIPLIER = 2.0#1.25

func initialize(_planet_data, _normal, _origin, _size, _depth, _parent_planet, _camera):
	planet_data = _planet_data
	normal = _normal
	chunk_origin = _origin
	chunk_size = _size
	depth = _depth
	parent_planet = _parent_planet
	player_camera = _camera
	
	update_lod()

func _process(delta):
	update_lod()

func update_lod():
	if not is_instance_valid(player_camera): return

	var center_point = _get_center_point_on_sphere()
	var dist = player_camera.global_position.distance_to(center_point)
	
	# A fórmula mágica do LOD
	var split_distance = (chunk_size * planet_data.radius) * SPLIT_MULTIPLIER
	
	# Regra: Se estiver perto o suficiente E não atingiu o limite, divide.
	if dist < split_distance and depth < MAX_DEPTH:
		if not is_split:
			split()
	
	# Regra: Se estiver longe, junta (merge).
	else:
		if is_split:
			merge()
		# Garante que se não está dividido, TEM QUE TER uma malha desenhada
		elif mesh_instance == null:
			create_mesh()

func split():
	is_split = true
	
	if mesh_instance:
		mesh_instance.queue_free()
		mesh_instance = null
	
	var half = chunk_size / 2.0
	
	create_child(chunk_origin, half)                      # Top-Left
	create_child(chunk_origin + Vector2(half, 0), half)   # Top-Right
	create_child(chunk_origin + Vector2(0, half), half)   # Bottom-Left
	create_child(chunk_origin + Vector2(half, half), half)# Bottom-Right

func merge():
	is_split = false
	
	for child in children:
		child.queue_free()
	children.clear()
	
	create_mesh()

func create_child(offset : Vector2, size : float):
	var child = QuadtreeNode.new()
	add_child(child)
	children.append(child)
	child.initialize(planet_data, normal, offset, size, depth + 1, parent_planet, player_camera)

func create_mesh():
	if mesh_instance != null: return

	mesh_instance = PlanetMeshFace.new()
	add_child(mesh_instance)
	
	mesh_instance.normal = normal
	mesh_instance.chunk_origin = chunk_origin
	mesh_instance.chunk_size = chunk_size
	
	mesh_instance.regenerate_mesh(planet_data)

func _get_center_point_on_sphere() -> Vector3:
	var axisA := Vector3(normal.y, normal.z, normal.x)
	var axisB : Vector3 = normal.cross(axisA)
	var center_perc = chunk_origin + Vector2(chunk_size, chunk_size) * 0.5
	var pointOnCube = normal + (center_perc.x - 0.5) * 2.0 * axisA + (center_perc.y - 0.5) * 2.0 * axisB
	
	var local_pos = pointOnCube.normalized() * planet_data.radius
	return parent_planet.to_global(local_pos)
