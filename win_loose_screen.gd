extends Control

@onready var win: Label = $HBoxContainer/VBoxContainer/Control/TextureRect/Win
@onready var loose: Label = $HBoxContainer/VBoxContainer/Control/TextureRect/Loose


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func win_display():
	win.visible = true
	loose.visible = false


func loose_display():
	win.visible = false
	loose.visible = true


func _on_red_kingdom_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://map1.tscn")


func _on_forest_creatures_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://castle_level.tscn")


func _on_tutorial_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu.tscn")
