extends Node2D

# set by shooter
var velocity = Vector2()
var gravity 
var team 
var damage
var max_y # when arrow reaches this y it will stop and get stabbed into the ground
var stabbed := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if stabbed:
		return
	# apply gravity and move the arrow
	velocity.y += gravity * delta
	# move
	position += velocity * delta
	# optional: rotate arrow to face its movement
	if velocity.length() > 0:
		rotation = velocity.angle()
	
	if velocity.y > 0 and position.y > max_y:
		#stab the arrow into the ground
		stabbed = true
		$HurtBox/CollisionShape2D.disabled = true
		$ArrowStuck.visible = true
		$Arrow.visible = false
		# wait 5 seconds, then remove arrow
		await get_tree().create_timer(5.0).timeout
		queue_free()
		

func _on_hurt_box_area_entered(area: Area2D) -> void:
	# check if the area that entered is a hitbox
	if area.name == "Hitbox":
		var parent = area.get_parent()
		if(parent.has_method("_get_team")):
			var target_team = parent._get_team()
			if(target_team != team and parent.has_method("take_damage")):
				parent.take_damage(damage)
				queue_free()
