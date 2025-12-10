@tool
extends Resource
class_name PlanetHeightMap

# Configurações de limite (para o script principal ler)
@export var min_height : float = 0.0
@export var max_height : float = 10.0

# A Imagem dos Continentes (Preto e Branco)
@export var panorama : Texture2D : set = set_panorama
var _image : Image

func set_panorama(val):
	panorama = val
	if panorama:
		_image = panorama.get_image()
	emit_signal("changed")

func prepare_data():
	if panorama: _image = panorama.get_image()

# Função que lê o pixel (0.0 a 1.0) na coordenada UV
func get_height_at_uv(u: float, v: float) -> float:
	if not _image: return 0.0
	
	var w = _image.get_width()
	var h = _image.get_height()
	
	# Mapeia 0..1 para pixels reais
	var x = int(u * (w - 1))
	var y = int(v * (h - 1))
	
	# Garante que não sai da imagem
	x = x % w
	y = clamp(y, 0, h - 1)
	
	# Retorna o brilho (Red channel)
	return _image.get_pixel(x, y).r
