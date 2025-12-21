extends StaticBody2D

signal base_destroyed(team: String)

var team: String = "enemy"
@export var max_health := 1000
var health :int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	health = max_health

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
	queue_free()
