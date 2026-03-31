extends Node

var zombie_health := 0
var player_pos: Vector3
var player_hit := false
var DAMAGE: int
var dir: Vector3
var zombies_alive: int
var is_pauseable: bool
var give_ammo: bool
var can_spawn_double: bool
var cutscene_played := false
var can_control: bool
var once_death: bool
var zombies_now: bool
var spawn_boxes: bool
var wave_num := 0
