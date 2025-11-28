extends CanvasLayer

@onready var point_label: Label = $Control/MarginContainer/Hbox/Vbox_left/Points/PointLabel
@onready var icons: HBoxContainer = $Control/MarginContainer/Hbox/Vbox_left/icons
@onready var wave_timer_label: Label = $Control/MarginContainer/Hbox/Vbox_right/Wave_timer/Wave_timer_label
const ICON_KNIGHT = preload("res://icon_knight.tscn")
const ICON_ARCHER = preload("res://icon_archer.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Singleton.game_ui = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_points(points:int):
	point_label.text = str(points) + " " + "g"
	pass

func update_icons(units_array):
	# clear old icons
	for child in icons.get_children():
		child.queue_free()
	
	# loop through the player_queue and display an icon for each unit in the queue
	for unit in units_array:
		if unit == "knight":
			var instance = ICON_KNIGHT.instantiate()
			icons.add_child(instance)
		if unit == "archer":
			var instance = ICON_ARCHER.instantiate()
			icons.add_child(instance)
		

func update_wave_timer(frames_left):
	var seconds = frames_left / 60.0
	var m = int(seconds / 60)
	var s = int(seconds) % 60
	var time = "%02d:%02d" % [m, s]
	wave_timer_label.text = time
