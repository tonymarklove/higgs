extends MarginContainer

onready var guage = $HBoxContainer/Bars/Bar/Guage
onready var label = $HBoxContainer/Bars/Bar/Count/Background/Number

func _on_Player_jump_charge_changed(value):
	guage.value = value * 100
	label.text = str(int(value * 100))
	