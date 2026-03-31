class_name Player
extends CharacterBody3D

@export var HEALTH := 100
@export var STAMINA := 500
@export var WALK_SPEED := 4.0
@export var RUN_SPEED := 6.0
@export var JUMP_VELOCITY := 5
@export var SENSITIVITY := 0.006
@export var BOB_FREQUENCY := 2
@export var BOB_DISTANCE := 0.05
@export var FOV := 75.0
@export var INTERACT_DISTANCE := 2.0
@export_category("Camera")
@export var SIDEWAYS_TILT := 1
@export var FALL_TILT_TIME := 0.3
@export var FALL_THRESHOLD := -5.5
@export_category("Weapon")
@export var WEAPON_BOB_H := 1
@export var WEAPON_BOB_V := 4
@export_category("Others")
@export var can_control := false

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Recoil/Camera
@onready var animations: AnimationPlayer = $Animations
@onready var crouch_check: ShapeCast3D = $CrouchCheck
@onready var weapons: MeshInstance3D = %Weapons
@onready var ammo: Label = $HUD/Magazine
@onready var total_ammo: Label = $HUD/Ammo
@onready var weapon_name: Label = $"HUD/Weapon Name"
@onready var health: ProgressBar = $HUD/Health/Health
@onready var stamina: ProgressBar = $HUD/Stamina/Stamina
@onready var health_underlay: ProgressBar = $HUD/Health/HealthUnderlay
@onready var stamina_regen_wait: Timer = $"HUD/Stamina/Stamina Regen Wait"
@onready var gate_anims: AnimationPlayer = $"../Navigation/Wall/Gate/AnimationPlayer"
@onready var spawn_points: Node3D = $"../Spawn Points"
@onready var cutscenes: AnimationPlayer = $"../Cutscenes"
@onready var gate_clang: AudioStreamPlayer3D = $"../Gate Clang"
@onready var middle: ColorRect = $HUD/Middle
@onready var up: ColorRect = $HUD/Up
@onready var down: ColorRect = $HUD/Down
@onready var ui: Control = $UI
@onready var boxes: Node3D = $"../Navigation/Boxes"
@onready var main_music: AudioStreamPlayer3D = $"../Audios/Main Music"
@onready var entry_music: AudioStreamPlayer3D = $"../Audios/Entry Music"
@onready var death_text: Label = $"HUD/Death Text"
@onready var death_wait: Timer = $"Death wait"
@onready var death_shader: ColorRect = $"HUD/Death Shader"
@onready var stair_trigger: Node3D = $"Head/Recoil/Camera/Stair Trigger"
@onready var movement_tutorial: Label = $"UI/Movement Tutorial"
@onready var jumping_tutorial: Label = $"UI/Jupming Tutorial"
@onready var shooting_tutorial: Label = $"UI/Shooting Tutorial"

const AK_47 := preload("res://weapon_resource/ak47.tres")
const AUG := preload("res://weapon_resource/aug.tres")
const FAMAS := preload("res://weapon_resource/famas.tres")
const GLOCK_18 := preload("res://weapon_resource/glock_18.tres")
const M_4A_1 := preload("res://weapon_resource/m4a1.tres")
const MAC_10 := preload("res://weapon_resource/mac10.tres")
const MP_5 := preload("res://weapon_resource/mp5.tres")
const P_90 := preload("res://weapon_resource/p90.tres")
const SCAR_H := preload("res://weapon_resource/scar-h.tres")
const TEC_9 := preload("res://weapon_resource/tec 9.tres")
const UMP_45 := preload("res://weapon_resource/ump 45.tres")

var speed := 0.0
var time_bob := 0.0
var is_crouching := false
var interact_cast_result
var fall_value := 0.0
var FALL_TILT_TIMER := 0.0
var forward_tilt_max := 1.25
var current_fall_velocity: float 
var current_health: int
var is_dead := false
var current_stamina := 0
var stamina_drain := 0.1
var stamina_regen := 75
var is_regening := false
var can_sprint := true
var gameplay_running := false
var given_ammo := false

var shader_material := ShaderMaterial.new()

