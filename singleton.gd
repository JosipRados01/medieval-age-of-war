extends Node

var game
var game_ui
var ability_cursor = null
var active_ability_button = null
var current_ability_type = ""
var abilities_enabled = true

const DEATH_SOUND = preload("res://death_sound.tscn")
const ARROW = preload("res://arrow.tscn")
const EXPLOSION = preload("res://explosion.tscn")

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

# Ability system
func ability_activated(ability_button, ability_type: String):
	# Store reference to the button that activated the ability
	active_ability_button = ability_button
	current_ability_type = ability_type
	
	# Show the ability cursor
	if ability_cursor:
		ability_cursor.show_cursor(ability_button)
	
	# Tell the game to start listening for clicks
	if game:
		game.set_ability_mode(true)

func ability_cancelled():
	# Hide the ability cursor
	if ability_cursor:
		ability_cursor.hide_cursor()
	
	# Tell the game to stop listening for ability clicks
	if game:
		game.set_ability_mode(false)
	
	active_ability_button = null
	current_ability_type = ""

func trigger_ability_at_position(position: Vector2):
	# Hide the cursor
	if ability_cursor:
		ability_cursor.hide_cursor()
	
	# Tell the game to stop listening for ability clicks
	if game:
		game.set_ability_mode(false)
	
	# Call the actual ability effect (placeholder for now)
	execute_ability_effect(position)
	
	# Tell the button that the ability was used (triggers cooldown)
	if active_ability_button:
		active_ability_button.use_ability()
	
	active_ability_button = null
	current_ability_type = ""

func execute_ability_effect(position: Vector2):
	if current_ability_type == "arrows":
		# Arrow rain ability: spawn 10 arrows from the sky in a 400px radius
		spawn_arrow_rain(position, 10, 400.0)
	elif current_ability_type == "explosion":
		# Explosion ability: spawn multiple explosions in the area
		spawn_explosions(position, 8, 100.0)

func spawn_arrow_rain(center_position: Vector2, arrow_count: int, radius: float):
	# Spawn arrows with 0.1s delay between each
	for i in range(arrow_count):
		# Calculate random offset position to spawn from (but all land at center)
		var angle = randf() * TAU  # Random angle
		var distance = randf_range(radius * 0.6, radius)  # Random distance from center
		var spawn_offset = Vector2(cos(angle), sin(angle)) * distance
		
		# All arrows land at center, but spawn from different positions around it
		spawn_arrow_from_sky(center_position, spawn_offset)
		
		# Wait 0.05 seconds before spawning the next arrow
		if i < arrow_count - 1:
			await get_tree().create_timer(0.05).timeout

func spawn_arrow_from_sky(target_position: Vector2, spawn_offset: Vector2):
	var arrow = ARROW.instantiate()
	
	# Calculate velocity needed to reach center from offset position
	var fall_time = 0.53  # Approximate time to fall
	var horizontal_velocity = -spawn_offset.x / fall_time  # Velocity to reach center
	
	# Start position: above the target, but offset to the side
	var start_position = target_position
	start_position.y -= 300  # Start 300 pixels above
	start_position.x += spawn_offset.x  # Offset horizontally so arrow comes from the side
	
	arrow.position = start_position
	arrow.team = "player"  # Arrows are on the player's team
	arrow.damage = 30  # Damage per arrow
	arrow.max_y = target_position.y + 100  # Where arrow should stop
	
	# Arrow falls with horizontal velocity pointing toward center
	arrow.velocity = Vector2(horizontal_velocity, 100)
	arrow.gravity = 2000.0  # Gravity pulls it down
	
	# Add to the game scene (let y-sorting handle rendering order naturally)
	if game and game.play_layer:
		game.play_layer.add_child(arrow)

func spawn_explosions(center_position: Vector2, explosion_count: int, radius: float):
	# Spawn explosions with 0.1s delay between each
	for i in range(explosion_count):
		# Calculate random position in the radius
		var angle = randf() * TAU  # Random angle
		var distance = randf_range(0, radius)  # Random distance from center
		var offset = Vector2(cos(angle), sin(angle)) * distance
		
		var explosion_position = center_position + offset
		
		# Spawn explosion
		var explosion = EXPLOSION.instantiate()
		explosion.position = explosion_position
		explosion.team = "player"  # Explosions are on the player's team
		explosion.damage = 50  # Damage per explosion
		
		# Add to the game scene
		if game and game.play_layer:
			game.play_layer.add_child(explosion)
		
		# Wait 0.08 seconds before spawning the next explosion
		if i < explosion_count - 1:
			await get_tree().create_timer(0.08).timeout
