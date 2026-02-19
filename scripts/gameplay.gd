extends Node

var wave_num := 1

func _input(_event: InputEvent) -> void:
	if Input.is_action_pressed("1"):
		wave_num += 1