var waves = [
	{"zombies":8, "health":15, "wait":2.8, "atp":6, "weapon":GLOCK_18},
	{"zombies":12, "health":17, "wait":2.6, "atp":8, "weapon":TEC_9},
	{"zombies":14, "health":19, "wait":2.4, "atp":10, "weapon":MAC_10},
	{"zombies":18, "health":21, "wait":2.2, "atp":12, "weapon":UMP_45},
	{"zombies":24, "health":23, "wait":2.0, "atp":14, "weapon":MP_5},
	{"zombies":26, "health":25, "wait":1.8, "atp":14, "weapon":P_90},
	{"zombies":32, "health":27, "wait":1.6, "atp":14, "weapon":FAMAS},
	{"zombies":34, "health":29, "wait":1.4, "atp":14, "weapon":AK_47},
	{"zombies":36, "health":31, "wait":1.2, "atp":16, "weapon":AUG},
	{"zombies":40, "health":33, "wait":1.0, "atp":17, "weapon":SCAR_H},
	{"zombies":40, "health":35, "wait":0.75, "atp":18, "weapon":M_4A_1}]

func _ready() -> void:
	death_wait.start()
	current_health = HEALTH
	Variables.player_hit = false
	middle.position = Vector2(0, 0)
	middle.visible = true
	shader_material.shader = preload("res://scripts/vhs.gdshader")
	death_shader.material = null
	death_shader.visible = false
	if !Variables.cutscene_played:
		cutscenes.play("intro")
		entry_music.play()
		Variables.is_pauseable = false
		can_control = false
	else:
		cutscenes.play("restart")
		Variables.is_pauseable = true
	position = Vector3(16, -5, 5)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crouch_check.add_exception($".")
	current_stamina = STAMINA
	stamina.max_value = STAMINA
	health.max_value = HEALTH
	stamina.max_value = STAMINA

func _input(event: InputEvent) -> void:
	if !can_control: return
	if is_dead: return
	if event.is_action_pressed("interact"):
		interact()

func _unhandled_input(event: InputEvent) -> void:
	if is_dead or !can_control: return
	# Jump
	if event.is_action_pressed("jump") and !is_crouching:
		jump()
	
	# Crouch
	if event.is_action_pressed("crouch"):
		crouch()
	
	# Rotate Camera
	if event is InputEventMouseMotion and can_control:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-70), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	if is_dead: 
		return
	if current_health <= 0 and death_wait.is_stopped():
		die()
		return
	
	if Variables.spawn_boxes:
		ammo_boxes(true)
		Variables.spawn_boxes = false
	
	if weapons.total_ammo_count > 50:
		ammo_boxes(false)
	
	#if Input.is_action_just_pressed("temp"):
	#	cutscenes.stop()
	#	position = Vector3(8.108, -5.086, 5.8)
	#	rotation = Vector3(0, 90, 0)
	#	can_control = true
	#	up.visible = false
	#	down.visible = false
	#	middle.visible = false
	#	weapons.visible = true
	#	ui.visible = true
	#	head.rotation = Vector3(0, 0 ,0)
	#	camera.rotation = Vector3(0, 0 ,0)
	#	start_gameplay()
	
	if can_control:
		Variables.can_control = true
	else:
		Variables.can_control = false
	
	Variables.player_pos = global_position
	
	if Variables.player_hit:
		take_damage(Variables.DAMAGE)
		hit(Variables.dir)
	
	# Handle Movement
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			if stair_trigger.jump == true:
				velocity.y += 3
				stair_trigger.jump = false
			weapons.weapon_bob(delta, speed, WEAPON_BOB_H * (speed / 1.5), WEAPON_BOB_V)
			weapons.weapon_sway(delta, false)
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			weapons.weapon_sway(delta, true)
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		weapons.weapon_sway(delta, true)
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 5.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 4.0)
	if velocity != Vector3(0, 0, 0):
		weapons.weapon_bob(delta, 2.0, 0.01, 0.025)
	
	# Funcs
	head_bob(delta)
	
	show_hud_data()
	
	fov(delta)
	
	add_gravity(delta)
	
	camera_tilt(delta)
	
	get_ammo()
	
	change_speed(delta)
	
	air_procces()
	
	interact_cast()
	
	move_and_slide()

func add_gravity(delta) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func fov(delta) -> void:
	var horizontal_velocity := Vector3(velocity.x, 0, velocity.z).length()
	var velocity_clamped = clamp(horizontal_velocity, 0.5, RUN_SPEED * 2)
	var target_fov: float = FOV + velocity_clamped * 2
	if is_crouching:
		target_fov *= 0.85
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

