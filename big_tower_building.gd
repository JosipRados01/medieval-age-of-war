extends Node2D

const TRIPLE_ARCHER_TOWER = preload("res://triple_archer_tower.tscn")
const QUAD_ARCHER_TOWER = preload("res://quad_archer_tower.tscn")

@onready var tower_construction: Sprite2D = $CastleConstruction
@onready var label: Label = $Label
@onready var area_construction: Area2D = $AreaConstruction
@onready var area_tower: Area2D = $AreaTower
var current_archer_tower = null
var state = "not_built"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_tower.visible = false
	area_tower.monitoring = false
	area_tower.monitorable = false
	label.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Safety check for game instance
	if not Singleton.game:
		return
	
	# Manual check to ensure label state is correct
	var mouse_pos = get_global_mouse_position()
	var is_hovering = false
	
	if state == "not_built" and area_construction.monitoring:
		is_hovering = _is_point_in_area(mouse_pos, area_construction)
	elif state == "level_1" and area_tower.monitoring:
		is_hovering = _is_point_in_area(mouse_pos, area_tower)
	
	# Update label visibility based on hover state
	if is_hovering and not label.visible:
		if state == "not_built":
			var cost = Singleton.game.tower_cost["triple_archer_tower"]
			if Singleton.game.can_afford_tower("triple_archer_tower"):
				label.text = "Build: " + str(cost) + "g"
			else:
				label.text = "Build: " + str(cost) + "g (Not enough!)"
		elif state == "level_1":
			var cost = Singleton.game.tower_cost["quad_archer_tower"]
			if Singleton.game.can_afford_tower("quad_archer_tower"):
				label.text = "Upgrade: " + str(cost) + "g"
			else:
				label.text = "Upgrade: " + str(cost) + "g (Not enough!)"
		label.visible = true
	elif not is_hovering and label.visible and state != "level_2":
		label.visible = false


func _is_point_in_area(point: Vector2, area: Area2D) -> bool:
	for child in area.get_children():
		if child is CollisionShape2D:
			var shape = child.shape
			var shape_pos = area.global_position + child.position
			
			if shape is CircleShape2D:
				return point.distance_to(shape_pos) <= shape.radius
			elif shape is RectangleShape2D:
				var rect = Rect2(shape_pos - shape.size / 2, shape.size)
				return rect.has_point(point)
			elif shape is CapsuleShape2D:
				# Simplified capsule check
				var half_height = (shape.height - shape.radius * 2) / 2
				var top = shape_pos + Vector2(0, -half_height)
				var bottom = shape_pos + Vector2(0, half_height)
				var dist_to_line = _point_to_line_distance(point, top, bottom)
				return dist_to_line <= shape.radius
	return false


func _point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len = line_vec.length()
	if line_len == 0:
		return point_vec.length()
	var t = clamp(point_vec.dot(line_vec) / (line_len * line_len), 0.0, 1.0)
	var projection = line_start + t * line_vec
	return point.distance_to(projection)


func _input(event: InputEvent) -> void:
	if not Singleton.game:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		# Check construction area
		if state == "not_built" and area_construction.monitoring:
			if _is_point_in_area(mouse_pos, area_construction):
				if Singleton.game.can_afford_tower("triple_archer_tower"):
					if Singleton.game.purchase_tower("triple_archer_tower"):
						current_archer_tower = TRIPLE_ARCHER_TOWER.instantiate()
						current_archer_tower.position = global_position
						get_parent().add_child(current_archer_tower)
						state = "level_1"
						var upgrade_cost = Singleton.game.tower_cost["quad_archer_tower"]
						label.text = "Upgrade: " + str(upgrade_cost) + "g"
						tower_construction.visible = false
						area_construction.monitoring = false
						area_construction.monitorable = false
						area_tower.visible = true
						area_tower.monitoring = true
						area_tower.monitorable = true
				else:
					label.text = "Not enough gold!"
					label.visible = true
					await get_tree().create_timer(1.5).timeout
					if state == "not_built":
						var cost = Singleton.game.tower_cost["triple_archer_tower"]
						label.text = "Build: " + str(cost) + "g"
						label.visible = true
				get_viewport().set_input_as_handled()
		
		# Check tower area
		elif state == "level_1" and area_tower.monitoring:
			if _is_point_in_area(mouse_pos, area_tower):
				if Singleton.game.can_afford_tower("quad_archer_tower"):
					if Singleton.game.purchase_tower("quad_archer_tower"):
						current_archer_tower.queue_free()
						current_archer_tower = QUAD_ARCHER_TOWER.instantiate()
						current_archer_tower.position = global_position
						get_parent().add_child(current_archer_tower)
						state = "level_2"
						label.visible = false
				else:
					label.text = "Not enough gold!"
					label.visible = true
					await get_tree().create_timer(1.5).timeout
					if state == "level_1":
						var cost = Singleton.game.tower_cost["quad_archer_tower"]
						label.text = "Upgrade: " + str(cost) + "g"
						label.visible = true
				get_viewport().set_input_as_handled()
