extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hitbox_area: Area2D = $Hitbox
@onready var hurtbox: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var hurtbox_area: Area2D = $Hurtbox
@onready var poison_area: Area2D = $poisonArea
@onready var enemyDetector: Area2D = $EnemyDetector
@onready var enemy_in_range: Area2D = $Enemy_in_range
@onready var point_on_path : PathFollow2D = $"../../Path/point_on_path"
@onready var death_particles: CPUParticles2D = $DeathParticles

@export var health := 180
const max_health = 180
var damage := 30
var can_attack_again_timer
var movement_speed := 200
# "player" | "enemy"
@export var team := "enemy"

var is_combat_mode: bool = false
var is_attacking: bool = false
var can_attack: bool = true
var attack_cooldown_frames = 30

@export var progress_on_path_precentage:float 
var progress_on_path_pixels := 0.0

# offset variables so that we don't follow the path exactly
var side_offset := 0.0
var target_offset := 0.0
@onready var offset_change_time := 0.0

## knockback variables
var is_knocked_back = false
var knockback_velocity = Vector2.ZERO
var knockback_duration = 0.0

## hit flash
var hit_flash = false
var hit_flash_frames = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if team == "enemy":
		progress_on_path_precentage = 0.99
		scale.x = -1

	point_on_path.progress_ratio = progress_on_path_precentage
	position = point_on_path.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# handle hit flash countdown
	if hit_flash_frames > 0:
		hit_flash_frames -= 1
		if hit_flash_frames == 0:
			animated_sprite.modulate = Color(1.0, 1.0, 1.0)
	
	#always update attack timer
	update_attack_timer()
	
	# handle knockback
	if is_knocked_back:
		_process_knockback(delta)
		return
	
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
		#THIS MAY CAUSE IT TO GET STUCK IF HE KILLS ALL ENEMIES
		if(is_attacking):
			pass
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
	animated_sprite.play("attack")
	
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
	var reposition_distance_y = randf_range(-50.0, 50.0)

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
	
	# Apply collision avoidance - push away from overlapping units
	var separation_force = _calculate_separation_force()
	target += separation_force
	
	position = position.move_toward(target, movement_speed * delta)
	
	#play the move animation
	animated_sprite.play("move")
	_update_offset(delta)

func _calculate_separation_force() -> Vector2:
	# Get all overlapping bodies in the hitbox
	var overlapping_bodies = hitbox_area.get_overlapping_bodies()
	if overlapping_bodies.size() == 0:
		return Vector2.ZERO
	
	var separation = Vector2.ZERO
	var neighbor_count = 0
	
	for body in overlapping_bodies:
		# Skip self
		if body == self:
			continue
			
		# Calculate direction away from this neighbor
		var distance_vec = position - body.position
		var distance = distance_vec.length()
		
		# Only apply separation if very close (to avoid constant pushing)
		if distance > 0 and distance < 60:  # adjust threshold as needed
			# Closer neighbors have stronger influence
			var push_strength = (60 - distance) / 60.0
			separation += distance_vec.normalized() * push_strength
			neighbor_count += 1
	
	# Average the separation force
	if neighbor_count > 0:
		separation = separation / neighbor_count
		# Scale the separation force (adjust multiplier as needed)
		separation *= 40.0
	
	return separation

func _update_offset(delta):
	# occasionally pick a new random offset
	offset_change_time -= delta
	if offset_change_time <= 0.0:
		target_offset = randf_range(-70, 70)  # random left/right range
		offset_change_time = randf_range(0.5, 1.0)  # how often to change direction

	# smoothly move toward that offset
	side_offset = lerp(side_offset, target_offset, 0.1)

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
	_apply_knockback()
	animated_sprite.modulate = Color(3.0, 3.0, 3.0)
	hit_flash_frames = 5
	
	if(health <= 0):
		die()


func die():
	Singleton.add_points(team, "spider")
	death_particles.reparent(get_parent())
	death_particles.emitting = true
	death_particles.connect("finished", Callable(self, "_on_death_particles_finished"))
	Singleton.play_death_sound(position)
	
	# spiders have acid blood that hurts the units one last time
	var overlapping_areas = poison_area.get_overlapping_areas()
	for area in overlapping_areas:
		if area.name == "Hitbox":
			var enemy = area.get_parent()
			if enemy.has_method("_get_team"):
				var enemy_team = enemy._get_team()
				if enemy_team != team and enemy.has_method("get_poisoned"):
					enemy.get_poisoned()
	
	queue_free()

func _on_death_particles_finished():
	death_particles.queue_free()

func _on_animated_sprite_2d_animation_finished() -> void:
	if(is_attacking):
		end_attack()


func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite.animation == "attack" :
		hurtbox.disabled = animated_sprite.frame != 4
		if(animated_sprite.frame == 4):
			%sfx_attack.play()
	else:
		hurtbox.disabled = true


func _on_hurtbox_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	# check if the area that entered is a hitbox
	if area.name == "Hitbox":
		var parent = area.get_parent()
		if(parent.has_method("_get_team")):
			var target_team = parent._get_team()
			if(target_team != team and parent.has_method("take_damage")):
				parent.take_damage(damage)
				if parent.has_method("get_poisoned"):
					parent.get_poisoned()

func _apply_knockback():
	var knockback_direction = -1 if team == "player" else 1
	var knockback_strength = 120.0
	var y_randomness = randf_range(-30, 30)
	knockback_velocity = Vector2(knockback_direction * knockback_strength, y_randomness)
	knockback_duration = 0.2
	is_knocked_back = true

func _process_knockback(delta):
	knockback_duration -= delta
	if knockback_duration <= 0:
		is_knocked_back = false
		knockback_velocity = Vector2.ZERO
		return
	
	position += knockback_velocity * delta
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 5.0 * delta)
