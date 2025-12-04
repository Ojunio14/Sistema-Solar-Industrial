@tool
extends Resource
class_name PlanetData



@export var radius : float = 100.0 : set = set_radius
@export var resolution : int = 50 : set = set_resolution # Resolução da Malha
@export var height_map : PlanetHeightMap : set = set_height_map

# Quanto o terreno sobe (Ex: 20 metros)
@export var amplitude : float = 20.0 : set = set_amplitude 

# Nível mínimo (Oceano). Se a imagem for preta, afunda X metros.
@export var min_height : float = 0.0 : set = set_min_height

func set_radius(val): radius = val; emit_signal("changed")
func set_resolution(val): resolution = val; emit_signal("changed")
func set_amplitude(val): amplitude = val; emit_signal("changed")
func set_min_height(val): min_height = val; emit_signal("changed")

func set_height_map(val):
	height_map = val
	if height_map and not height_map.is_connected("changed", Callable(self, "on_data_changed")):
		height_map.changed.connect(Callable(self, "on_data_changed"))
	emit_signal("changed")

func on_data_changed():
	emit_signal("changed")

# ==========================================================
# AQUI ACONTECE A MÁGICA
# ==========================================================
func point_on_planet(point_on_sphere : Vector3) -> Vector3:
	var elevation : float = 0.0
	
	if height_map:
		# 1. Matemática de Esfera para Retângulo (UV)
		var longitude = atan2(point_on_sphere.x, point_on_sphere.z)
		var u = (longitude / (2.0 * PI)) + 0.5
		
		var latitude = asin(point_on_sphere.y)
		var v = (latitude / PI) + 0.5
		v = 1.0 - v # Inverte para não ficar de cabeça para baixo
		
		# 2. Lê a altura da imagem (0.0 a 1.0)
		var valor_da_imagem = height_map.get_height_at_uv(u, v)
		
		# 3. Calcula altura final em metros
		# Fórmula: Nível Mínimo + (Valor * Força)
		elevation = min_height + (valor_da_imagem * amplitude)

	# Aplica ao raio original
	return point_on_sphere * (radius + elevation)