func crouch() -> void:
	if is_crouching and !crouch_check.is_colliding():
		animations.play_backwards("crouch")
		is_crouching = !is_crouching
	elif !is_crouching:
		animations.play("crouch")
		is_crouching = !is_crouching

func change_speed(delta) -> void:
	if !can_control: return
	if Input.is_action_pressed("right") and !Input.is_action_pressed("left") and !Input.is_action_pressed("backward") and !Input.is_action_pressed("forward"):
		can_sprint = false
	else:
		can_sprint = true
	if Input.is_action_pressed("run") and current_stamina > 0 and can_sprint:
		is_regening = false
		speed = RUN_SPEED
		if velocity.x > 0.01 or velocity.z > 0.01:
			current_stamina -= stamina_drain * delta
			current_stamina = clamp(current_stamina, 0, STAMINA)
	else:
		speed = WALK_SPEED
		if current_stamina < STAMINA and stamina_regen_wait.is_stopped():
			stamina_regen_wait.start()
		if is_regening and current_stamina < STAMINA:
			current_stamina += stamina_regen * delta
			current_stamina = clamp(current_stamina, 0, STAMINA)
	stamina.value = current_stamina
	if is_crouching:
		speed /= 3

func head_bob(delta) -> void:
	time_bob += delta * velocity.length() * float(is_on_floor())
	var pos := Vector3.ZERO
	pos.y = sin(time_bob * BOB_FREQUENCY) * BOB_DISTANCE
	#pos.x = abs(sin(time_bob * BOB_FREQUENCY / 2) * BOB_DISTANCE)
	camera.transform.origin = pos

func jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func interact() -> void:
	if interact_cast_result and interact_cast_result.has_user_signal("interacting"):
		interact_cast_result.emit_signal("interacting")

func interact_cast() -> void:
	if is_dead: return
	var space_state := camera.get_world_3d().direct_space_state
	var screen_center: Vector2 = get_viewport().size / 2
	screen_center.x += 1
	screen_center.y += 1
	var origin := camera.project_ray_origin(screen_center)
	var end := origin + camera.project_ray_normal(screen_center) * INTERACT_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_bodies = true
	var result := space_state.intersect_ray(query)
	var current_cast_result = result.get("collider")
	if current_cast_result != interact_cast_result:
		if interact_cast_result and interact_cast_result.has_user_signal("unfocused"):
			interact_cast_result.emit_signal("unfocused")
		if current_cast_result and current_cast_result.has_user_signal("focused"):
			current_cast_result.emit_signal("focused")
	interact_cast_result = current_cast_result

func camera_tilt(delta) -> void:
	if !can_control: return
	if is_dead: return
	var angles := camera.rotation
	var offset := Vector3.ZERO
	var right_dot := velocity.dot(camera.global_transform.basis.x)
	var right_tilt := clampf(right_dot * deg_to_rad(SIDEWAYS_TILT), deg_to_rad(-SIDEWAYS_TILT), deg_to_rad(SIDEWAYS_TILT))
	angles.z = lerp(angles.z, -right_tilt, delta * 125)
	FALL_TILT_TIMER -= delta
	var fall_ratio = max(0.0, FALL_TILT_TIMER / FALL_TILT_TIME)
	var fall_kick_amount = fall_ratio * fall_value
	angles.x -= fall_kick_amount
	offset.y -= fall_kick_amount
	camera.position = offset
	camera.rotation = lerp(camera.rotation, angles, delta * 8.0)
	head.rotation.x = lerp(head.rotation.x, 0.0, delta * 8) - fall_kick_amount

func add_fall_kick(fall_strength: float) -> void:
	if is_dead: return
	fall_value = deg_to_rad(fall_strength)
	FALL_TILT_TIMER = FALL_TILT_TIME

func check_fall_speed() -> bool:
	return current_fall_velocity < FALL_THRESHOLD

func air_procces() -> void:
	if is_dead: return
	if is_on_floor():
		if check_fall_speed():
			var fall_strength = abs(current_fall_velocity) * 0.35
			add_fall_kick(fall_strength)
	current_fall_velocity = velocity.y

func show_hud_data() -> void:
	weapon_name.text = str(weapons.weapon.weapon_name)
	ammo.text = str(weapons.magazine_count)
	total_ammo.text = str(weapons.total_ammo_count)

