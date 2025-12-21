extends Node2D


var enemy_spawn_queue = []
var current_enemy_wave = []
var player_spawn_queue = []
var current_player_wave = []
var wave_counter := 0
var enemy_points = 800
var player_points = 600
var spawn_timer = 0
var spawn_interval = 30

@onready var clock_sound_timer: Timer = $clockSoundTimer
@onready var wave_timer: Timer = $WaveTimer


const KNIGHT = preload("res://knight.tscn")
const ARCHER = preload("res://archer.tscn")
const SPEARMAN = preload("res://spearman.tscn")
const HEALER = preload("res://healer.tscn")
const WIN_LOSE_SCREEN = preload("res://win_loose screen.tscn")


const BEAR = preload("res://bear.tscn")
const PANDA = preload("res://panda.tscn")
const GNOME = preload("res://gnome.tscn")
const SPIDER = preload("res://spider.tscn")
const LIZARD = preload("res://lizard.tscn")


@onready var sfx_new_wave: AudioStreamPlayer2D = %sfx_new_wave
@onready var sfx_clock_ticking: AudioStreamPlayer2D = %sfx_clock_ticking


const units_enum = {
	"knight": "knight",
	"archer": "archer",
	"spearman": "spearman",
	"healer": "healer",
	"bear": "bear",
	"panda": "panda",
	"gnome": "gnome",
	"spider": "spider",
	"lizard": "lizard"
}

