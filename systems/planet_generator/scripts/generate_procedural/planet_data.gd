#@tool
extends Resource
class_name PlanetData



# Geometria Básica
@export var radius : float = 50.0 : set = set_radius
@export var resolution : int = 10
@export var amplitude : float = 20.0 # Altura máxima dos continentes
@export var min_height : float = 0.0 # Nível base

# Conexão com a imagem
@export var height_map : PlanetHeightMap : set = set_height_map 

func set_radius(val): radius = val; emit_signal("changed")
func set_height_map(val):
	height_map = val
	if height_map and not height_map.is_connected("changed", Callable(self, "on_data_changed")):
		height_map.changed.connect(Callable(self, "on_data_changed"))
	emit_signal("changed")

func on_data_changed():
	if height_map: height_map.prepare_data()
	emit_signal("changed")

# --- A FUNÇÃO DE FORMA ---
func point_on_planet(point_on_sphere : Vector3) -> Vector3:
	# 1. Normaliza para garantir que estamos na superficie da esfera unitária
	var p = point_on_sphere.normalized()
	
	# 2. Calcula UV (Latitude/Longitude)
	var u = (atan2(p.x, p.z) / (2.0 * PI)) + 0.5
	var v = (asin(p.y) / PI) + 0.5
	v = 1.0 - v # Inverte V se a imagem estiver de cabeça para baixo
	
	# 3. Lê a altura da imagem
	var h_percent = 0.0
	if height_map:
		h_percent = height_map.get_height_at_uv(u, v)
	
	# 4. Calcula elevação final
	var elevation = min_height + (h_percent * amplitude)
	
	# 5. Aplica ao raio
	return p * (radius + elevation)
