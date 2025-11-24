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
var team := "player"

var is_combat_mode: bool = false
var is_attacking: bool = false
var can_attack: bool = true

@export var progress_on_path_precentage:float 
var progress_on_path_pixels := 0.0

# offset variables so that we don't follow the path exactly
var side_offset := 0.0
var target_offset := 0.0
@onready var offset_change_time := 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#spawn on the correct position on the path
	point_on_path.progress_ratio = progress_on_path_precentage
	position = point_on_path.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
				reposition()
	else:
		#continue following the path
		move_on_path(delta)


func check_combat_mode() -> bool:
	return false

func should_unit_attack() -> bool:
	return false
	
func start_attack_animation():
	pass
	
func reposition():
	pass
	
func move_on_path(delta):
	#print()
	#get and update the point
	point_on_path.progress_ratio = progress_on_path_precentag
	point_on_path.progress += movement_speed * delta
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


# check if the enemy is still in range and init a second swing if so
func check_second_swing():
	pass
