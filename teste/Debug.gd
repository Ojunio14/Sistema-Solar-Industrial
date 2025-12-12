#Debug
extends Control

# Arraste seu PlanetData e o Node do Planeta (para pegar a posição 0,0,0)
@export var planet_data : PlanetData
@export var planet_node : Node3D 
@export var player : Camera3D

var Fps : String 
var alt : int = 0
# Configuração igual ao KSP: Quando mudar para modo Radar?
const RADAR_THRESHOLD = 3000.0 # Metros



func _process(delta):
	Fps = str(Engine.get_frames_per_second())
	$VBoxContainer/Fps2/Fps.text = Fps
	#if not player or not planet_data: return
	
	# 1. Cálculos Básicos
	# Vetor do centro do planeta até o jogador
	var vector_to_player = player.global_position - planet_node.global_position
	
	# Distância total do centro (Raio + Altura)
	var distance_from_center = vector_to_player.length()
	
	# --- MODO 1: ALTITUDE NÍVEL DO MAR (ASL) ---
	# Simplesmente a distância total menos o raio "oficial" do planeta
	var altitude_asl = distance_from_center - planet_data.radius
	
	# --- MODO 2: ALTITUDE DE RADAR (AGL/TERRENO) ---
	# Aqui está o segredo: Usamos seu script para descobrir onde o chão está matematicamente
	
	# Pegamos a direção normalizada (Esfera Unitária)
	var direction_unit = vector_to_player.normalized()
	
	# Perguntamos ao PlanetData: "Qual a altura do terreno nesta direção?"
	var ground_position_3d = planet_data.point_on_planet(direction_unit)
	
	# A distância do centro até o chão naquele ponto
	var ground_radius = ground_position_3d.length()
	
	# AGL é a diferença entre onde você está e onde o chão está
	var altitude_agl = distance_from_center - ground_radius
	
	# --- LÓGICA DE EXIBIÇÃO TIPO KSP ---
	update_ui(altitude_asl, altitude_agl)

func update_ui(asl, agl):
	# No KSP, o altímetro mostra ASL quando alto, e AGL quando baixo.
	
	var valor_mostrado = 0.0
	var is_radar = false
	
	# Se a altura real do chão for menor que 3000m (exemplo), ativa radar
	# E também garantimos que não estamos sobre o mar (agl > 0)
	if agl < RADAR_THRESHOLD and agl > 0:
		valor_mostrado = agl
		is_radar = true
	else:
		valor_mostrado = asl
		is_radar = false
		
	# Exemplo de print (conecte isso num Label depois)
	alt = int(valor_mostrado)
	$VBoxContainer/Altura/Teste_Alti/Alti.text = str(alt)
	#if is_radar:
		##$Alti.text = str(valor_mostrado)
		#print("RADAR: %.1f m" % valor_mostrado)
	#else:
		#print("ALTITUDE: %.1f m" % valor_mostrado)


func _on_option_button_item_selected(index: int) -> void:

	CameraManager.switch_camera(index)
