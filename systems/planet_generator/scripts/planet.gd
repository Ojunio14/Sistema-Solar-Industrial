#@tool
extends Node3D

signal changed

var _planeta_data : Resource
@export var planeta_data : Resource :
	set(value):
		_planeta_data = value
		set_planet_noise(value)
		on_data_changed()
	get:
		return _planeta_data

func set_planet_noise(value):
	_planeta_data = value
	emit_signal("changed")
	#for n in _planeta_data:
	
	if _planeta_data != null and not _planeta_data.is_connected("changed", Callable(self,"on_data_changed")):
		#_planeta_data.connect("changed", self, "on_data_changed")
		_planeta_data.connect("changed", Callable(self,"on_data_changed"))


func _ready() -> void:
	on_data_changed()
	pass
	


func on_data_changed():
	for child in get_children():
		var face := child as PlanetMeshFace
		face.regenerate_mesh(planeta_data)
