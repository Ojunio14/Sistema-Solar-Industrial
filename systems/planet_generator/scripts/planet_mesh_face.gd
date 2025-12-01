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
	var color_array := PackedColorArray() # <--- NOVO: Array de Cores
	var index_array := PackedInt32Array()
	
	vertex_array.resize(num_vertices)
	uv_array.resize(num_vertices)
	normal_array.resize(num_vertices)
	color_array.resize(num_vertices) # <--- NOVO
	index_array.resize(num_indices)
	
	var tri_index : int = 0
	var axisA := Vector3(normal.y, normal.z, normal.x)
	var axisB : Vector3 = normal.cross(axisA)
	
	for y in range(resolution):
		for x in range(resolution):
			var i : int = x + y * resolution
			var percent := Vector2(x,y) / (resolution-1)
			
			# 1. Posição na Esfera
			var pointOnUnitCube : Vector3 = normal + (percent.x-0.5) * 2.0 * axisA + (percent.y-0.5) * 2.0 * axisB
			var pointOnUnitSphere := pointOnUnitCube.normalized()
			
			# 2. Calcular Altura
			var pointOnPlanet := planet_data.point_on_planet(pointOnUnitSphere)
			vertex_array[i] = pointOnPlanet
			
			# 3. Calcular Normal (Simplificada para Esfera)
			normal_array[i] = pointOnUnitSphere
			
			# --- AQUI ESTÁ A MÁGICA DOS BIOMAS ---
			# Calculamos a altura real subtraindo o raio (para saber se é mar ou montanha)
			var elevation = pointOnPlanet.length() - planet_data.radius
			
			# Pedimos ao PlanetData: "Qual a temperatura e umidade aqui?"
			var biome_info = planet_data.get_biome_data(pointOnUnitSphere, elevation)
			
			# Guardamos os dados na COR do vértice:
			# R (Vermelho) = Temperatura
			# G (Verde) = Umidade
			# B (Azul) = 0 (Reservado para o futuro)
			color_array[i] = Color(biome_info.temperature, biome_info.moisture, 0.0, 1.0)
			# -------------------------------------

			# Triângulos (Indíces)
			if x != resolution-1 and y != resolution-1:
				index_array[tri_index] = i
				index_array[tri_index+1] = i+resolution+1
				index_array[tri_index+2] = i+resolution
				index_array[tri_index+3] = i
				index_array[tri_index+4] = i+1
				index_array[tri_index+5] = i+resolution+1
				tri_index += 6
	
	arrays[Mesh.ARRAY_VERTEX] = vertex_array
	arrays[Mesh.ARRAY_NORMAL] = normal_array
	arrays[Mesh.ARRAY_TEX_UV] = uv_array
	arrays[Mesh.ARRAY_COLOR] = color_array # <--- NOVO: Enviamos para a GPU
	arrays[Mesh.ARRAY_INDEX] = index_array
	
	call_deferred("_update_mesh", arrays)

func _update_mesh(arrays : Array):
	var _mesh := ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	self.mesh = _mesh
