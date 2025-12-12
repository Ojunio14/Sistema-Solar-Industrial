extends Node


signal PosCameraOrbital(pos)

# Dicionário para guardar as câmeras registradas: {"FreeFly": CameraNode, "Orbital": CameraNode}
var cameras : Dictionary = {}
var current_camera : Camera3D = null
var current_camera_id : int
enum Cam_Id {LivreQuadTree,Orbital,WireFrame,Null}
#var current_cam : int = Cam_Id.LivreQuadTree
var Cam_quidtree_pos

func switch_camera(camera_name : int):
	if not cameras.has(camera_name):
		push_error("Camera Manager: Câmera '" , camera_name , "' não encontrada!")
		return

	match camera_name:
		Cam_Id.LivreQuadTree:
			cam_livre_quadtree(camera_name)
			#switch_to(camera_name)
			pass
		Cam_Id.Orbital:
			#switch_to(camera_name)
			pass
		Cam_Id.WireFrame:
			cam_wireframe(camera_name)
			#switch_to(camera_name)
			pass
		Cam_Id.Null:
			pass




func cam_livre_quadtree(camera_name):
	cameras[2].process_mode = Node.PROCESS_MODE_DISABLED
	var camera_wire_frame = cameras[0]
	#print(cameras)
	camera_wire_frame.make_current()
	camera_wire_frame.process_mode = Node.PROCESS_MODE_INHERIT
	
	
func cam_wireframe(camera_name):
	#var camera_wire_frame = cameras[2]
	#print(cameras)
	cameras[0].process_mode = Node.PROCESS_MODE_DISABLED
	var camera_wire_frame = cameras[2]
	#print(cameras)
	camera_wire_frame.make_current()
	camera_wire_frame.process_mode = Node.PROCESS_MODE_INHERIT
	
# Registra uma câmera nova (A câmera chama isso quando nasce)
func register_camera(camera_name: int, camera_node: Camera3D):
	
	
	cameras[camera_name] = camera_node
	print("Camera Manager: Câmera '" , camera_name , "' registrada.")

# Remove (A câmera chama isso quando morre/é destruída)
func unregister_camera(camera_name: int):
	if cameras.has(camera_name):
		cameras.erase(camera_name)

# A função mágica que troca a visão
func switch_to(camera_name: int):
	if not cameras.has(camera_name):
		push_error("Camera Manager: Câmera '" , camera_name , "' não encontrada!")
		return
	
		
	print(cameras)
	var next_cam = cameras[camera_name]
	if camera_name == 0:
		pass
		#current_cam.process_mode = Node.PROCESS_MODE_DISABLED
	# Desativa a anterior (opcional, dependendo da sua lógica)
	# if current_camera: current_camera.current = false
	# Ativa a nova
	next_cam.make_current() # Função nativa da Godot que assume o controle
	#print(current_cam,"-----------")
	current_camera = next_cam
	
	#print("Camera Manager: Trocado para " + camera_name)




## Exemplo: Alternar entre câmeras com uma tecla
#func _unhandled_input(event):
	#if event.is_action_pressed("change_cam_view"): # Crie esse input map
		## Exemplo simples de toggle
		#if current_camera == cameras.get("FreeFly"):
			#switch_to("Orbital")
		#elif current_camera == cameras.get("FreeFlyFrame"):
			#switch_to("FreeFlyFrame")
		#else:
			#switch_to("FreeFly")
