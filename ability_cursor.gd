extends Sprite2D

var active_ability_button = null

func _ready() -> void:
	# Load the cursor texture
	texture = load("res://assets/ui/ability cursor.png")
	# Make it follow the mouse
	set_process(true)
	# Initially hidden
	visible = false
	# Set Z index to render on top
	z_index = 100

func _process(_delta: float) -> void:
	if visible:
		# Follow mouse position
		global_position = get_global_mouse_position()

func show_cursor(ability_button) -> void:
	active_ability_button = ability_button
	visible = true

func hide_cursor() -> void:
	active_ability_button = null
	visible = false

func get_active_button():
	return active_ability_button
