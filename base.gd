extends Node2D


var team: String = "player"
var health := 1000
var maxHealth := 1000
var invisibleBase = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if invisibleBase:
		$EnemyBase.visible = false
		$PlayerBase.visible = false
	else:
		if team == "player":
			$EnemyBase.visible = false
			$PlayerBase.visible = true
		else:
			$EnemyBase.visible = true
			$PlayerBase.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _get_team():
	return team


func take_damage(damage:int):
	health -= damage
	
	if(health <= 0):
		die()


func die():
	pass
