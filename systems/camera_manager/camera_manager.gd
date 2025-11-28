extends Node

# Dicionário para guardar as câmeras registradas: {"FreeFly": CameraNode, "Orbital": CameraNode}
var cameras : Dictionary = {}
var current_camera : Camera3D = null

# Registra uma câmera nova (A câmera chama isso quando nasce)
func register_camera(camera_name: String, camera_node: Camera3D):
	cameras[camera_name] = camera_node
	print("Camera Manager: Câmera '" + camera_name + "' registrada.")

# Remove (A câmera chama isso quando morre/é destruída)
func unregister_camera(camera_name: String):
	if cameras.has(camera_name):
		cameras.erase(camera_name)

# A função mágica que troca a visão
func switch_to(camera_name: String):
	if not cameras.has(camera_name):
		push_error("Camera Manager: Câmera '" + camera_name + "' não encontrada!")
		return
	
	var next_cam = cameras[camera_name]
	
	# Desativa a anterior (opcional, dependendo da sua lógica)
	# if current_camera: current_camera.current = false
	
	# Ativa a nova
	next_cam.make_current() # Função nativa da Godot que assume o controle
	current_camera = next_cam
	
	print("Camera Manager: Trocado para " + camera_name)

# Exemplo: Alternar entre câmeras com uma tecla
func _unhandled_input(event):
	if event.is_action_pressed("change_cam_view"): # Crie esse input map
		# Exemplo simples de toggle
		if current_camera == cameras.get("FreeFly"):
			switch_to("Orbital")
		else:
			switch_to("FreeFly")
