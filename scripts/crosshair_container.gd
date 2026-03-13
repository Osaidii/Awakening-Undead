extends CenterContainer

@export var PLAYER: CharacterBody3D
@export var LINES: Array[Line2D]
@export var SPEED := 0.25
@export var DISTANCE := 2.0
@export var RADIUS := 1.0
@export var COLOR := Color.WHITE
@onready var timer: Timer = $Player/UI/CrosshairContainer/Timer

func _ready() -> void:
	queue_redraw()

func _process(_delta: float) -> void:
	adjust_lines()

func _draw() -> void:
	draw_circle(Vector2(0, 0), RADIUS, COLOR)

func adjust_lines() -> void:
	var vel = PLAYER.get_real_velocity()
	var origin = Vector3(0, 0, 0)
	var pos = Vector2(0, 0)
	var speed = origin.distance_to(vel)
	
	#Top
	LINES[0].position = lerp(LINES[0].position, pos + Vector2(0, -speed * DISTANCE), SPEED)
	#Bottom
	LINES[1].position = lerp(LINES[1].position, pos + Vector2(0, speed * DISTANCE), SPEED)
	#Left
	LINES[2].position = lerp(LINES[2].position, pos + Vector2(-speed * DISTANCE, 0), SPEED)
	#Right
	LINES[3].position = lerp(LINES[3].position, pos + Vector2(speed * DISTANCE, 0), SPEED)
