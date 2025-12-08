extends Node2D


var enemy_spawn_queue = []
var current_enemy_wave = []
var player_spawn_queue = []
var current_player_wave = []
var enemy_points = 600
var player_points = 600

var spawn_timer = 0
var spawn_interval = 25

@onready var clock_sound_timer: Timer = $clockSoundTimer
@onready var wave_timer: Timer = $WaveTimer


const KNIGHT = preload("res://knight.tscn")
const ARCHER = preload("res://archer.tscn")
const SPEARMAN = preload("res://spearman.tscn")
const WIN_LOSE_SCREEN = preload("res://win_loose screen.tscn")

@onready var sfx_new_wave: AudioStreamPlayer2D = %sfx_new_wave
@onready var sfx_clock_ticking: AudioStreamPlayer2D = %sfx_clock_ticking


const units_enum = {
	"knight": "knight",
	"archer": "archer",
	"spearman": "spearman"
}

const units_cost = {
	"knight": 30,
	"spearman": 40,
	"archer": 80,
}

@onready var play_layer: Node2D = $PlayLayer
@onready var canvas_layer: CanvasLayer = $CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Singleton.game = self
	Singleton.update_points()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Check if user pressed a summon button
	if (Input.is_action_just_pressed("spawn_knight") and player_points >= units_cost.knight):
		player_points -= units_cost.knight
		player_spawn_queue.append(units_enum.knight)
	
	if (Input.is_action_just_pressed("spawn_archer") and player_points >= units_cost.archer):
		player_points -= units_cost.archer
		player_spawn_queue.append(units_enum.archer)
	
	if (Input.is_action_just_pressed("spawn_spearman") and player_points >= units_cost.spearman):
		player_points -= units_cost.spearman
		player_spawn_queue.append(units_enum.spearman)
	
	if (Input.is_action_just_pressed("cancel_unit")):
		cancel_unit()
	
	if Input.is_action_just_pressed("spawn_archer") or Input.is_action_just_pressed("spawn_knight") or Input.is_action_just_pressed("spawn_spearman") or Input.is_action_just_pressed("cancel_unit"):
		Singleton.update_icons(player_spawn_queue)
		Singleton.update_points()
		%thump.play()
	
	Singleton.update_wave_timer(wave_timer)
	
	# if there's anything in the queues summon every 60 frames
	spawn_timer += 1
	if (spawn_timer % spawn_interval == 0):
		if(current_player_wave.size() > 0):
			spawnUnit("player")
		
		if(current_enemy_wave.size() > 0):
			spawnUnit("enemy")

func spawnUnit(team):
	var unit_type
	if (team == "player"):
		unit_type = current_player_wave.pop_front()
	else:
		unit_type = current_enemy_wave.pop_front()
		
	var unit_instance
	if unit_type == units_enum.knight:
		unit_instance = KNIGHT.instantiate()
	elif unit_type == units_enum.archer:
		unit_instance = ARCHER.instantiate()
	elif unit_type == units_enum.spearman:
		unit_instance = SPEARMAN.instantiate()
	unit_instance.team = team
	# initial position should not be in the loose area for any unit
	unit_instance.position = Vector2(500, 500)
	play_layer.add_child(unit_instance)


func _on_wave_timer_timeout() -> void:
	# calculate what units the enemy should spawn
	while enemy_points >= units_cost.knight:
		# twice as likely to select archers
		var selected_unit = [units_enum.knight, units_enum.archer, units_enum.archer, units_enum.spearman].pick_random()
		if enemy_points < units_cost[selected_unit]:
			selected_unit = units_enum.knight
		
		enemy_points -= units_cost[selected_unit]
		enemy_spawn_queue.append(selected_unit)
	
	# start wave
	# empty both arrays and move them to the next wave
	current_enemy_wave.append_array(enemy_spawn_queue.duplicate())
	enemy_spawn_queue.clear()

	current_player_wave.append_array(player_spawn_queue.duplicate())
	player_spawn_queue.clear()
	
	Singleton.update_icons(player_spawn_queue)
	clock_sound_timer.start()
	sfx_new_wave.play()


func _on_clock_sound_timer_timeout() -> void:
	sfx_clock_ticking.play()


func cancel_unit():
	if (player_spawn_queue.size() > 0 ):
		var last_unit = player_spawn_queue.pop_back()
		player_points += units_cost[last_unit]


func _on_loose_condition_area_body_entered(body: Node2D) -> void:
	# check if its an enemy
	if body.has_method("_get_team"):
		var team = body._get_team()
		if team == "enemy":
			var win_lose_screen = WIN_LOSE_SCREEN.instantiate()
			canvas_layer.add_child(win_lose_screen)
			win_lose_screen.loose_display()
			get_tree().paused = true


func _on_win_condition_area_body_entered(body: Node2D) -> void:
	# check if its a player unit (win condition)
	if body.has_method("_get_team"):
		var team = body._get_team()
		if team == "player":
			var win_lose_screen = WIN_LOSE_SCREEN.instantiate()
			canvas_layer.add_child(win_lose_screen)
			win_lose_screen.win_display()
			get_tree().paused = true
