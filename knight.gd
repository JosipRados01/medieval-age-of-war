extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var enemyDetector: Area2D = $EnemyDetector
@onready var enemy_in_range: Area2D = $Enemy_in_range
@onready var point_on_path : PathFollow2D = $"../../Path/point_on_path"

var health := 100
var damage := 30
var can_attack_again_timer
var movement_speed := 100
# "player" | "enemy"
@export var team := "player"

var is_combat_mode: bool = false
var is_attacking: bool = false
var can_attack: bool = true
var attack_animation_played = ""
var attack_cooldown_frames = 500

@export var progress_on_path_precentage:float 
var progress_on_path_pixels := 0.0

# offset variables so that we don't follow the path exactly
var side_offset := 0.0
var target_offset := 0.0
@onready var offset_change_time := 0.0

# reposition variables
var current_target_position = null
var reposition_timer = 0
var reposition_interval = 200  # frames


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#spawn on the correct position on the path
	point_on_path.progress_ratio = progress_on_path_precentage
	position = point_on_path.position
	
	# flip the scene if this is an enemy unit
	if(team == "enemy"):
		scale.x = -1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	#always update attack timer
	update_attack_timer()
	
	is_combat_mode = check_combat_mode()
	# The unit can either be in combat or moving
	if(is_combat_mode):
		# if attacking do nothing
		if(is_attacking):
			# check if the animation should turn on the hitbox or off
			pass
		else:
			#check for nearby enemies and if an enemy is close enough attack
			if(can_attack and should_unit_attack()):
				# init attack animation
				start_attack_animation()
			else:
				#reposition according to enemy. Ideal position for knight is in front of the enemy and in range for attack
				animated_sprite.play("move")
				reposition(delta)
	else:
		#continue following the path
		move_on_path(delta)

func get_enemies_detected():
	var enemies = []
	var overlaping = enemyDetector.get_overlapping_bodies()
	for enemy in overlaping:
		if (enemy.has_method("_get_team")):
			var enemy_team = enemy._get_team()
			if team != enemy_team:
				enemies.append(enemy)
	return enemies

func check_combat_mode() -> bool:
	# the unit should engage combat mode if the EnemyDetector area has enemies in the enemy team
	var enemies = get_enemies_detected()
	if(enemies.size() > 0):
		return true
	return false

func should_unit_attack() -> bool:
	# the unit should attack if the Enemy_in_range area has enemies in the enemy team
	var overlaping = enemy_in_range.get_overlapping_bodies()
	for enemy in overlaping:
		if (enemy.has_method("_get_team")):
			var enemy_team = enemy._get_team()
			if team != enemy_team:
				return true
	return false

func _get_team():
	return team

func start_attack_animation():
	is_attacking = true
	attack_animation_played = "attack_1"
	animated_sprite.play("attack_1")
	
func reposition(delta):
	reposition_timer += 1
	# if can attack - move in, if can't move away
	if(can_attack):
		# check if an enemy is already in range using should_unit_attack
		var enemy_in_range = should_unit_attack()
		if(enemy_in_range):
			return
			
	# get the position of the closest enemy detected
	var overlaping_enemies = get_enemies_detected()
	if overlaping_enemies.size() == 0: 
		return
	# for now just get the first one, but this should be the closest enemy
	var chosen_enemy = overlaping_enemies[0]
	
	if ((reposition_timer % reposition_interval == 0) or current_target_position == null):
		# if not find a point in front of the enemy to move towards
		var targetPosition = chosen_enemy.position
		var reposition_distance_x = 80 
		if not can_attack:
			reposition_distance_x = randi() % (200 - 50 + 1) + 51
		
		var reposition_distance_y = 0 
		if not can_attack:
			var y = randi() % (100 - 50 + 1) + 51  # 51..200
			if randi() % 2 == 0:
				y = -y  # randomly flip to negative side
			reposition_distance_y = y
		
		if(team == "player"):
			targetPosition.x -= reposition_distance_x
			targetPosition.y -= reposition_distance_y
		else:
			targetPosition.x += reposition_distance_x
			targetPosition.y += reposition_distance_y
		current_target_position = targetPosition
			
	# move to the point
	position = position.move_toward(current_target_position, movement_speed * delta)

func move_on_path(delta):
	#get and update the point
	point_on_path.progress_ratio = progress_on_path_precentage
	
	#player's units move forward while enemy units move backwards
	if(team == "player"):
		point_on_path.progress += movement_speed * delta
	else:
		point_on_path.progress -= movement_speed * delta
	
	#update our knight for next frame
	progress_on_path_precentage = point_on_path.progress_ratio

	var target := point_on_path.position
	position = position.move_toward(target, movement_speed * delta)
	
	#play the move animation
	animated_sprite.play("move")
	_update_offset(delta)

func _update_offset(delta):
	# occasionally pick a new random offset
	offset_change_time -= delta
	if offset_change_time <= 0.0:
		target_offset = randf_range(-50, 50)  # random left/right range
		offset_change_time = randf_range(0.5, 2.0)  # how often to change direction

	# smoothly move toward that offset
	side_offset = lerp(side_offset, target_offset, 0.05)

	# apply it to PathFollow2D
	point_on_path.v_offset = side_offset

func update_attack_timer():
	if(can_attack):
		return
	print(can_attack_again_timer)
	can_attack_again_timer -= 1
	if(can_attack_again_timer <= 0):
		can_attack = true

func end_attack():
	is_attacking = false
	can_attack = false
	can_attack_again_timer = attack_cooldown_frames
	attack_animation_played = ""
	# make sure repositioning selects a new target on the next frame
	reposition_timer = reposition_interval-1

# check if the enemy is still in range and init a second swing if so
func check_second_swing():
	#if an enemy is still in range play the second swing, if not just end the attack
	if(should_unit_attack()):
		attack_animation_played = "attack_2"
		animated_sprite.play("attack_2")
	else:
		end_attack()


func _on_animated_sprite_2d_animation_finished() -> void:
	if(attack_animation_played == "attack_1"):
		check_second_swing()
	else: 
		if (attack_animation_played == "attack_2"):
			end_attack()
		else:
			end_attack()
	
