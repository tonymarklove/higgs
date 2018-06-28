extends MarginContainer

onready var guage = $HBoxContainer/Bars/Bar/Guage

func _on_Player_jump_charge_changed(value):
	guage.value = value
	