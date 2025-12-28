extends TextureButton

func _ready() -> void:
	# Set button textures
	texture_normal = load("res://assets/ui/buttons/spawn_archer_regular.png")
	texture_pressed = load("res://assets/ui/buttons/spawn_archer_pressed.png")
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	ignore_texture_size = true

func _on_pressed() -> void:
	# Trigger the spawn_archer input action
	var event_press = InputEventAction.new()
	event_press.action = "spawn_archer"
	event_press.pressed = true
	Input.parse_input_event(event_press)
	
	# Send release event immediately
	var event_release = InputEventAction.new()
	event_release.action = "spawn_archer"
	event_release.pressed = false
	Input.parse_input_event(event_release)
