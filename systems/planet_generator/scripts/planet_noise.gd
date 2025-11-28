#@tool
extends Resource

class_name PlanetNoise


var _noise_map : FastNoiseLite
@export var noise_map : FastNoiseLite :
	set(value):
		set_noise_map(value)
	get:
		return _noise_map

func set_noise_map(value):
	_noise_map = value
	emit_signal("changed")
	if _noise_map != null and not _noise_map.is_connected("changed", Callable(self,"on_data_changed")):
			_noise_map.connect("changed", Callable(self,"on_data_changed"))
	


var _amplitude : float
@export var amplitude : float = 1 :
	set(value):
		set_amplitude(value)
	get:
		return _amplitude

func set_amplitude(value):
	_amplitude = value
	emit_signal("changed")


var _min_height : float
@export var min_height : float = 0 :
	set(value):
		set_min_height(value)
	get:
		return _min_height
		
func set_min_height(value):
	_min_height = value
	emit_signal("changed")


var _use_first_layer_as_mask : bool
@export var use_first_layer_as_mask : bool = false :
	set(value):
		set_first_layer_as_mask(value)
	get:
		return _use_first_layer_as_mask

func set_first_layer_as_mask(value):
	_use_first_layer_as_mask = value
	emit_signal("changed")

func on_data_changed():
	emit_signal("changed")
#var _noise_map : FastNoiseLite
#
#@export var noise_map : FastNoiseLite : 
	#set(value):
		#_noise_map = value
#
		##noise_map = val
		#emit_signal("changed")
		##if _noise_map != null and not _noise_map.is_connected("changed", self, "on_data_changed"):
			##_noise_map.connect("changed", self, "on_data_changed")
		#
	#get:
		#return _noise_map


#@export var amplitude : float = 1.0 #setget set_amplitude
#@export var min_height : float = 0.0 setget set_min_height
#@export var use_first_layer_as_mask : bool = false setget set_first_layer_as_mask

#func set_first_layer_as_mask(val):
	#use_first_layer_as_mask = val
	#emit_signal("changed")
	
#func set_min_height(val):
	#min_height = val
	#emit_signal("changed")
	
#func set_amplitude(val):
	#amplitude = val
	#emit_signal("changed")

#func set_noise_map(val):
	#noise_map = val
	#emit_signal("changed")
	#if noise_map != null and not noise_map.is_connected("changed", self, "on_data_changed"):
		#noise_map.connect("changed", self, "on_data_changed")
		
#func on_data_changed():
	#emit_signal("changed")
