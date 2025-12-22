extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var enemy_detector: Area2D = $enemyDetector

const ARROW = preload("res://arrow.tscn")

var team = "player"
var damage := 40
var can_attack_again_timer
var is_combat_mode: bool = false
var is_attacking: bool = false
var can_attack: bool = true
func get_attack_cooldown_frames():
	return randi_range(10, 15)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite.play("idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
		if(is_attacking):
			return
		idle()



func get_enemies_detected():
	var enemies = []
	var overlaping = enemy_detector.get_overlapping_bodies()
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



func start_attack_animation():
	is_attacking = true
	animated_sprite.play("shoot")


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


func _on_animated_sprite_2d_animation_finished() -> void:
	if(is_attacking):
		end_attack()


func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite.animation == "shoot" and animated_sprite.frame == 5:
		shoot_arrow()


func get_most_progressed_enemy(to_position: Vector2, enemies: Array) -> Node2D:
	if enemies.is_empty():
		return null

	var target = enemies[0]
	var target_x = target.position.x

	for e in enemies:
		if target_x < target.position.x:
			target = e
			target_x = target.position.x

	return target


func shoot_arrow():
	var enemies = get_enemies_detected()
	if enemies.is_empty():
		return

	var target = get_most_progressed_enemy(global_position, enemies)
	var start = $shootLocation.global_position
	var end = target.global_position
	#we assume the enemy will move a bit 
	end.x -= 20
	
	turn_towards_enemy(end, animated_sprite)

	# ---- SETTINGS ----
	var g = 5000.0               # gravity
	var extra_height = 100.0     # how high above the higher point the apex should be

	# ---- TRAJECTORY CALCULATION ----
	var dx = end.x - start.x
	var dy = end.y - start.y

	# choose apex height
	var apex_y = min(start.y, end.y) - extra_height

	# vertical velocities
	var vy_up = sqrt(2.0 * g * (start.y - apex_y))
	var vy_down = sqrt(2.0 * g * (end.y - apex_y))

	# times for vertical travel
	var t_up = vy_up / g
	var t_down = vy_down / g
	var total_t = t_up + t_down     # total flight time

	# horizontal velocity needed to land exactly on target
	var vx = dx / total_t

	# pick upward velocity
	var vy = -vy_up

	if end.x < global_position.x:
		vx = -abs(vx)
	else:
		vx = abs(vx)

	# ---- SPAWN ARROW ----
	var arrow = ARROW.instantiate()
	arrow.position = start
	# Only set z_index if target is in front of tower
	if end.y > global_position.y:
		arrow.z_index = 1   # Target in front of tower
		arrow.render_in_front = true
		arrow.render_in_front_until = global_position.y
	arrow.gravity = g
	arrow.velocity = Vector2(vx, vy)
	arrow.team = team
	arrow.damage = damage
	arrow.max_y = end.y + 20
	get_parent().add_child(arrow)
	%sfx_shoot.play()

func turn_towards_enemy(target, archer_sprite: AnimatedSprite2D):
	if target.x < global_position.x:
		archer_sprite.flip_h = true
	else:
		archer_sprite.flip_h = false

func idle():
	animated_sprite.play("idle")
