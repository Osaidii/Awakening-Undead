extends Skeleton3D

@onready var weapons: MeshInstance3D = %Weapons
@onready var hip_bone: PhysicalBone3D = $"Physical Bone Hips"
@onready var player: Player = $Player

func _ready() -> void:
	await get_tree().create_timer(0.01).timeout
	physical_bones_start_simulation()
	await get_tree().create_timer(2.25).timeout
	physical_bones_stop_simulation()

func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	visible = true

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	visible = false
