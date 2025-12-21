extends Node

var game
var game_ui

const DEATH_SOUND = preload("res://death_sound.tscn")

func add_points(team:String, unit:String):
	if(team == "player"):
		game.enemy_points += game.get_points_for_unit(unit)
	else:
		game.player_points += game.get_points_for_unit(unit)
	
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
