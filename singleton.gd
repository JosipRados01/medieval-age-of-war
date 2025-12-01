extends Node

var game
var game_ui

const DEATH_SOUND = preload("res://death_sound.tscn")

func add_points(team:String, points:int):
	if(team == "player"):
		game.enemy_points += points
	else:
		game.player_points += points
	
	game_ui.update_points(game.player_points)


func update_points():
	game_ui.update_points(game.player_points)

func update_icons(units):
	game_ui.update_icons(units)

func update_wave_timer(timer):
	game_ui.update_wave_timer(timer)

func play_death_sound(position):
	var instance = DEATH_SOUND.instantiate()
	instance.position = position
	get_tree().current_scene.add_child(instance)
	instance.play()
