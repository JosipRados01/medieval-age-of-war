
extends Node2D

var animated_sprite: AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var friend_detector: Area2D = $FriendDetector
@onready var friends_in_front: Area2D = $FriendDetector/FriendsInFront
@onready var point_on_path : PathFollow2D = $"../../Path/point_on_path"
@onready var death_particles: CPUParticles2D = $DeathParticles

const HEAL_EFFECT = preload("res://heal_effect.tscn")
const HEAL_AMMOUNT = 20

@export var health := 100
const max_health := 100
var can_heal_again_timer
var movement_speed := 150
# "player" | "enemy"
@export var team := "player"
# how many points the unit is worth on death
var points = 120

var is_friends_detected: bool = false
var is_healing: bool = false
var is_idling: bool = false
var can_heal: bool = true
func get_heal_cooldown_frames():
	return randi_range(200, 400)


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
	var range_scale_factor = randf_range(0.9, 1.1)
	friend_detector.scale = Vector2(range_scale_factor, range_scale_factor)


# Called every frame. 'delta' is the elapsed time since the previous frame.
## The healer moves along the path and tries to be a part of a unit and have units in frnt of himself
## He will move along the path quicky if no friends are detected. 
## When friends are detected he will keep running if friends are in front and idle if friends are not in front
## When friends are detected and he can heal he heals of course
## MAYBE Experiment with making some of them wait if no friends are detected instead of trying to catch up
func _process(delta: float) -> void:
	#always update attack timer
	update_heal_timer()
	
	if(is_healing or is_idling):
		return
	is_friends_detected = check_friends_detected()
	if(is_friends_detected):
		if(can_heal and check_wounded_friends()):
			# init attack animation
			start_heal_animation()
		else:
			# check if friends are in front to idle or keep running
			if(check_friends_in_front()):
				move_on_path(delta)
			else:
				idle()
	else:
		#continue following the path
		move_on_path(delta)

func get_friends_detected():
	var friends = []
	var overlaping = friend_detector.get_overlapping_bodies()
	for unit in overlaping:
		if unit == self:
			continue
		if (unit.has_method("_get_team")):
			var unit_team = unit._get_team()
			if team == unit_team:
				friends.append(unit)
	return friends

func get_wounded_friends():
	var friends = get_friends_detected()
	var wounded = []
	for friend in friends:
		if friend.health < friend.max_health:
			wounded.append(friend)
	return wounded

func check_wounded_friends():
	var friends = get_friends_detected()
	for friend in friends:
		if friend.health < friend.max_health:
			return true
	return false

func check_friends_detected() -> bool:
	# the unit should engage combat mode if the EnemyDetector area has enemies in the enemy team
	var friends = get_friends_detected()
	return friends.size() > 0

func check_friends_in_front() -> bool:
	var overlaping = friends_in_front.get_overlapping_bodies()
	for unit in overlaping:
		if unit == self:
			continue
		if (unit.has_method("_get_team")):
			var unit_team = unit._get_team()
			if team == unit_team:
				return true
	return false

func _get_team():
	return team

func start_heal_animation():
	is_healing = true
	## TODO: need to have what friends should be healed and spawn the heal effects
	heal_friends()
	animated_sprite.play("heal")

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

func update_heal_timer():
	if(can_heal):
		return
	can_heal_again_timer -= 1
	if(can_heal_again_timer <= 0):
		can_heal = true

func end_heal():
	is_healing = false
	can_heal = false
	can_heal_again_timer = get_heal_cooldown_frames()

func take_damage(damage:int):
	health -= damage
	
	if(health <= 0):
		die()


func die():
	Singleton.add_points(team, points)
	death_particles.reparent(get_parent())
	death_particles.emitting = true
	death_particles.connect("finished", Callable(self, "_on_death_particles_finished"))
	Singleton.play_death_sound(position)
	queue_free()

func _on_death_particles_finished():
	death_particles.queue_free()

func _on_animated_sprite_2d_animation_finished() -> void:
	if(is_healing):
		end_heal()

func get_closest_friend(to_position: Vector2, friends: Array) -> Node2D:
	if friends.is_empty():
		return null

	var closest = friends[0]
	var closest_dist = to_position.distance_to(closest.position)

	for f in friends:
		var d = to_position.distance_to(f.position)
		if d < closest_dist:
			closest = f
			closest_dist = d

	return closest

## TODO: Add max health to units and only heal injured units up to max health
func heal_friends():
	# get friends
	var friends = get_wounded_friends()
	# spawn the healing effect on their location
	for friend in friends:
		var healEffect = HEAL_EFFECT.instantiate()
		healEffect.position = friend.position
		healEffect.position.y += 20
		get_parent().add_child(healEffect)
		healEffect.heal()
		#increase their by heal ammount
		friend.health += HEAL_AMMOUNT
	

func idle():
	animated_sprite.play("idle")
	is_idling = true
	await get_tree().create_timer(1.0).timeout
	is_idling = false
