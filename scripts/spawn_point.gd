extends Node3D

@onready var world: Node3D = $"../.."
@onready var point: Marker3D = $point
const ZOMBIE = preload("res://scenes/zombie.tscn")
@onready var zombies: Node3D = $"../../Zombies"
@onready var player: Player = %Player
const P_90 = preload("res://weapon_resource/p90.tres")

func spawn_zombie():
	var pos = point.global_position
	var instance = ZOMBIE.instantiate()
	pos.y += 2
	world.add_child(instance)
	instance.global_position = pos
	if instance.is_alive:
		await get_tree().process_frame
