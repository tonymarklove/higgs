extends Area2D

export var scene_to_load = "res://Levels/Level_1_2.tscn"
export(Vector2) var teleport_to_location

func use_door():
	get_node("/root/Global").goto_scene(scene_to_load, teleport_to_location)
