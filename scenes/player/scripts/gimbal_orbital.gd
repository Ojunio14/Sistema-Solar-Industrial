extends Node3D


signal ChangedCamera


# Variáveis (equivalente a [SerializeField])
@export var target: Node3D
@export var sensitivity: float = 5.0
@export var orbit_radius: float = 5.0

@export var minimum_orbit_distance: float = 2.0
@export var maximum_orbit_distance: float = 10.0

# Variáveis privadas
var yaw: float
var pitch: float

# Variável para armazenar o movimento do mouse entre as funções
var _mouse_motion: Vector2 = Vector2.ZERO
@export var my_id : String = "Gimbal_Orbital"

# Unity: void Start()
func _ready() -> void:
	
	CameraManager.register_camera(my_id, $Camera)
	
	# Unity: yaw = transform.eulerAngles.y;
	yaw = self.rotation_degrees.y
	# Unity: pitch = transform.eulerAngles.x;
	pitch = self.rotation_degrees.x


# A função _input captura eventos de entrada como movimento do mouse e scroll.
func _input(event: InputEvent) -> void:
	# Captura o movimento relativo do mouse para ser usado no _process
	if event is InputEventMouseMotion:
		_mouse_motion = event.relative
	
	# Lógica do scroll do mouse
	# Unity: orbitRadius -= Input.mouseScrollDelta.y / sensitivity;
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			orbit_radius -= 5.0 / sensitivity
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			orbit_radius += 5.0 / sensitivity


# Unity: void Update()
func _process(delta: float) -> void:
	# Unity: if (Input.GetMouseButton(0))
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Unity: float mouseX = Input.GetAxis("Mouse X");
		var mouse_x: float 
		mouse_x -= _mouse_motion.x
		# Unity: float mouseY = Input.GetAxis("Mouse Y");
		var mouse_y: float = _mouse_motion.y

		# Unity: pitch -= mouseY * sensitivity;
		pitch -= mouse_y * sensitivity
		#yaw += mouse_x * sensitivity
		#pitch = clamp(pitch, -89.9, 89.9)
		## Unity: bool isUpsideDown = pitch > 90f || pitch < -90f;
		var is_upside_down: bool = pitch > 90.0 or pitch < -90.0
#
		## Unity: if (isUpsideDown) { yaw -= ... } else { yaw += ... }
		if is_upside_down:
			yaw -= mouse_x * sensitivity
		else:
			yaw += mouse_x * sensitivity

		# Unity: transform.rotation = Quaternion.Euler(pitch, yaw, 0);
		self.rotation_degrees = Vector3(pitch, yaw, 0)

	# Unity: orbitRadius = Mathf.Clamp(orbitRadius, minimumOrbitDistance, maximumOrbitDistance);
	orbit_radius = clampf(orbit_radius, minimum_orbit_distance, maximum_orbit_distance)
	
	#print(orbit_radius)
	
	
	if orbit_radius <= 550:
		var cast = RayCast()
		#print(cast["collider"].get_parent())
		if cast.has("collider"):
			print(cast["collider"].get_parent())
			emit_signal("ChangedCamera")
			orbit_radius = 700
		#print(cast)
		print(orbit_radius)
	
	# Unity: transform.position = target.position - transform.forward * orbitRadius;
	# O vetor "para frente" da Unity (-Z) é o oposto do de Godot (+Z).
	# Por isso, o sinal de "-" vira "+".
	self.global_position = target.global_position + self.global_transform.basis.z * orbit_radius

	# Reseta a variável de movimento do mouse para o próximo quadro
	_mouse_motion = Vector2.ZERO



const RAY_LENGTH = 1000

func _physics_process(delta):
	if Input.is_action_just_pressed("G"):
		var meshIns : MeshInstance3D = MeshInstance3D.new()
		var boxMesh : BoxMesh = BoxMesh.new()
		boxMesh.size = Vector3(50,5,50)
		#var capsuleMesh : CapsuleMesh = CapsuleMesh.new()
		#capsuleMesh.radius = 3
		#capsuleMesh.height = 16
		meshIns.mesh = boxMesh#capsuleMesh
		get_tree().get_first_node_in_group("Teste").add_child(meshIns)
		
		var result = RayCast()

		if result.has("position"):
			#print(result)
			
			var PosSphere = result["position"]
			
			var NormalSphere = result["normal"]
			
			
			var rotFinal = Quaternion(Vector3.UP,NormalSphere)
			
			
			meshIns.global_position = PosSphere
			meshIns.quaternion = rotFinal


func RayCast() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var cam = get_viewport().get_camera_3d()
	var mousepos = get_viewport().get_mouse_position()

	var origin = cam.project_ray_origin(mousepos)
	var end = origin + cam.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	#query.collide_with_areas = true

	var result = space_state.intersect_ray(query)
	return result

func _exit_tree():
	# Avisa o gerente que eu fui destruída (mudei de cena)
	CameraManager.unregister_camera(my_id)
