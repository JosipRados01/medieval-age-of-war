extends Camera2D

var camera_speed := 10
var zoom_max := Vector2(8, 8)
var zoom_min := Vector2(1.5, 1.5)
var zoom_speed := Vector2(0.1, 0.1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if  Input.is_action_pressed("up") and position.y > -700:
		position.y -= camera_speed
	if  Input.is_action_pressed("down") and position.y < 800:
		position.y += camera_speed
	if  Input.is_action_pressed("left") and position.x > 200:
		position.x -= camera_speed
	if  Input.is_action_pressed("right") and position.x < 6200:
		position.x += camera_speed
	
	# exclusionary if zoom in/out with zoom in taking priority
	if Input.is_action_pressed("zoom_in") and zoom < zoom_max:
		zoom = zoom + zoom_speed
	if Input.is_action_pressed("zoom_out") and zoom > zoom_min:
		zoom = zoom - zoom_speed
