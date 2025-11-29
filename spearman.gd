extends Node2D

var animated_sprite: AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hurtbox_side: CollisionShape2D = $Hurtbox_side/CollisionShape2D
@onready var hurtbox_up_side: CollisionShape2D = $Hurtbox_up_side/CollisionShape2D
@onready var hurtbox_down_side: CollisionShape2D = $Hurtbox_down_side/CollisionShape2D
@onready var enemyDetector: Area2D = $EnemyDetector
@onready var enemy_in_range_side: Area2D = $Enemy_in_range_side
@onready var enemy_in_range_up_side: Area2D = $Enemy_in_range_up_side
@onready var enemy_in_range_down_side: Area2D = $Enemy_in_range_down_side
@onready var point_on_path : PathFollow2D = $"../../Path/point_on_path"
@onready var death_particles: CPUParticles2D = $DeathParticles

@export var health := 150
var damage := 50
var can_attack_again_timer
var movement_speed := 200
# "player" | "enemy"
@export var team := "player"
# how many points the unit is worth on death
var points = 50

var is_combat_mode: bool = false
var is_attacking: bool = false
var can_attack: bool = true
var attack_cooldown_frames = 20

@export var progress_on_path_precentage:float 
var progress_on_path_pixels := 0.0

# offset variables so that we don't follow the path exactly
var side_offset := 0.0
var target_offset := 0.0
@onready var offset_change_time := 0.0

# repositioning preference for spearman
var repositioning_preference := "side"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if team == "enemy":
		progress_on_path_precentage = 0.99
		animated_sprite = $EnemyAnimatedSprite2D
		$AnimatedSprite2D.queue_free()
	else:
		animated_sprite = $AnimatedSprite2D
		$EnemyAnimatedSprite2D.queue_free()

	point_on_path.progress_ratio = progress_on_path_precentage
	position = point_on_path.position

	if team == "enemy":
		scale.x = -1
	
	# choose a random preference for attack side
	repositioning_preference = ["side", "down", "up"].pick_random()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	#always update attack timer
	update_attack_timer()
	
	is_combat_mode = check_combat_mode()
	# The unit can either be in combat or moving
	if(is_combat_mode):
		# if attacking do nothing
		if(is_attacking):
			pass
		else:
			#check for nearby enemies and if an enemy is close enough attack
			if(can_attack and should_unit_attack()):
				# init attack animation
				start_attack_animation()
			else:
				#reposition according to enemy. Ideal position for knight is in front of the enemy and in range for attack
				reposition(delta)
	else:
		#TODO: add a check for is attacking and skip the moving if so
		# reset the variables to make sure that we don't get stuck
		is_attacking = false
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
	var overlaping = enemy_in_range_side.get_overlapping_bodies()
	overlaping.append_array(enemy_in_range_up_side.get_overlapping_bodies())
	overlaping.append_array(enemy_in_range_down_side.get_overlapping_bodies())
	for enemy in overlaping:
		if (enemy.has_method("_get_team")):
			var enemy_team = enemy._get_team()
			if team != enemy_team:
				return true
	return false

func _get_team():
	return team

func are_enemies_in_array(array):
	for enemy in array:
		if (enemy.has_method("_get_team")):
			var enemy_team = enemy._get_team()
			if team != enemy_team:
				return true
	return false

func start_attack_animation():
	is_attacking = true
	if(are_enemies_in_array(enemy_in_range_side.get_overlapping_bodies())):
		animated_sprite.play("attack_side")
	elif(are_enemies_in_array(enemy_in_range_up_side.get_overlapping_bodies())):
		animated_sprite.play("attack_up_side")
	else:
		animated_sprite.play("attack_down_side")
	
func reposition(delta):
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
	
	
	# if not find a point in front of the enemy to move towards
	var targetPosition = chosen_enemy.position
	var reposition_distance_x = 70 
	var reposition_distance_y = 0
	
	if repositioning_preference == "up":
		reposition_distance_y = 40
	elif repositioning_preference == "down":
		reposition_distance_y = -40

	if(team == "player"):
		targetPosition.x -= reposition_distance_x
		targetPosition.y -= reposition_distance_y
	else:
		targetPosition.x += reposition_distance_x
		targetPosition.y += reposition_distance_y
	# move to the point
	position = position.move_toward(targetPosition, movement_speed * delta)

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
	can_attack_again_timer -= 1
	if(can_attack_again_timer <= 0):
		can_attack = true

func end_attack():
	is_attacking = false
	can_attack = false
	can_attack_again_timer = attack_cooldown_frames
	animated_sprite.play("move")


func take_damage(damage:int):
	health -= damage
	
	if(health <= 0):
		die()


func die():
	Singleton.add_points(team, points)
	death_particles.reparent(get_parent())
	death_particles.emitting = true
	death_particles.connect("finished", Callable(self, "_on_death_particles_finished"))
	queue_free()

func _on_death_particles_finished():
	death_particles.queue_free()

func _on_animated_sprite_2d_animation_finished() -> void:
	if(is_attacking):
		end_attack()


func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite.animation == "attack_side" :
		hurtbox_side.disabled = animated_sprite.frame != 1
	elif animated_sprite.animation == "attack_up_side" :
		hurtbox_up_side.disabled = animated_sprite.frame != 1
	elif animated_sprite.animation == "attack_down_side":
		hurtbox_down_side.disabled = animated_sprite.frame != 1
	else:
		hurtbox_side.disabled = true
		hurtbox_up_side.disabled = true
		hurtbox_down_side.disabled = true


func _on_hurtbox_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	# check if the area that entered is a hitbox
	if area.name == "Hitbox":
		var parent = area.get_parent()
		if(parent.has_method("_get_team")):
			var target_team = parent._get_team()
			if(target_team != team and parent.has_method("take_damage")):
				parent.take_damage(damage)
