extends Node

func _ready():
	OS.center_window()

func goto_scene(path, teleport_to_location):
	call_deferred("_deferred_goto_scene", path, teleport_to_location)

func _deferred_goto_scene(path, teleport_to_location):
	# Load new scene.
	var s = ResourceLoader.load(path)
	var new_scene = s.instance()

	# Add it to the active scene, as child of root.
	var level_node = get_node("/root/Node/Level")
	var parent = level_node.get_parent()

	level_node.free()

	parent.add_child(new_scene)

	if teleport_to_location != null:
		var player_node = get_node("/root/Node/Player")
		player_node.set_position(teleport_to_location)
