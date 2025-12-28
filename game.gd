extends Node2D

# Game mode
enum GameMode { CLASSIC, WAVES }
var current_game_mode: GameMode = GameMode.CLASSIC

var enemy_spawn_queue = []
var current_enemy_wave = []
var player_spawn_queue = []
var current_player_wave = []
var wave_counter := 0
var enemy_points = 800
var player_points = 600
var spawn_timer = 0
var spawn_interval = 30
var ability_mode = false

# Wave mode configuration
var wave_definitions = [
	{"points": 200, "strategy": "panda_gnome"},     # Wave 1
	{"points": 260, "strategy": "panda_gnome"},     # Wave 2
	{"points": 325, "strategy": "spider_lizard"},   # Wave 3
	{"points": 395, "strategy": "spider_lizard"},   # Wave 4
	{"points": 470, "strategy": "spider_lizard"},   # Wave 5
	{"points": 550, "strategy": "spider_lizard"},   # Wave 6
	{"points": 635, "strategy": "bear_only"},       # Wave 7
	{"points": 725, "strategy": ""},                # Wave 8
	{"points": 820, "strategy": ""},                # Wave 9
	{"points": 920, "strategy": ""},                # Wave 10
	{"points": 1025, "strategy": ""},               # Wave 11
	{"points": 1135, "strategy": ""},               # Wave 12
	{"points": 1250, "strategy": "bear_only"},               # Wave 13
	{"points": 1370, "strategy": "spider_lizard"},               # Wave 14
	{"points": 1495, "strategy": "spider_lizard"},               # Wave 15
	{"points": 1625, "strategy": "spider_lizard"},               # Wave 16
	{"points": 1760, "strategy": "bear_only"},               # Wave 17
	{"points": 1900, "strategy": ""},               # Wave 18
	{"points": 1950, "strategy": ""},               # Wave 19
	{"points": 2000, "strategy": "bear_only"},               # Wave 20
]

@onready var clock_sound_timer: Timer = $clockSoundTimer
@onready var wave_timer: Timer = $WaveTimer


const KNIGHT = preload("res://knight.tscn")
const ARCHER = preload("res://archer.tscn")
const SPEARMAN = preload("res://spearman.tscn")
const HEALER = preload("res://healer.tscn")
const WIN_LOSE_SCREEN = preload("res://win_loose screen.tscn")
const ABILITY_CURSOR = preload("res://ability_cursor.tscn")


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
	"spearman": 60,
	"archer": 80,
	"healer": 100,
	"bear": 130,
	"panda": 70,
	"gnome": 30,
	"spider": 40,
	"lizard": 90
}

const tower_cost = {
	"archer_tower": 350,
	"twin_archer_tower": 250,
	"triple_archer_tower": 800,
	"quad_archer_tower": 350
}

@onready var play_layer: Node2D = $PlayLayer
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var player_base = $PlayLayer/PlayerBase
@onready var enemy_base = $PlayLayer/EnemyBase


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Singleton.game = self
	Singleton.update_points()
	
	# Initialize ability cursor
	var cursor_instance = ABILITY_CURSOR.instantiate()
	play_layer.add_child(cursor_instance)
	Singleton.ability_cursor = cursor_instance
	
	# Set game mode based on scene name
	var scene_name = get_tree().current_scene.name
	if scene_name == "level1":
		current_game_mode = GameMode.CLASSIC
	elif scene_name == "level2":
		current_game_mode = GameMode.WAVES
	
	# Connect base destroyed signals
	if player_base:
		player_base.base_destroyed.connect(_on_base_destroyed)
	if enemy_base:
		enemy_base.base_destroyed.connect(_on_base_destroyed)
	


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
	
	if current_game_mode == GameMode.WAVES:
		calculate_wave_mode_composition()
	else:
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
	
	# In classic mode, give additional money
	if current_game_mode == GameMode.CLASSIC and wave_counter < 10:
		# Give additional money to you and enemy after wave was summoned
		enemy_points += 100
		player_points += 50
		Singleton.update_points()
	# In waves mode, always give player money
	elif current_game_mode == GameMode.WAVES:
		player_points += 75
		Singleton.update_points()


func _on_clock_sound_timer_timeout() -> void:
	sfx_clock_ticking.play()


func calculate_wave_mode_composition():
	# Get the wave definition for the current wave
	var wave_index = wave_counter - 1
	
	# If we've exceeded defined waves, cap at the last wave's points
	if wave_index >= wave_definitions.size():
		# Cap at the final wave's points, don't scale further
		enemy_points = wave_definitions[wave_definitions.size() - 1]["points"]
	else:
		var wave_def = wave_definitions[wave_index]
		enemy_points = wave_def["points"]
		
		# Check if wave has a specific strategy
		if wave_def["strategy"] != "":
			# Execute specific wave mode strategy
			match wave_def["strategy"]:
				"panda_gnome":
					spawn_panda_gnome_wave()
				"spider_lizard":
					spawn_spider_lizard_wave()
				"bear_only":
					spawn_bear_only_wave()
				_:
					# Default to monster wave
					spawn_monster_wave()
			return
	
	# Use default monster wave strategy
	spawn_monster_wave()


# ============================================================================
# CLASSIC MODE STRATEGIES (Knights, Archers, Spearmen, Healers)
# ============================================================================

