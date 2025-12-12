extends CanvasLayer

@onready var point_label: Label = $Control/MarginContainer/Hbox/Vbox_left/Points/PointLabel
@onready var icons: FlowContainer = $Control/MarginContainer/Hbox/Vbox_left/icons
@onready var wave_timer_label: Label = $Control/MarginContainer/Hbox/Vbox_right/Wave_timer/Wave_timer_label
const ICON_KNIGHT = preload("res://icon_knight.tscn")
const ICON_ARCHER = preload("res://icon_archer.tscn")
const ICON_SPEARMAN = preload("res://icon_spearman.tscn")
const ICON_HEALER = preload("res://icon_healer.tscn")

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
		if unit == "spearman":
			var instance = ICON_SPEARMAN.instantiate()
			icons.add_child(instance)
		if unit == "healer":
			var instance = ICON_HEALER.instantiate()
			icons.add_child(instance)
		

func update_wave_timer(timer: Timer):
	var time_left: float = timer.time_left
	var m = int(time_left)
	var time = "%02d" % [m]
	time += " s"
	wave_timer_label.text = time
