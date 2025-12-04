@tool
extends MeshInstance3D
class_name PlanetMeshFace

@export var normal : Vector3

func regenerate_mesh(planet_data : PlanetData):
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var resolution : int = planet_data.resolution
	var num_vertices : int = resolution * resolution
	var num_indices : int = (resolution-1) * (resolution-1) * 6
	
	var vertex_array := PackedVector3Array()
	var uv_array := PackedVector2Array()
	var normal_array := PackedVector3Array()
	var index_array := PackedInt32Array()
	
	# Redimensiona e limpa (importante para o cálculo de normais funcionar)
	vertex_array.resize(num_vertices)
	uv_array.resize(num_vertices)
	normal_array.resize(num_vertices)
	normal_array.fill(Vector3.ZERO) # Limpa com zeros
	index_array.resize(num_indices)
	
	var tri_index : int = 0
	var axisA := Vector3(normal.y, normal.z, normal.x)
	var axisB : Vector3 = normal.cross(axisA)
	
	# --- PASSO 1: GERAÇÃO DOS VÉRTICES ---
	for y in range(resolution):
		for x in range(resolution):
			var i : int = x + y * resolution
			var percent := Vector2(x,y) / (resolution-1)
			
			var pointOnUnitCube : Vector3 = normal + (percent.x-0.5) * 2.0 * axisA + (percent.y-0.5) * 2.0 * axisB
			var pointOnUnitSphere := pointOnUnitCube.normalized()
			
			# Aplica a altura da imagem
			var pointOnPlanet := planet_data.point_on_planet(pointOnUnitSphere)
			vertex_array[i] = pointOnPlanet
			
			# Gera UVs básicos (para testar texturas depois)
			uv_array[i] = Vector2(percent.x, percent.y)

			# Cria os Triângulos
			if x != resolution-1 and y != resolution-1:
				index_array[tri_index] = i
				index_array[tri_index+1] = i+resolution+1
				index_array[tri_index+2] = i+resolution
				
				index_array[tri_index+3] = i
				index_array[tri_index+4] = i+1
				index_array[tri_index+5] = i+resolution+1
				tri_index += 6
	
	# --- PASSO 2: CÁLCULO REAL DE ILUMINAÇÃO (NORMAIS) ---
	# Isso faz as montanhas terem sombra própria
	
	for a in range(0, index_array.size(), 3):
		var b : int = a + 1
		var c : int = a + 2
		
		var ia : int = index_array[a]
		var ib : int = index_array[b]
		var ic : int = index_array[c]
		
		# Pega os 3 pontos do triângulo
		var va : Vector3 = vertex_array[ia]
		var vb : Vector3 = vertex_array[ib]
		var vc : Vector3 = vertex_array[ic]
		
		# Calcula a direção para onde o triângulo aponta (Cross Product)
		var dir_triangulo : Vector3 = (vb - va).cross(vc - va)
		
		# Adiciona essa direção aos vértices
		normal_array[ia] += dir_triangulo
		normal_array[ib] += dir_triangulo
		normal_array[ic] += dir_triangulo

	# Normaliza o resultado (deixa o vetor com tamanho 1)
	for i in range(normal_array.size()):
		normal_array[i] = normal_array[i].normalized()
	
	# --- FINALIZAÇÃO ---
	arrays[Mesh.ARRAY_VERTEX] = vertex_array
	arrays[Mesh.ARRAY_NORMAL] = normal_array
	arrays[Mesh.ARRAY_TEX_UV] = uv_array
	arrays[Mesh.ARRAY_INDEX] = index_array
	
	call_deferred("_update_mesh", arrays)

func _update_mesh(arrays : Array):
	var _mesh := ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	self.mesh = _mesh
