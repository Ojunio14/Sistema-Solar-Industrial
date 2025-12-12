extends Camera3D

# --- ADICIONADO: Posição do Planeta ---
@export var planet_center : Vector3 = Vector3.ZERO

# Configurações de Sensibilidade e Velocidade
@export_group("Controles da Câmera")
@export var mouse_sensitivity : float = 0.002
@export var base_speed : float = 10.0
@export var boost_multiplier : float = 5.0  # Multiplicador ao segurar Shift
@export var max_speed_scale : float = 100.0 # Para viajar rápido pelo planeta

@export var my_id : CameraManager.Cam_Id



# Variáveis internas
var current_speed_scale : float = 1.0

func _ready():
	CameraManager.register_camera(my_id, self)
	# Captura o mouse para ele não sair da tela
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# 1. Rotação da Câmera (Mouse)
	if event is InputEventMouseMotion:
		# --- MUDANÇA AQUI ---
		# Em vez de rotate_y (global), giramos em torno do eixo "Cima" local da câmera
		# Isso permite virar a cabeça esquerda/direita independente da gravidade
		rotate_object_local(Vector3.UP, -event.relative.x * mouse_sensitivity)
		
		# Rotação vertical (X) - Gira a câmera localmente (Olhar pra cima/baixo)
		rotate_object_local(Vector3.RIGHT, -event.relative.y * mouse_sensitivity)
		
		# Removemos o "rotation.z = 0" daqui porque ele quebra a rotação esférica.
		# A correção do horizonte será feita no _process.

	# 2. Controle de Velocidade (Scroll do Mouse)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_speed_scale = min(current_speed_scale * 1.1, max_speed_scale)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_speed_scale = max(current_speed_scale * 0.9, 0.1)
	
	# 3. Sair do modo captura (Tecla ESC)
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	# Se o mouse não estiver capturado, não move
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	# --- 1. MOVIMENTAÇÃO ---
	var speed = base_speed * current_speed_scale
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= boost_multiplier

	var velocity = Vector3.ZERO

	# Movimentação WASD (Local)
	if Input.is_key_pressed(KEY_W): velocity += Vector3.FORWARD
	if Input.is_key_pressed(KEY_S): velocity += Vector3.BACK
	if Input.is_key_pressed(KEY_A): velocity += Vector3.LEFT
	if Input.is_key_pressed(KEY_D): velocity += Vector3.RIGHT
	
	# Movimentação Vertical (Q/E)
	if Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE): 
		velocity += Vector3.UP
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_CTRL): 
		velocity += Vector3.DOWN

	velocity = velocity.normalized()

	# Aplica o movimento na direção que a câmera está olhando
	# Usamos Basis local para garantir que W vá para frente da lente
	var global_velocity = transform.basis * (velocity * speed * delta)
	global_position += global_velocity

	# --- 2. CORREÇÃO DE HORIZONTE (A Mágica do Planeta) ---
	# Chamamos a função que recalcula a rotação para alinhar com o planeta
	align_horizon_to_planet()

func align_horizon_to_planet():
	# 1. Descobrir onde é "Cima" no planeta (Vetor da gravidade invertido)
	var planet_up = (global_position - planet_center).normalized()
	
	# 2. Descobrir para onde a câmera está olhando agora (Frente)
	var camera_forward = -transform.basis.z
	
	# PREVENÇÃO DE BUG: Se olhar exatamente para cima ou para baixo (90 graus),
	# o cálculo matemático falha. Se estiver muito alinhado, não ajustamos o horizonte.
	if abs(camera_forward.dot(planet_up)) > 0.99:
		return

	# 3. Recalcular o vetor "Direita" da câmera
	# O vetor Direita deve ser perpendicular à Gravidade e à Frente da câmera.
	var new_right = camera_forward.cross(planet_up).normalized()
	
	# 4. Recalcular o vetor "Cima" da câmera (Local)
	# O Cima da câmera deve ser perpendicular à Frente e à Direita
	var new_camera_up = new_right.cross(camera_forward).normalized()
	
	# 5. Aplicar a nova base (Mantém o olhar, mas ajusta a inclinação da cabeça)
	transform.basis = Basis(new_right, new_camera_up, -camera_forward)


#func _exit_tree():
	## Avisa o gerente que eu fui destruída (mudei de cena)
	#CameraManager.unregister_camera(my_id)
