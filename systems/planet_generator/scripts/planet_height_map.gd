@tool
extends Resource
class_name PlanetHeightMap

@export var min_height : float = 0.0
@export var max_height : float = 10.0

# --- IMAGEM 1: ALTURA (PANORAMA) ---
@export var panorama : Texture2D : set = set_panorama
var _image : Image

# --- IMAGEM 2: BIOMA ---
@export var biome_map : Texture2D : set = set_biome_map # ARRASTE SUA IMAGEM DE BIOMAS AQUI
var _biome_img_cache : Image

# Setters para garantir atualização no Editor
func set_panorama(val):
	panorama = val
	prepare_data()
	emit_signal("changed")

func set_biome_map(val):
	biome_map = val
	prepare_data()
	emit_signal("changed")

func prepare_data():
	# Carrega a Altura
	if panorama:
		_image = panorama.get_image()
	
	# --- CORREÇÃO AQUI: Carrega o Bioma também! ---
	if biome_map:
		_biome_img_cache = biome_map.get_image()
	# ----------------------------------------------

# 1. FUNÇÃO DE ALTURA (Suave / Bilinear)
func get_height_at_uv(u: float, v: float) -> float:
	if not _image: return 0.0
	
	var w = _image.get_width()
	var h = _image.get_height()
	
	var x_float = u * (w - 1)
	var y_float = v * (h - 1)
	
	x_float = fmod(x_float, float(w - 1))
	if x_float < 0: x_float += (w - 1)
	y_float = clamp(y_float, 0.0, h - 1.0)
	
	# Interpolação Bilinear (Mantive sua lógica correta)
	var x0 = int(floor(x_float))
	var y0 = int(floor(y_float))
	var x1 = (x0 + 1) % w
	var y1 = min(y0 + 1, h - 1)
	
	var fade_x = x_float - x0
	var fade_y = y_float - y0
	
	var h00 = _image.get_pixel(x0, y0).r
	var h10 = _image.get_pixel(x1, y0).r
	var h01 = _image.get_pixel(x0, y1).r
	var h11 = _image.get_pixel(x1, y1).r
	
	var mix_top = lerp(h00, h10, fade_x)
	var mix_bottom = lerp(h01, h11, fade_x)
	
	return lerp(mix_top, mix_bottom, fade_y)

# 2. NOVA FUNÇÃO: LER BIOMA (Dura / Sem Mistura)
func get_biome_at_uv(u: float, v: float) -> float:
	if not _biome_img_cache: return 0.0
	
	var w = _biome_img_cache.get_width()
	var h = _biome_img_cache.get_height()
	
	# Matemática UV padrão
	var x_float = u * (w - 1)
	var y_float = v * (h - 1)
	
	# Wrap Horizontal
	x_float = fmod(x_float, float(w - 1))
	if x_float < 0: x_float += (w - 1)
	
	# Clamp Vertical
	y_float = clamp(y_float, 0.0, h - 1.0)
	
	# IMPORTANTE: Usamos "round" ou "int" direto.
	# Não usamos lerp/mistura. Bioma tem que ser exato.
	var x = int(x_float)
	var y = int(y_float)
	
	return _biome_img_cache.get_pixel(x, y).r
