extends Node2D

@onready var animated_sprite1: AnimatedSprite2D = $AnimatedSprite1
@onready var animated_sprite2: AnimatedSprite2D = $AnimatedSprite2
@onready var enemy_detector: Area2D = $enemyDetector

const ARROW = preload("res://arrow.tscn")

var team = "player"
var damage := 40
var can_attack_again_timer
var is_combat_mode: bool = false
var is_attacking: bool = false
var can_attack: bool = true
var current_archer: int = 1  # Track which archer shoots next
var archer2_delay: int = 0  # Delay counter for second archer
var archer1_finished: bool = true
var archer2_finished: bool = true

func get_attack_cooldown_frames():
	return randi_range(10, 15)

func _ready() -> void:
	animated_sprite1.play("idle")
	animated_sprite2.play("idle")

func _process(delta: float) -> void:
	update_attack_timer()
	update_archer2_delay()
	is_combat_mode = check_combat_mode()
	
	if(is_combat_mode):
		if(is_attacking):
			pass
		else:
			if(can_attack):
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
	var enemies = get_enemies_detected()
	if(enemies.size() > 0):
		return true
	return false

func start_attack_animation():
	is_attacking = true
	archer1_finished = false
	archer2_finished = false
	animated_sprite1.play("shoot")
	archer2_delay = 15  # Start archer 2 after 10 frames

func update_archer2_delay():
	if archer2_delay > 0:
		archer2_delay -= 1
		if archer2_delay == 0 and is_attacking:
			animated_sprite2.play("shoot")

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
	archer1_finished = true
	archer2_finished = true

func _on_animated_sprite_2d_animation_finished() -> void:
	# This will be called by both archers
	if animated_sprite1.animation == "shoot":
		archer1_finished = true
		animated_sprite1.play("idle")
	if animated_sprite2.animation == "shoot":
		archer2_finished = true
		animated_sprite2.play("idle")
	
	# End attack when both archers are done
	if archer1_finished and archer2_finished:
		end_attack()

func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite1.animation == "shoot" and animated_sprite1.frame == 5:
		shoot_arrow($shootLocation1)
	if animated_sprite2.animation == "shoot" and animated_sprite2.frame == 5:
		shoot_arrow($shootLocation2)



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

func shoot_arrow(shoot_location: Marker2D):
	var enemies = get_enemies_detected()
	if enemies.is_empty():
		return

	var target = get_most_progressed_enemy(global_position, enemies)
	var start = shoot_location.global_position
	var end = target.global_position
	end.x -= 20
	
	turn_towards_enemy(end)

	var g = 5000.0
	var extra_height = 10.0

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
	arrow.gravity = g
	arrow.velocity = Vector2(vx, vy)
	arrow.team = team
	arrow.damage = damage
	arrow.max_y = end.y + 20
	get_parent().add_child(arrow)
	%sfx_shoot.play()

func turn_towards_enemy(target):
	if target.x < global_position.x:
		scale.x = -1
	else:
		scale.x = 1

func idle():
	if animated_sprite1.animation != "shoot":
		animated_sprite1.play("idle")
	if animated_sprite2.animation != "shoot":
		animated_sprite2.play("idle")