func calculate_enemy_wave_composition():
	var original_points = enemy_points
	
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
# ============================================================================
# WAVE MODE STRATEGIES (Monsters: Bear, Panda, Gnome, Spider, Lizard)
# ============================================================================

func spawn_panda_gnome_wave():
	# Waves 1-2: Only panda and gnome
	# Split budget: 60% pandas, 40% gnomes
	var panda_budget = int(enemy_points * 0.6)
	
	# Spawn pandas
	while panda_budget >= units_cost.panda and enemy_points >= units_cost.panda:
		enemy_points -= units_cost.panda
		panda_budget -= units_cost.panda
		enemy_spawn_queue.append(units_enum.panda)
	
	# Fill rest with gnomes
	while enemy_points >= units_cost.gnome:
		enemy_points -= units_cost.gnome
		enemy_spawn_queue.append(units_enum.gnome)


func spawn_spider_lizard_wave():
	# Waves 3-6: Only spider and lizard
	# Split budget: 60% lizards, 40% spiders
	var lizard_budget = int(enemy_points * 0.6)
	
	# Spawn lizards first (higher cost, tankier)
	while lizard_budget >= units_cost.lizard and enemy_points >= units_cost.lizard:
		enemy_points -= units_cost.lizard
		lizard_budget -= units_cost.lizard
		enemy_spawn_queue.append(units_enum.lizard)
	
	# Fill rest with spiders
	while enemy_points >= units_cost.spider:
		enemy_points -= units_cost.spider
		enemy_spawn_queue.append(units_enum.spider)


func spawn_bear_only_wave():
	# Wave 7: Only bears
	while enemy_points >= units_cost.bear:
		enemy_points -= units_cost.bear
		enemy_spawn_queue.append(units_enum.bear)


func spawn_monster_wave():
	# Default monster wave: Balanced mix of all creatures
	# Composition: 20% bears, 30% lizards, 20% pandas, 10% gnomes, 20% spiders
	var target_bears = max(1, int(enemy_points * 0.2 / units_cost.bear))
	var target_lizards = max(1, int(enemy_points * 0.3 / units_cost.lizard))
	var target_pandas = max(1, int(enemy_points * 0.2 / units_cost.panda))
	var target_gnomes = max(1, int(enemy_points * 0.1 / units_cost.gnome))
	var target_spiders = max(1, int(enemy_points * 0.2 / units_cost.spider))
	
	# Spawn lizards first (highest priority)
	for i in target_lizards:
		if enemy_points >= units_cost.lizard:
			enemy_points -= units_cost.lizard
			enemy_spawn_queue.append(units_enum.lizard)

	# Spawn bears
	for i in target_bears:
		if enemy_points >= units_cost.bear:
			enemy_points -= units_cost.bear
			enemy_spawn_queue.append(units_enum.bear)

	# Spawn spiders
	for i in target_spiders:
		if enemy_points >= units_cost.spider:
			enemy_points -= units_cost.spider
			enemy_spawn_queue.append(units_enum.spider)
	
	# Spawn pandas
	for i in target_pandas:
		if enemy_points >= units_cost.panda:
			enemy_points -= units_cost.panda
			enemy_spawn_queue.append(units_enum.panda)
	
	# Spend the rest on gnomes
	
	#spend the rest on GNOOOOMES
	while enemy_points >= units_cost.gnome:
		enemy_points -= units_cost.gnome
		enemy_spawn_queue.append(units_enum.gnome)
	#
#
#func _on_loose_condition_area_body_entered(body: Node2D) -> void:
	## check if its an enemy
	#if body.has_method("_get_team"):
		#var team = body._get_team()
		#if team == "enemy":
			#var win_lose_screen = WIN_LOSE_SCREEN.instantiate()
			#canvas_layer.add_child(win_lose_screen)
			#win_lose_screen.loose_display()
			#get_tree().paused = true
#
#
#func _on_win_condition_area_body_entered(body: Node2D) -> void:
	## check if its a player unit (win condition)
	#if body.has_method("_get_team"):
		#var team = body._get_team()
		#if team == "player":
			#var win_lose_screen = WIN_LOSE_SCREEN.instantiate()
			#canvas_layer.add_child(win_lose_screen)
			#win_lose_screen.win_display()
			#get_tree().paused = true


func get_points_for_unit(unit: String):
	return units_cost[unit]

func can_afford_tower(tower_type: String) -> bool:
	return player_points >= tower_cost[tower_type]

func purchase_tower(tower_type: String) -> bool:
	if can_afford_tower(tower_type):
		player_points -= tower_cost[tower_type]
		Singleton.update_points()
		return true
	return false

func set_ability_mode(enabled: bool) -> void:
	ability_mode = enabled

func _input(event: InputEvent) -> void:
	# Handle ability click FIRST - before anything else can consume the input
	if ability_mode and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var click_position = get_global_mouse_position()
			Singleton.trigger_ability_at_position(click_position)
			get_viewport().set_input_as_handled()
			return  # Early return to prevent other input processing

func _on_base_destroyed(destroyed_team: String):
	var win_lose_screen = WIN_LOSE_SCREEN.instantiate()
	canvas_layer.add_child(win_lose_screen)
	
	if destroyed_team == "player":
		# Player base destroyed = player loses
		win_lose_screen.loose_display()
	else:
		# Enemy base destroyed = player wins
		win_lose_screen.win_display()
	
	get_tree().paused = true
