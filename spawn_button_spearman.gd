extends TextureButton

const UNIT_COST = 60

func _ready() -> void:
	# Set button textures
	texture_normal = load("res://assets/ui/buttons/spawn_spearman_regular.png")
	texture_pressed = load("res://assets/ui/buttons/spawn_spearman_pressed.png")
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	ignore_texture_size = true

func _process(delta: float) -> void:
	# Update opacity based on affordability
	if Singleton.game and Singleton.game.player_points >= UNIT_COST:
		modulate.a = 1.0  # Full opacity
	else:
		modulate.a = 0.5  # Semi-transparent

func _on_pressed() -> void:
	# Trigger the spawn_spearman input action
	var event_press = InputEventAction.new()
	event_press.action = "spawn_spearman"
	event_press.pressed = true
	Input.parse_input_event(event_press)
	
	# Send release event immediately
	var event_release = InputEventAction.new()
	event_release.action = "spawn_spearman"
	event_release.pressed = false
	Input.parse_input_event(event_release)
