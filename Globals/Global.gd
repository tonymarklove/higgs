extends Node

func _ready():
	OS.center_window()

func goto_scene(path, teleport_to_location=null):
	call_deferred("_deferred_goto_scene", path, teleport_to_location)

func _deferred_goto_scene(path, teleport_to_location):
	# Load new scene.
	var s = ResourceLoader.load(path)
	var new_level = s.instance()

	# Add it to the active scene, as child of root.
	var level_node = get_node("/root/GameWorld/Level")
	var parent = level_node.get_parent()

	level_node.free()

	parent.add_child(new_level)

	if teleport_to_location != null:
		var player_node = get_node("/root/GameWorld/Player")
		player_node.set_position(teleport_to_location)

func notify_camera_of_level_change(level):
	get_node("/root/GameWorld/Player/Camera").calculate_bounds(level)
