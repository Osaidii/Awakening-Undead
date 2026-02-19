class_name damageable
extends CharacterBody3D

var old_health := 15
var current_health := 15

func take_damage(damage: float) -> void:
	old_health = current_health
	current_health -= damage
