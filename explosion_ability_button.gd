extends TextureButton

var ability_active = false
var ability_cooldown = 0.0
const ABILITY_DURATION = 20.0
const ABILITY_TYPE = "explosion"

@onready var countdown_label: Label = $CountdownLabel

func _ready() -> void:
	# Set button textures - using the explosion ability image
	var normal_texture = load("res://assets/ui/buttons/ability_explosion_regular.png")
	var pressed_texture = load("res://assets/ui/buttons/ability_explosion_pressed.png")
	texture_normal = normal_texture
	texture_pressed = pressed_texture
	texture_hover = normal_texture
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	ignore_texture_size = true
	custom_minimum_size = Vector2(200, 200)

func _process(delta: float) -> void:
	# Disable button if abilities are not enabled in this game mode
	if not Singleton.abilities_enabled:
		disabled = true
		modulate.a = 0.3
		return
	
	# Handle cooldown
	if ability_cooldown > 0:
		ability_cooldown -= delta
		countdown_label.text = str(ceil(ability_cooldown))
		modulate.a = 0.5  # Semi-transparent during cooldown
		disabled = true
	else:
		countdown_label.text = ""
		modulate.a = 1.0  # Full opacity when available
		disabled = false

func _on_pressed() -> void:
	if ability_active:
		# Cancel the ability
		cancel_ability()
	else:
		# Activate the ability
		activate_ability()

func activate_ability():
	ability_active = true
	button_pressed = true
	# Notify the game that ability is active
	if Singleton.game:
		Singleton.ability_activated(self, ABILITY_TYPE)

func cancel_ability():
	ability_active = false
	button_pressed = false

	# Notify the game that ability is cancelled
	if Singleton.game:
		Singleton.ability_cancelled()

func use_ability():
	# Called when the ability is actually used/consumed
	ability_active = false
	button_pressed = false
	ability_cooldown = ABILITY_DURATION
