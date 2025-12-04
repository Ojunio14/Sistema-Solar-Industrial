@tool
extends Resource
class_name PlanetHeightMap

# Arraste sua imagem Preto e Branco aqui
@export var panorama : Texture2D : set = set_panorama
var _image : Image

func set_panorama(val):
	panorama = val
	if panorama:
		# IMPORTANTE: A imagem precisa estar importada como "Lossless"
		_image = panorama.get_image()
	emit_signal("changed")

# Função que converte UV (0 a 1) para Altura (0 a 1)
func get_height_at_uv(u: float, v: float) -> float:
	if not _image: return 0.0
	
	var w = _image.get_width()
	var h = _image.get_height()
	
	# Transforma UV em coordenadas de Pixel
	var x_float = u * (w - 1)
	var y_float = v * (h - 1)
	
	# Wrap Horizontal (Para não ter costura na emenda do planeta)
	x_float = fmod(x_float, float(w - 1))
	if x_float < 0: x_float += (w - 1)
	
	# Clamp Vertical (Trava nos polos)
	y_float = clamp(y_float, 0.0, h - 1.0)
	
	# --- INTERPOLAÇÃO BILINEAR (Suavização) ---
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
