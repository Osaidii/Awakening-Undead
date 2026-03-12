extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var black: ColorRect = $Black

var is_paused := false

func _ready() -> void:
	visible = false
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and is_paused:
		is_paused = false
		resume()
	elif event.is_action_pressed("pause") and !is_paused and Variables.is_pauseable:
		is_paused = true
		pause()

func pause() -> void:
	visible = true
	get_tree().paused = true
	animation_player.play("blur")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animation_player.play_backwards("blur")
	await get_tree().create_timer(0.5).timeout
	get_tree().paused = false
	visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_main_menu_pressed() -> void:
	black.visible = true
	animation_player.play("black")
	await get_tree().create_timer(1).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main menu.tscn")
	animation_player.play_backwards("black")

func _on_resume_pressed() -> void:
	resume()
