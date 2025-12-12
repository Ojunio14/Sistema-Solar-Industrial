extends MeshInstance3D
class_name PlanetMeshFace

# --- CONFIGURAÇÃO DE VISUALIZAÇÃO ---
enum ViewMode { SOLID, WIREFRAME, HYBRID }

# MUDAR AQUI PARA VER AS LINHAS DO QUADTREE:
# ViewMode.SOLID     = Planeta Sólido
# ViewMode.WIREFRAME = Apenas Linhas (Ótimo para Debug)
# ViewMode.HYBRID    = Sólido + Linhas (Melhor dos dois mundos)
const CURRENT_MODE : ViewMode = ViewMode.HYBRID
# -------------------------------------

var normal : Vector3
var chunk_origin : Vector2
var chunk_size : float
var resolution : int = 20 # Resolução de cada pedaço

func regenerate_mesh(planet_data : PlanetData):
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var num_vertices : int = (resolution + 1) * (resolution + 1)
	var num_indices : int = resolution * resolution * 6
	
	var vertex_array := PackedVector3Array()
	var index_array := PackedInt32Array()
	var uv_array := PackedVector2Array()
	var normal_array := PackedVector3Array()
	var color_array := PackedColorArray()
	
	vertex_array.resize(num_vertices)
	normal_array.resize(num_vertices)
	color_array.resize(num_vertices)
	uv_array.resize(num_vertices)
	
	# Usamos lista dinâmica para índices pois o tamanho exato pode variar
	var temp_indices = PackedInt32Array()

	var axisA := Vector3(normal.y, normal.z, normal.x)
	var axisB : Vector3 = normal.cross(axisA)
	
	# --- GERAÇÃO DOS VÉRTICES ---
	for y in range(resolution + 1):
		for x in range(resolution + 1):
			var i : int = x + y * (resolution + 1)
			
			# Lógica do Quadtree
			var percent = Vector2(x, y) / float(resolution)
			var point_on_face_uv = chunk_origin + (percent * chunk_size)
			
			var pointOnUnitCube : Vector3 = normal + (point_on_face_uv.x - 0.5) * 2.0 * axisA + (point_on_face_uv.y - 0.5) * 2.0 * axisB
			var pointOnUnitSphere : Vector3 = pointOnUnitCube.normalized()
			
			# 1. AQUI CONECTAMOS COM SEU PLANET DATA
			var pointOnPlanet := planet_data.point_on_planet(pointOnUnitSphere)
			
			vertex_array[i] = pointOnPlanet
			
			# 2. SISTEMA DE CORES SIMPLIFICADO (Para Debug)
			# Como ainda não temos biomas complexos no Quadtree, usamos altura
			var altura_atual = pointOnPlanet.length()
			var altura_mar = planet_data.radius + planet_data.min_height + 0.2
			
			if altura_atual <= altura_mar:
				color_array[i] = Color.ROYAL_BLUE # Mar
			else:
				color_array[i] = Color.GRAY # Terra
			
			# Triângulos
			if x < resolution and y < resolution:
				var top_left = i
				var top_right = i + 1
				var bottom_left = i + (resolution + 1)
				var bottom_right = i + (resolution + 1) + 1
				
				# Triângulo 1
				temp_indices.append(top_left)
				temp_indices.append(bottom_left)
				temp_indices.append(top_right)
				
				# Triângulo 2
				temp_indices.append(top_right)
				temp_indices.append(bottom_left)
				temp_indices.append(bottom_right)

	# 3. CÁLCULO AUTOMÁTICO DE NORMAIS
	# (Fazemos depois de preencher os arrays)
	index_array = temp_indices
	
	# Cálculo manual de normais flat (Low Poly style)
	# Se quiser suave, pode usar surface tool depois
	for a in range(0, index_array.size(), 3):
		var i1 = index_array[a]
		var i2 = index_array[a+1]
		var i3 = index_array[a+2]
		
		var v1 = vertex_array[i1]
		var v2 = vertex_array[i2]
		var v3 = vertex_array[i3]
		
		var normal_tri = (v2 - v1).cross(v3 - v1).normalized()
		
		normal_array[i1] += normal_tri
		normal_array[i2] += normal_tri
		normal_array[i3] += normal_tri
	
	for k in range(normal_array.size()):
		normal_array[k] = normal_array[k].normalized()

	arrays[Mesh.ARRAY_VERTEX] = vertex_array
	arrays[Mesh.ARRAY_COLOR] = color_array
	arrays[Mesh.ARRAY_NORMAL] = normal_array
	arrays[Mesh.ARRAY_INDEX] = index_array
	
	call_deferred("_update_mesh", arrays)

func _update_mesh(arrays : Array):
	var _mesh := ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	self.mesh = _mesh
	
	# --- GERENCIAMENTO DE MATERIAIS (Sólido, Wireframe ou Híbrido) ---
	
	# 1. Material Sólido (Base)
	var solid_mat = StandardMaterial3D.new()
	solid_mat.vertex_color_use_as_albedo = true # Usa as cores do bioma
	
	# 2. Material Wireframe (Shader)
	var wire_shader = Shader.new()
	wire_shader.code = """
	shader_type spatial;
	render_mode wireframe, cull_back, unshaded;
	uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Preto por padrão
	
	void fragment() {
		ALBEDO = line_color.rgb;
	}
	"""
	var wire_mat = ShaderMaterial.new()
	wire_mat.shader = wire_shader
	
	# --- APLICAÇÃO BASEADA NA OPÇÃO ESCOLHIDA ---
	match CURRENT_MODE:
		ViewMode.SOLID:
			self.material_override = solid_mat
			
		ViewMode.WIREFRAME:
			# No modo apenas wireframe, usamos as cores do bioma nas linhas para ficar bonito
			wire_shader.code = """
			shader_type spatial;
			render_mode wireframe, cull_back, unshaded;
			void fragment() { ALBEDO = COLOR.rgb; }
			"""
			wire_mat.shader = wire_shader
			self.material_override = wire_mat
			
		ViewMode.HYBRID:
			# No modo híbrido, usamos o sólido e adicionamos o wireframe como "Next Pass"
			# Definimos a linha como BRANCA ou PRETA para contrastar com o terreno
			wire_mat.set_shader_parameter("line_color", Color(1.0, 1.0, 1.0)) # Linhas brancas
			solid_mat.next_pass = wire_mat
			self.material_override = solid_mat
	# Colisão (Opcional - Ative só quando o jogador for andar)
	# --- LÓGICA DE COLISÃO ---
	# Só gera colisão se o pedaço for pequeno (chunk_size < 0.1 ou algo assim)
	# ou se o depth (profundidade) for alta.
	
	# DICA PARA SEU TESTE:
	# Como você quer testar andar, ative a colisão sempre por enquanto, 
	# mas saiba que vai pesar no FPS.
	
	if get_parent().depth > 4: # Exemplo: Só gera física nos níveis detalhados
		create_trimesh_collision()
	
	# Limpeza de colisão antiga
	else:
		for child in get_children():
			if child is StaticBody3D:
				child.queue_free()
