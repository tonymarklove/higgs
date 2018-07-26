extends Node

onready var bounds = $Bounds

func _ready():
	Global.notify_camera_of_level_change(self)

func bounds_left():
	return bounds.position.x - bounds.scale.x * 32

func bounds_right():
	return bounds.position.x + bounds.scale.x * 32

func bounds_top():
	return bounds.position.y - bounds.scale.y * 32

func bounds_bottom():
	return bounds.position.y + bounds.scale.y * 32