const units_cost = {
	"knight": 30,
	"spearman": 50,
	"archer": 80,
	"healer": 100,
	"bear": 130,
	"panda": 70,
	"gnome": 30,
	"spider": 40,
	"lizard": 90
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
	
	if (Input.is_action_just_pressed("spawn_healer") and player_points >= units_cost.healer):
		player_points -= units_cost.healer
		player_spawn_queue.append(units_enum.healer)
	
	if (Input.is_action_just_pressed("cancel_unit")):
		cancel_unit()
	
	if Input.is_action_just_pressed("spawn_archer") or Input.is_action_just_pressed("spawn_knight") or Input.is_action_just_pressed("spawn_spearman") or Input.is_action_just_pressed("spawn_healer") or Input.is_action_just_pressed("cancel_unit"):
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
	elif unit_type == units_enum.healer:
		unit_instance = HEALER.instantiate()
	## ENEMY UNITS
	elif unit_type == units_enum.bear:
		unit_instance = BEAR.instantiate()
	elif unit_type == units_enum.panda:
		unit_instance = PANDA.instantiate()
	elif unit_type == units_enum.gnome:
		unit_instance = GNOME.instantiate()
	elif unit_type == units_enum.spider:
		unit_instance = SPIDER.instantiate()
	elif unit_type == units_enum.lizard:
		unit_instance = LIZARD.instantiate()
	unit_instance.team = team
	# initial position should not be in the loose area for any unit
	unit_instance.position = Vector2(500, 500)
	# just a little  movement speed variance
	unit_instance.movement_speed += randi_range(-4,4)
	play_layer.add_child(unit_instance)


func _on_wave_timer_timeout() -> void:
	# calculate what units the enemy should spawn using strategic AI
	wave_counter += 1
	calculate_enemy_wave_composition()
	
	# check if the queue has over 20 units. if so decrease the time between spawning units
	if player_spawn_queue.size() > 20:
		spawn_interval = 10
	else:
		spawn_interval = 30
	
	# start wave
	# empty both arrays and move them to the next wave
	current_enemy_wave.append_array(enemy_spawn_queue.duplicate())
	enemy_spawn_queue.clear()

	current_player_wave.append_array(player_spawn_queue.duplicate())
	player_spawn_queue.clear()
	
	Singleton.update_icons(player_spawn_queue)
	clock_sound_timer.start()
	sfx_new_wave.play()
	
	if wave_counter < 10:
		# Give additional money to you and enemy after wave was summoned
		enemy_points += 100
		player_points += 50
		Singleton.update_points()


func _on_clock_sound_timer_timeout() -> void:
	sfx_clock_ticking.play()


func calculate_enemy_wave_composition():
	var original_points = enemy_points
	
	## right now im making enemy monster units so im just spawning those
	spawn_monster_wave()
	return
	
	
	# When under 500 points, 50% chance to wait and spawn nothing (only once at a time)
	if enemy_points < 500 and randf() < 0.5:
		return  # Skip spawning this wave

	# Define strategic compositions based on budget ranges
	if enemy_points >= 500:  # Large budget - Balanced elite army
		spawn_balanced_elite_army()
	elif enemy_points >= 300:  # Medium-high budget - Mixed tactical force
		spawn_mixed_tactical_force()
	elif enemy_points >= 150:  # Medium budget - Focused strategy
		spawn_focused_strategy()
	elif enemy_points >= 60:   # Low budget - Rush strategy
		spawn_rush_strategy()
	else:  # Very low budget - Whatever we can afford
		spawn_minimal_force()

func spawn_balanced_elite_army():
	# For large budgets: Create a well-balanced army with support units
	# Composition: 25% Knights, 30% Archers, 25% Spearmen, 20% Healers
	var target_healers = max(1, int(enemy_points * 0.20 / units_cost.healer))
	var target_knights = max(1, int(enemy_points * 0.25 / units_cost.knight))
	var target_archers = max(2, int(enemy_points * 0.30 / units_cost.archer))
	
	# Spawn healers first (support units)
	for i in target_healers:
		if enemy_points >= units_cost.healer:
			enemy_points -= units_cost.healer
			enemy_spawn_queue.append(units_enum.healer)
	
	# Spawn knights (tanks)
	for i in target_knights:
		if enemy_points >= units_cost.knight:
			enemy_points -= units_cost.knight
			enemy_spawn_queue.append(units_enum.knight)
	
	# Fill remaining points with archers and spearmen
	while enemy_points >= units_cost.spearman:
		if enemy_points >= units_cost.archer and randf() < 0.6:  # 60% chance for archer
			enemy_points -= units_cost.archer
			enemy_spawn_queue.append(units_enum.archer)
		else:
			enemy_points -= units_cost.spearman
			enemy_spawn_queue.append(units_enum.spearman)

func spawn_mixed_tactical_force():
	# Medium-high budget: Focus on archers with knight support
	# Composition: 45% Archers, 40% Knights, 15% Spearmen
	var archer_budget = int(enemy_points * 0.45)
	var knight_budget = int(enemy_points * 0.4)
	
	# Spawn archers (main damage dealers)
	while archer_budget >= units_cost.archer and enemy_points >= units_cost.archer:
		enemy_points -= units_cost.archer
		archer_budget -= units_cost.archer
		enemy_spawn_queue.append(units_enum.archer)
	
	# Spawn knights (protection for archers)
	while knight_budget >= units_cost.knight and enemy_points >= units_cost.knight:
		enemy_points -= units_cost.knight
		knight_budget -= units_cost.knight
		enemy_spawn_queue.append(units_enum.knight)
	
	# Fill remaining with spearmen
	while enemy_points >= units_cost.spearman:
		enemy_points -= units_cost.spearman
		enemy_spawn_queue.append(units_enum.spearman)

func spawn_focused_strategy():
	# Medium budget: Choose a focused strategy
	var strategy = randi() % 3
	
	if strategy == 0:  # Archer focus - ranged superiority
		spawn_archer_focused_wave()
	elif strategy == 1:  # Knight rush - heavy armor push
		spawn_knight_focused_wave()
	else:  # Spearman swarm - numbers advantage
		spawn_spearman_focused_wave()

func spawn_archer_focused_wave():
	# 70% archers, 30% knights for protection
	var knight_count = max(1, int(enemy_points * 0.3 / units_cost.knight))
	
	# Spawn some knights first for protection
	for i in knight_count:
		if enemy_points >= units_cost.knight:
			enemy_points -= units_cost.knight
			enemy_spawn_queue.append(units_enum.knight)
	
	# Fill rest with archers
	while enemy_points >= units_cost.archer:
		enemy_points -= units_cost.archer
		enemy_spawn_queue.append(units_enum.archer)

func spawn_knight_focused_wave():
	# Heavy knight focus with minimal support
	# 80% knights, 20% spearmen
	var spearman_budget = int(enemy_points * 0.2)
	
	# Spawn a few spearmen for variety
	while spearman_budget >= units_cost.spearman and enemy_points >= units_cost.spearman:
		enemy_points -= units_cost.spearman
		spearman_budget -= units_cost.spearman
		enemy_spawn_queue.append(units_enum.spearman)
	
	# Fill rest with knights
	while enemy_points >= units_cost.knight:
		enemy_points -= units_cost.knight
		enemy_spawn_queue.append(units_enum.knight)

func spawn_spearman_focused_wave():
	# Spearman swarm with some knight support
	# 25% knights, 75% spearmen
	var knight_count = max(1, int(enemy_points * 0.25 / units_cost.knight))
	
	# Spawn some knights for tanking
	for i in knight_count:
		if enemy_points >= units_cost.knight:
			enemy_points -= units_cost.knight
			enemy_spawn_queue.append(units_enum.knight)
	
	# Fill rest with spearmen
	while enemy_points >= units_cost.spearman:
		enemy_points -= units_cost.spearman
		enemy_spawn_queue.append(units_enum.spearman)

func spawn_rush_strategy():
	# Low budget: Quick decisive action
	if enemy_points >= units_cost.healer + units_cost.knight:
		# Healer + knight combo for survivability
		enemy_points -= units_cost.healer
		enemy_spawn_queue.append(units_enum.healer)
		enemy_points -= units_cost.knight
		enemy_spawn_queue.append(units_enum.knight)
	elif enemy_points >= units_cost.archer * 2:
		# Double archer for range advantage
		enemy_points -= units_cost.archer
		enemy_spawn_queue.append(units_enum.archer)
		enemy_points -= units_cost.archer
		enemy_spawn_queue.append(units_enum.archer)
	else:
		# Just spam cheapest effective units
		while enemy_points >= units_cost.knight:
			enemy_points -= units_cost.knight
			enemy_spawn_queue.append(units_enum.knight)

func spawn_minimal_force():
	# Very low budget: Just get what we can
	while enemy_points >= units_cost.knight:
		enemy_points -= units_cost.knight
		enemy_spawn_queue.append(units_enum.knight)

func cancel_unit():
	if (player_spawn_queue.size() > 0 ):
		var last_unit = player_spawn_queue.pop_back()
		player_points += units_cost[last_unit]


func spawn_monster_wave():
	
	##Debugging spiders
	#while enemy_points >= enemy_units_cost.spider:
		#enemy_points -= enemy_units_cost.spider
		#enemy_spawn_queue.append(units_enum.spider)
	
	
	var target_bears = max(1, int(enemy_points * 0.2 / units_cost.bear))
	var target_lizards = max(1, int(enemy_points * 0.3 / units_cost.lizard))
	var target_pandas = max(1, int(enemy_points * 0.2 / units_cost.panda))
	var target_gnomes = max(1, int(enemy_points * 0.1 / units_cost.gnome))
	var target_spiders = max(1, int(enemy_points * 0.2 / units_cost.spider))
	
	
	for i in target_lizards:
		if enemy_points >= units_cost.lizard:
			enemy_points -= units_cost.lizard
			enemy_spawn_queue.append(units_enum.lizard)

	for i in target_bears:
		if enemy_points >= units_cost.bear:
			enemy_points -= units_cost.bear
			enemy_spawn_queue.append(units_enum.bear)

	for i in target_spiders:
		if enemy_points >= units_cost.spider:
			enemy_points -= units_cost.spider
			enemy_spawn_queue.append(units_enum.spider)
	
	for i in target_pandas:
		if enemy_points >= units_cost.panda:
			enemy_points -= units_cost.panda
			enemy_spawn_queue.append(units_enum.panda)
	
	#spend the rest on GNOOOOMES
	while enemy_points >= units_cost.gnome:
		enemy_points -= units_cost.gnome
		enemy_spawn_queue.append(units_enum.gnome)
	

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


func get_points_for_unit(unit: String):
	return units_cost[unit]
