extends GPUParticles3D

@onready var wound_sound: AudioStreamPlayer3D = $"Wound Sound"

func _ready() -> void:
	emitting = true
	wound_sound.play()
	await get_tree().create_timer(0.5, false).timeout
	queue_free()

func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	visible = true

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	visible = false
