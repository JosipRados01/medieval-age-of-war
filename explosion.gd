extends Node2D

var team = "player"
var damage = 30



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Disable the area initially
	$Area2D.monitoring = false
	
	# Randomly choose one sprite to show
	if randf() < 0.5:
		$AnimatedSprite2D.visible = true
		$AnimatedSprite2D2.visible = false
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.connect("frame_changed", _on_animated_sprite_2d_frame_changed)
		$AnimatedSprite2D.connect("animation_finished", _on_animation_finished)
	else:
		$AnimatedSprite2D.visible = false
		$AnimatedSprite2D2.visible = true
		$AnimatedSprite2D2.play()
		$AnimatedSprite2D2.connect("frame_changed", _on_animated_sprite_2d_frame_changed)
		$AnimatedSprite2D2.connect("animation_finished", _on_animation_finished)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_area_entered(area: Area2D) -> void:
	# check if the area that entered is a hitbox
	if area.name == "Hitbox":
		var parent = area.get_parent()
		if(parent.has_method("_get_team")):
			var target_team = parent._get_team()
			if(target_team != team and parent.has_method("take_damage")):
				parent.take_damage(damage)
				queue_free()


func _on_animated_sprite_2d_frame_changed() -> void:
	var active_sprite = $AnimatedSprite2D if $AnimatedSprite2D.visible else $AnimatedSprite2D2
	if active_sprite.frame == 2:
		$Area2D.monitoring = true
	else:
		$Area2D.monitoring = false


func _on_animation_finished() -> void:
	queue_free()
