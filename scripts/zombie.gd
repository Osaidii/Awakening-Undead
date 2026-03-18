class_name Zombie
extends damageable

@export var SPEED := 3.0
@export var ATTACK_RANGE := 2
@export var DAMAGE := 20

@onready var player: Player = %Player
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_flow: AnimationTree = $AnimFlow
@onready var animations: AnimationPlayer = $Animations
@onready var collision: CollisionShape3D = $Collision
@onready var armature: Node3D = $Armature
@onready var general_skeleton: Skeleton3D = $Armature/GeneralSkeleton
@onready var general_skeleton_simulator: PhysicalBoneSimulator3D = $Armature/GeneralSkeleton/PhysicalBoneSimulator3D
@onready var ragdoll_anims: AnimationPlayer
@onready var eye_1: OmniLight3D = $Armature/GeneralSkeleton/PhysicalBoneSimulator3D/Head/Eye1
@onready var eye_2: OmniLight3D = $Armature/GeneralSkeleton/PhysicalBoneSimulator3D/Head/Eye2
@onready var idle_1: AudioStreamPlayer3D = $"Idle 1"
@onready var idle_2: AudioStreamPlayer3D = $"Idle 2"
@onready var hurt_1: AudioStreamPlayer3D = $"Hurt 1"
@onready var hurt_2: AudioStreamPlayer3D = $"Hurt 2"
@onready var dying: AudioStreamPlayer3D = $Die

const ZOMBIE_RAGDOLL := preload("res://instantiable/zombie_ragdoll.tscn")
var rng := RandomNumberGenerator.new()

var state_machine
var player_is_in_range: bool
var ragdoll_started := false 
var is_dead := false
var is_alive: bool
var is_playing_sound := false
var prev_health: int
var sound_timer: float

func _ready() -> void:
	is_alive = true
	current_health = Variables.zombie_health
	state_machine = anim_flow.get("parameters/playback")
	armature.visible = true

func _process(delta: float) -> void:
	if current_health <= 0:
		is_dead = true
	
	sound_timer = randf_range(5.0, 10.0)
	sound_timer -= delta
	
	if sound_timer == 0 and !is_playing_sound:
		play_sound("idle")
	
	if is_dead:
		if !ragdoll_started:
			ragdoll_started = true
			die()
			return
	
	animation()
	
	add_gravity(delta)
	
	move_and_slide()
	
	being_attacked()

func add_gravity(delta) -> void:
	velocity += (get_gravity() * 50) * delta

func animation() -> void:
	anim_flow.set("parameters/conditions/player nearby", player_is_in_range)
	anim_flow.set("parameters/conditions/player not nearby", !player_is_in_range)
	anim_flow.set("parameters/conditions/attack", player_in_attack_range())
	anim_flow.set("parameters/conditions/dead", has_died())
	match state_machine.get_current_node():
		"run":
			if player_is_in_range:
				nav_agent.set_target_position(Variables.player_pos)
				var next_nav_point := nav_agent.get_next_path_position()
				velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
				rotate_toward_player(get_process_delta_time())
		"attack":
			var target_pos = Variables.player_pos
			target_pos.y = global_position.y
			look_at(target_pos, Vector3.UP)
			rotation.y += PI
			velocity = Vector3.ZERO
		"idle":
			velocity = Vector3(0, 0, 0)
		"die":
			velocity = Vector3.ZERO

func player_in_attack_range() -> bool:
	return global_position.distance_to(Variables.player_pos) < ATTACK_RANGE

func rotate_toward_player(delta) -> void:
	rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), 10 * delta)

func hit_finished() -> void:
	if is_dead: return
	if global_position.distance_to(Variables.player_pos) < ATTACK_RANGE + 1:
		var dir = global_position.direction_to(Variables.player_pos)
		Variables.player_hit = true
		Variables.DAMAGE = DAMAGE
		Variables.dir = dir

func has_died() -> bool:
	return current_health <= 0

func die() -> void:
	if !is_playing_sound:
		play_sound("die")
		is_playing_sound = true
	is_alive = false
	Variables.zombies_alive -= 1
	anim_flow.active = false
	animations.stop()
	velocity = Vector3.ZERO
	collision.disabled = true
	armature.visible = false
	eye_1.visible = false
	eye_2.visible = false
	print("here1")
	var ragdoll = ZOMBIE_RAGDOLL.instantiate()
	ragdoll.global_transform = global_transform
	ragdoll.rotation = global_rotation
	var ragdoll_skeleton: Skeleton3D = ragdoll.get_child(0).get_child(0)
	for i in general_skeleton.get_bone_count():
		var pose := general_skeleton.get_bone_global_pose(i)
		ragdoll_skeleton.set_bone_global_pose(i, pose)
	get_parent().add_child(ragdoll)
	var ragdoll_anim: AnimationPlayer = ragdoll.get_node("Animations")
	ragdoll_anim.play("dissolve")
	var tween = create_tween()
	tween.tween_callback(Callable(ragdoll, "queue_free")).set_delay(3.5)
	print("here2")

func _on_player_body_entered(body: Node3D) -> void:
	if is_dead: return
	if body is Player:
		player_is_in_range = true

func _on_player_body_exited(body: Node3D) -> void:
	if is_dead: return
	if body is Player:
		player_is_in_range = false

func being_attacked() -> void:
	if is_dead: return
	if !player_is_in_range and old_health > current_health:
		player_is_in_range = true
	old_health = current_health

func play_sound(sound) -> void:
	match sound:
		"idle":
			var idle_sound := randi_range(1, 2)
			if idle_sound == 1:
				idle_1.pitch_scale = randf_range(0.85, 1.15)
				idle_1.play()
				
			else:
				idle_2.pitch_scale = randf_range(0.85, 1.15)
				idle_2.play()
		"hurt":
			var hurt_sound := randi_range(1, 2)
			if hurt_sound == 1:
				hurt_1.pitch_scale = randf_range(0.85, 1.15)
				hurt_1.play()
			else:
				hurt_2.pitch_scale = randf_range(0.85, 1.15)
				hurt_2.play()
		"die":
			dying.play()
			dying.pitch_scale = randf_range(0.85, 1.15)

func _on_die_finished() -> void:
	is_playing_sound = false

func _on_hurt_2_finished() -> void:
	is_playing_sound = false

func _on_hurt_1_finished() -> void:
	is_playing_sound = false

func _on_idle_2_finished() -> void:
	is_playing_sound = false

func _on_idle_1_finished() -> void:
	is_playing_sound = false
