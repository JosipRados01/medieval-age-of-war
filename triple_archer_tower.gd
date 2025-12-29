extends Node2D

@onready var animated_sprite1: AnimatedSprite2D = $AnimatedSprite1
@onready var animated_sprite2: AnimatedSprite2D = $AnimatedSprite2
@onready var animated_sprite3: AnimatedSprite2D = $AnimatedSprite3
@onready var enemy_detector_1: Area2D = $AnimatedSprite1/enemyDetector1
@onready var enemy_detector_2: Area2D = $AnimatedSprite2/enemyDetector2
@onready var enemy_detector_3: Area2D = $AnimatedSprite3/enemyDetector3

const ARROW = preload("res://arrow.tscn")

var team = "player"
var damage := 40

# Archer 1 state
var archer1_is_attacking := false
var archer1_can_attack := true
var archer1_attack_timer := 0
var archer1_has_shot := false

# Archer 2 state
var archer2_is_attacking := false
var archer2_can_attack := true
var archer2_attack_timer := 0
var archer2_has_shot := false

# Archer 3 state
var archer3_is_attacking := false
var archer3_can_attack := true
var archer3_attack_timer := 0
var archer3_has_shot := false

func _ready() -> void:
	animated_sprite1.play("idle")
	animated_sprite2.play("idle")
	animated_sprite3.play("idle")

func _process(delta: float) -> void:
	process_archer1()
	process_archer2()
	process_archer3()

func process_archer1():
	update_archer_timer(1)
	var has_enemies = get_enemies_detected(enemy_detector_1).size() > 0
	
	if has_enemies:
		if not archer1_is_attacking and archer1_can_attack:
			archer1_is_attacking = true
			archer1_has_shot = false
			animated_sprite1.play("shoot")
		elif not archer1_is_attacking:
			animated_sprite1.play("idle")
	else:
		if not archer1_is_attacking:
			animated_sprite1.play("idle")

func process_archer2():
	update_archer_timer(2)
	var has_enemies = get_enemies_detected(enemy_detector_2).size() > 0
	
	if has_enemies:
		if not archer2_is_attacking and archer2_can_attack:
			archer2_is_attacking = true
			archer2_has_shot = false
			animated_sprite2.play("shoot")
		elif not archer2_is_attacking:
			animated_sprite2.play("idle")
	else:
		if not archer2_is_attacking:
			animated_sprite2.play("idle")

func process_archer3():
	update_archer_timer(3)
	var has_enemies = get_enemies_detected(enemy_detector_3).size() > 0
	
	if has_enemies:
		if not archer3_is_attacking and archer3_can_attack:
			archer3_is_attacking = true
			archer3_has_shot = false
			animated_sprite3.play("shoot")
		elif not archer3_is_attacking:
			animated_sprite3.play("idle")
	else:
		if not archer3_is_attacking:
			animated_sprite3.play("idle")

func update_archer_timer(archer_num: int):
	if archer_num == 1:
		if not archer1_can_attack:
			archer1_attack_timer -= 1
			if archer1_attack_timer <= 0:
				archer1_can_attack = true
	elif archer_num == 2:
		if not archer2_can_attack:
			archer2_attack_timer -= 1
			if archer2_attack_timer <= 0:
				archer2_can_attack = true
	elif archer_num == 3:
		if not archer3_can_attack:
			archer3_attack_timer -= 1
			if archer3_attack_timer <= 0:
				archer3_can_attack = true

func _on_animated_sprite_2d_animation_finished() -> void:
	# This is the old generic callback - we'll use specific ones below
	pass

func _on_archer1_animation_finished() -> void:
	if animated_sprite1.animation == "shoot":
		animated_sprite1.play("idle")
		archer1_is_attacking = false
		archer1_can_attack = false
		archer1_attack_timer = randi_range(8, 18)

func _on_archer2_animation_finished() -> void:
	if animated_sprite2.animation == "shoot":
		animated_sprite2.play("idle")
		archer2_is_attacking = false
		archer2_can_attack = false
		archer2_attack_timer = randi_range(8, 18)

func _on_archer3_animation_finished() -> void:
	if animated_sprite3.animation == "shoot":
		animated_sprite3.play("idle")
		archer3_is_attacking = false
		archer3_can_attack = false
		archer3_attack_timer = randi_range(8, 18)

func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite1.animation == "shoot" and animated_sprite1.frame == 5 and not archer1_has_shot:
		archer1_has_shot = true
		shoot_arrow($AnimatedSprite1/shootLocation1, enemy_detector_1, animated_sprite1)
	if animated_sprite2.animation == "shoot" and animated_sprite2.frame == 5 and not archer2_has_shot:
		archer2_has_shot = true
		shoot_arrow($AnimatedSprite2/shootLocation2, enemy_detector_2, animated_sprite2)
	if animated_sprite3.animation == "shoot" and animated_sprite3.frame == 5 and not archer3_has_shot:
		archer3_has_shot = true
		shoot_arrow($AnimatedSprite3/shootLocation3, enemy_detector_3, animated_sprite3)

func get_enemies_detected(detector: Area2D):
	var enemies = []
	var overlaping = detector.get_overlapping_bodies()
	for enemy in overlaping:
		if (enemy.has_method("_get_team")):
			var enemy_team = enemy._get_team()
			if team != enemy_team:
				enemies.append(enemy)
	return enemies

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

func shoot_arrow(shoot_location: Marker2D, detector: Area2D, archer_sprite: AnimatedSprite2D):
	var enemies = get_enemies_detected(detector)
	if enemies.is_empty():
		return

	var target = get_most_progressed_enemy(global_position, enemies)
	var start = shoot_location.global_position
	var end = target.global_position
	end.x -= 25
	
	turn_towards_enemy(end, archer_sprite)

	var g = 5000.0
	var extra_height = 100.0

	var dx = end.x - start.x
	var dy = end.y - start.y

	var apex_y = min(start.y, end.y) - extra_height

	var vy_up = sqrt(2.0 * g * (start.y - apex_y))
	var vy_down = sqrt(2.0 * g * (end.y - apex_y))

	var t_up = vy_up / g
	var t_down = vy_down / g
	var total_t = t_up + t_down

	var vx = dx / total_t
	var vy = -vy_up

	if end.x < global_position.x:
		vx = -abs(vx)
	else:
		vx = abs(vx)

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
