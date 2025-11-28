extends Node2D

var animated_sprite: AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var enemyDetector: Area2D = $EnemyDetector
@onready var point_on_path : PathFollow2D = $"../../Path/point_on_path"
@onready var death_particles: CPUParticles2D = $DeathParticles

const ARROW = preload("res://arrow.tscn")
@export var health := 100
var damage := 40
var can_attack_again_timer
var movement_speed := 100
# "player" | "enemy"
@export var team := "player"
# how many points the unit is worth on death
var points = 50

var is_combat_mode: bool = false
var is_attacking: bool = false
var can_attack: bool = true
func get_attack_cooldown_frames():
	return randi_range(20, 80)


@export var progress_on_path_precentage:float 
var progress_on_path_pixels := 0.0

# offset variables so that we don't follow the path exactly
var side_offset := 0.0
var target_offset := 0.0
@onready var offset_change_time := 0.0


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
	
	# change the range randomly per archer to avoid full clustering
	var range_scale_factor = randf_range(0.8, 1.2)
	enemyDetector.scale = Vector2(range_scale_factor, range_scale_factor)


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
			if(can_attack):
				# init attack animation
				start_attack_animation()
			else:
				idle()
	else:
		#continue following the path
		is_attacking = false
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

func _get_team():
	return team

func start_attack_animation():
	is_attacking = true
	animated_sprite.play("shoot")

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
	can_attack_again_timer = get_attack_cooldown_frames()

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
	if animated_sprite.animation == "shoot" and animated_sprite.frame == 5:
		shoot_arrow()


func get_closest_enemy(to_position: Vector2, enemies: Array) -> Node2D:
	if enemies.is_empty():
		return null

	var closest = enemies[0]
	var closest_dist = to_position.distance_to(closest.position)

	for e in enemies:
		var d = to_position.distance_to(e.position)
		if d < closest_dist:
			closest = e
			closest_dist = d

	return closest


func shoot_arrow():
	# get target enemy
	var enemies = get_enemies_detected()
	if enemies.size() == 0:
		return
	
	var target_enemy = get_closest_enemy(global_position, enemies)

	
	# calculate initial velocity for arrow
	var start = global_position
	var end = target_enemy.global_position
	#
	#var m = ColorRect.new()
	#m.position = Vector2(end)     # where you want it
	#m.size = Vector2(10, 10)      # 10x10
	#m.color = Color.WHITE         # white
	#get_parent().add_child(m)
	#
	var g = 5000.0
	var vx = 1000.0
	
	var dx = end.x - start.x
	var dy = end.y - start.y
	
	print("target: ", dx,", ", dy)
	
	# decrease dx by dy
	dx -= dy
	
	var t = abs(dx)/ vx
	
	var vy = -(g * (t/2)) - 200
	
	var max_y = end.y + 20
	# spawn the arrow
	var arrow = ARROW.instantiate()
	arrow.position = start
	arrow.gravity = g
	print("speed" ,Vector2(vx, vy))
	arrow.velocity = Vector2(vx, vy)
	arrow.team = team
	arrow.damage = damage
	arrow.max_y = max_y
	get_parent().add_child(arrow)

func idle():
	animated_sprite.play("idle")