func hit(dir) -> void:
	if is_dead: return
	dir.y *= 0 
	velocity += dir * 10
	Variables.player_hit = false

func die() -> void:
	death_wait.stop()
	gameplay_running = false
	if is_dead or Variables.once_death or !death_wait.is_stopped():
		return
	Variables.once_death = true
	is_dead = true
	death_shader.visible = true
	death_shader.material = shader_material
	can_control = false
	cutscenes.play("die")
	await get_tree().create_timer(2.4).timeout
	death_text.text = "GET UP"
	await get_tree().create_timer(2.6).timeout
	get_tree().reload_current_scene()

func take_damage(damage) -> void:
	if is_dead: return
	if not is_instance_valid(self): return
	current_health -= damage
	current_health = clamp(current_health, 0, HEALTH)
	health.value = current_health
	await get_tree().create_timer(0.5).timeout
	await get_tree().create_timer(0.5).timeout
	var tween = create_tween()
	tween.tween_property(health_underlay, "value", health.value, 0.5)

func _on_stamina_regen_wait_timeout() -> void:
	is_regening = true

func intro_method() -> void:
	gate_anims.play_backwards("close")
	await get_tree().create_timer(10).timeout
	Variables.is_pauseable = true
	main_music.playing = true
	can_control = true

func outro_method() -> void:
	camera.rotation = Vector3(0, 0, 0)
	head.rotation = Vector3(0, 0, 0)
	await get_tree().create_timer(3.5).timeout
	gate_anims.play("open")

func remove_velo_aftet_cut() -> void:
	velocity.y = 0

func wave_manager(zombies, z_health, wait, atp) -> void:
	Variables.zombies_now = atp
	print(Variables.zombies_alive)
	if not is_instance_valid(self): return
	Variables.zombie_health = z_health
	for i in range(zombies):
		if is_dead:
			return
		await get_tree().create_timer(wait).timeout
		var point = spawn_points.get_child(randi_range(0, spawn_points.get_child_count() - 1))
		var tries := 0
		var max_tries := 12
		while !point.can_spawn and tries < max_tries:
			tries += 1
			point = spawn_points.get_child(randi_range(0, spawn_points.get_child_count() - 1))
		if point.can_spawn:
			point.spawn_zombie()
			Variables.zombies_alive += 1
			print("added: ", Variables.zombies_alive)
		else:
			point.spawn_second_zombie()
			Variables.zombies_alive += 1
			print("added: ", Variables.zombies_alive)
		while Variables.zombies_alive >= atp and !is_dead:
			await get_tree().create_timer(0.2).timeout
	while Variables.zombies_alive > 0 and !is_dead:
		await get_tree().create_timer(0.2).timeout
	Variables.wave_num += 1
	print("ended")

func ending() -> void:
	if not is_instance_valid(self): return
	Variables.is_pauseable = false
	cutscenes.play("ending")
	await get_tree().create_timer(33).timeout
	get_tree().change_scene_to_file("res://scenes/main menu.tscn")

func gameplay() -> void:
	reset_gameplay_vars()
	for wave in waves:
		if is_dead: return
		wave = waves[Variables.wave_num]
		weapons.weapon = wave.weapon
		weapons.load_weapon()
		await wave_manager(wave.zombies, wave.health, wave.wait, wave.atp)
		await get_tree().create_timer(10).timeout
	can_control = false
	ending() 

func ammo_boxes(yesorno: bool) -> void:
	if yesorno == false:
		for i in range(boxes.get_child_count()):
			var box = boxes.get_child(i)
			box.visible = false
			box.get_child(2).disabled = true
	if yesorno == true:
		for i in range(boxes.get_child_count()):
			var box = boxes.get_child(i)
			box.visible = true
			box.get_child(2).disabled = false

func get_ammo() -> void:
	if Variables.give_ammo:
		weapons.total_ammo_count += 50
		Variables.give_ammo = false
		if weapons.total_ammo_count > 50:
			ammo_boxes(false)

func reset_gameplay_vars():
	Variables.zombies_alive = 0
	Variables.player_hit = false
	Variables.give_ammo = false
	Variables.once_death = false
	is_dead = false

func start_gameplay():
	Variables.cutscene_played = true
	if gameplay_running: return
	gameplay_running = true
	await gameplay()
	gameplay_running = false
