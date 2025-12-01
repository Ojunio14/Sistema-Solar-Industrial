#@tool
extends Resource
class_name PlanetData


@export var radius : float = 50.0 :
	set(value):
		radius = value
		emit_signal("changed")

@export var resolution : int = 100 :
	set(value):
		resolution = value
		emit_signal("changed")

@export var height_map : PlanetHeightMap :
	set(value):
		height_map = value
		if height_map:
			height_map.prepare_data()
			if not height_map.is_connected("changed", Callable(self, "on_data_changed")):
				height_map.changed.connect(Callable(self, "on_data_changed"))
		emit_signal("changed")

func on_data_changed():
	if height_map: height_map.prepare_data()
	emit_signal("changed")


# ... (suas variáveis de height_map, radius, etc) ...

@export_group("Biome Settings")
@export var moisture_noise : FastNoiseLite # Arraste um Noise aqui no Inspector!
@export var temperature_noise : FastNoiseLite # Opcional: Para variar um pouco o calor
@export var biome_frequency : float = 1.0 # Frequência dos biomas


func point_on_planet(point_on_sphere : Vector3) -> Vector3:
	var elevation : float = 0.0
	
	if height_map:
		# LÓGICA EQUIRETANGULAR
		# O vetor point_on_sphere já é normalizado (-1 a 1)
		
		# 1. Calcular Longitude (U) - Eixo X/Z
		# atan2 retorna entre -PI e PI.
		var longitude = atan2(point_on_sphere.x, point_on_sphere.z)
		# Converter para 0 a 1
		var u = (longitude / (2.0 * PI)) + 0.5
		
		# 2. Calcular Latitude (V) - Eixo Y
		# asin retorna entre -PI/2 e PI/2
		var latitude = asin(point_on_sphere.y)
		# Converter para 0 a 1
		var v = (latitude / PI) + 0.5
		
		# Correção: Texturas geralmente leem de cima para baixo (0 no topo, 1 em baixo)
		# Então talvez precise inverter o V:
		v = 1.0 - v 
		
		# Ler altura
		var height_percent = height_map.get_height_at_uv(u, v)
		
		# Aplicar escala
		var min_h = height_map.min_height
		var max_h = height_map.max_height
		elevation = min_h + (height_percent * (max_h - min_h))

	return point_on_sphere * (radius + elevation)


# Retorna um Dicionário com { "temp": 0.0 a 1.0, "moist": -1.0 a 1.0 }
#func get_biome_data(point_on_sphere: Vector3, elevation_above_sea: float) -> Dictionary:
	#var latitude = abs(point_on_sphere.y)
	#
	## --- AJUSTE AUTOMÁTICO DE ESCALA ---
	## Independentemente do tamanho do planeta, queremos que as manchas de bioma
	## tenham um tamanho fixo (ex: manchas de 200 metros).
	## Se não fizermos isso, planetas grandes terão manchas gigantescas.
	#
	## Fator de correção: Quanto maior o raio, maior a frequência necessária.
	## O valor '0.05' aqui é um "número mágico" que define o tamanho base das manchas.
	## Aumente para 0.1 se quiser manchas menores (mais variedade).
	## Diminua para 0.01 se quiser biomas continentais enormes.
	#var escala_final = radius * biome_frequency * 0.05
	#
	## -----------------------------------
	#
	#var base_temp = 1.0 - latitude
	#
	#if temperature_noise:
		## Usamos a escala_final aqui
		#var noise_val = temperature_noise.get_noise_3dv(point_on_sphere * escala_final)
		#base_temp += noise_val * 0.6 
		#
	#if height_map:
		#var height_factor = elevation_above_sea / height_map.max_height
		#base_temp -= height_factor * 0.7 
		#
	#base_temp = clamp(base_temp, 0.0, 1.0)
	#
	#var moisture = 0.0
	#if moisture_noise:
		## Usamos a mesma escala aqui (ou varie um pouco se quiser)
		#moisture = moisture_noise.get_noise_3dv(point_on_sphere * escala_final)
		#moisture = (moisture + 1.0) / 2.0
		#
	#return { "temperature": base_temp, "moisture": moisture }

func get_biome_data(point_on_sphere: Vector3, elevation_above_sea: float) -> Dictionary:
	var biome_id = 0.0
	
	# Agora perguntamos para o height_map, que é quem segura a imagem
	if height_map:
		# 1. Recalcula UV (Matemática repetida, mas necessária aqui)
		var longitude = atan2(point_on_sphere.x, point_on_sphere.z)
		var u = (longitude / (2.0 * PI)) + 0.5
		var latitude = asin(point_on_sphere.y)
		var v = (latitude / PI) + 0.5
		v = 1.0 - v
		
		# 2. Chama a função nova que criamos acima
		biome_id = height_map.get_biome_at_uv(u, v)

	return { "temperature": biome_id, "moisture": 0.0 }

#func get_biome_data(point_on_sphere: Vector3, elevation_above_sea: float) -> Dictionary:
	#var biome_id = 0.0 # Padrão (Água)
	#
	#if height_map._biome_img_cache:
		## 1. Converte Esfera para UV (Mesma matemática do HeightMap)
		#var longitude = atan2(point_on_sphere.x, point_on_sphere.z)
		#var u = (longitude / (2.0 * PI)) + 0.5
		#var latitude = asin(point_on_sphere.y)
		#var v = (latitude / PI) + 0.5
		#v = 1.0 - v 
		#
		## 2. Lê o pixel da imagem de BIOMA
		#var w = height_map._biome_img_cache.get_width()
		#var h = height_map._biome_img_cache.get_height()
		#
		#var x = int(u * (w - 1))
		#var y = int(v * (h - 1))
		#
		## Pega o valor VERMELHO (R) como ID (0.0 a 1.0)
		#biome_id = height_map._biome_img_cache.get_pixel(x, y).r
		## Vamos imprimir o valor do pixel central para ver o que está acontecendo
		#if x == int(w / 2) and y == int(h / 2):
			#print("Valor lido da Imagem de Bioma: ", biome_id)
	#else:
		## --- ADICIONE ISSO AQUI ---
		## Se cair aqui, a variável da imagem está VAZIA (null)
		#print("ERRO CRÍTICO: Nenhuma imagem de bioma carregada na memória!")
	## Retornamos o ID dentro da variável "temperature" para enganar o shader antigo
	## Mas agora "temperature" significa "TIPO DE BIOMA"
	#return { "temperature": biome_id, "moisture": 0.0 }
