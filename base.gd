extends StaticBody2D

signal base_destroyed(team: String)

@export var team: String = "player"
@export var max_health := 1000
var health :int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	health = max_health
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
	base_destroyed.emit(team)
	$EnemyBase.visible = false
	$PlayerBase.visible = false
	$CastleDestroyed.visible = true
