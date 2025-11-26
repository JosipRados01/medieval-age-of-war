extends Node

var game
var game_ui


func add_points(team:String, points:int):
	if(team == "player"):
		game.player_points += points
	else:
		game.enemy_points += points
	
	game_ui.update_points(game.player_points)


func update_points():
	game_ui.update_points(game.player_points)

func update_icons(units):
	game_ui.update_icons(units)

func update_wave_timer(frames_left):
	game_ui.update_wave_timer(frames_left)
