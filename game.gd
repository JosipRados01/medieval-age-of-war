extends Node2D


var enemy_spawn_queue = []
var current_enemy_wave = []
var player_spawn_queue = []
var current_player_wave = []
var enemy_points = 1000
var player_points = 1000
var spawn_timer = 0
var spawn_interval = 60
var wave_spawn_timer = 0
var wave_spawn_interval = 600

const KNIGHT = preload("res://knight.tscn")

const units_enum = {
	"knight": "knight",
	"archer": "archer",
	"spearman": "spearman"
}

const units_cost = {
	"knight": 30,
	"archer": 50,
	"spearman": 40
}

@onready var play_layer: Node2D = $PlayLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Check if user pressed a summon button
	if (Input.is_action_just_pressed("spawn_knight") and player_points >= units_cost.knight):
		player_points -= units_cost.knight
		player_spawn_queue.append(units_enum.knight)
	
	# Check if the enemy should summon their wave
	wave_spawn_timer += 1
	if(wave_spawn_timer % wave_spawn_interval == 0):
		while enemy_points >= units_cost.knight:
			enemy_points -= units_cost.knight
			enemy_spawn_queue.append(units_enum.knight)
	
	if(wave_spawn_timer % wave_spawn_interval == 0):
		# empty both arrays and move them to the next wave
		current_enemy_wave.append_array(enemy_spawn_queue.duplicate())
		enemy_spawn_queue.clear()

		current_player_wave.append_array(player_spawn_queue.duplicate())
		player_spawn_queue.clear()
	
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
	#elif unit_type == units_enum.archer:
		#unit_instance = ARCHER.instantiate()
	#elif unit_type == units_enum.spearman:
		#unit_instance = SPEARMAN.instantiate()
	unit_instance.team = team
	play_layer.add_child(unit_instance)
