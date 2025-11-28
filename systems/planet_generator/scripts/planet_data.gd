#@tool
extends Resource
class_name  PlanetData
#signal changed

#=======================================
var _radius : float
@export var radius : float = 1 :
	set(value):
		set_radius(value)
	get:
		return _radius

func set_radius(value):
	_radius = value
	emit_signal("changed")

#=======================================

var _resolution : int
@export var resolution : int = 1 :
	set(value):
		set_resolution(value)
	get:
		return _resolution

func set_resolution(value):
	_resolution = value
	emit_signal("changed")

#=======================================
var _planet_noise : Array[Resource]
@export var planet_noise : Array[Resource] = [] : 
	set(value):
		set_planet_noise(value)
	get:
		return _planet_noise
		

func set_planet_noise(value):
	
	_planet_noise = value
	emit_signal("changed")
	for n in planet_noise:
		if n != null and not n.is_connected("changed", Callable(self,"on_data_changed")):
				n.connect("changed", Callable(self,"on_data_changed"))
	




func on_data_changed():
	emit_signal("changed")

#func point_on_planet(point_on_sphere : Vector3) -> Vector3:
	#var elevation : float = 0
	#for n in planet_noise:
			#
		#var level_elevation = n.noise_map.get_noise_3dv(point_on_sphere)
		#level_elevation = (level_elevation + 1) / 2.0 * n.amplitude
		#level_elevation = max(0.0, level_elevation - n.min_height)
		#elevation += level_elevation 
	#return point_on_sphere * radius * (elevation + 1.0)


#
func point_on_planet(point_on_sphere : Vector3) -> Vector3:
	var elevation : float = 0.0
	var base_elevation := 0.0
	if planet_noise.size() > 0:
		base_elevation = (planet_noise[0].noise_map.get_noise_3dv(point_on_sphere))
		base_elevation = (base_elevation + 1.0) / 2.0 * planet_noise[0].amplitude
		base_elevation = max(0.0, base_elevation - planet_noise[0].min_height)
	for n in planet_noise:
		var mask := 1.0
		if n.use_first_layer_as_mask:
			mask = base_elevation
		var level_elevation = n.noise_map.get_noise_3dv(point_on_sphere)
		level_elevation = (level_elevation + 1.0) / 2.0 * n.amplitude
		level_elevation = max(0.0, level_elevation - n.min_height) * mask
		elevation += level_elevation
	return point_on_sphere * radius * (elevation+1.0)
