extends Node2D

@onready var sfx_death: AudioStreamPlayer2D = $sfx_death


func _ready():
	await get_tree().create_timer(3.0).timeout
	queue_free()

func play():
	sfx_death.play()
