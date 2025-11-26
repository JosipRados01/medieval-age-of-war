extends Node

var game


func add_points(team:String, points:int):
	if(team == "player"):
		game.player_points += points
	else:
		game.enemy_points += points
