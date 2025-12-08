extends Camera2D

@export var zoomSpeed : float = 10;
var zoomTarget :Vector2
var zoom_max := Vector2(2, 2)
var zoom_min := Vector2(0.3, 0.3)

var dragStartMousePos = Vector2.ZERO
var dragStartCameraPos = Vector2.ZERO
var isDragging : bool = false

var camera_limit_left = 200
var camera_limit_right = 6200
var camera_limit_top = -700
var camera_limit_bottom = 800

# Called when the node enters the scene tree for the first time.
func _ready():
	zoomTarget = zoom
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	Zoom(delta)
	SimplePan(delta)
	ClickAndDrag()
	
func Zoom(delta):
	if Input.is_action_just_pressed("camera_zoom_in"):
		zoomTarget *= 1.1
		
	if Input.is_action_just_pressed("camera_zoom_out"):
		zoomTarget *= 0.9
	
	zoomTarget = clamp(zoomTarget, zoom_min, zoom_max)
	zoom = zoom.slerp(zoomTarget, zoomSpeed * delta) 
	
	
func SimplePan(delta):
	var moveAmount = Vector2.ZERO
	if Input.is_action_pressed("camera_move_right") and position.x < camera_limit_right:
		moveAmount.x += 1
		
	if Input.is_action_pressed("camera_move_left") and position.x > camera_limit_left:
		moveAmount.x -= 1
		
	if Input.is_action_pressed("camera_move_up") and position.y > camera_limit_top:
		moveAmount.y -= 1
		
	if Input.is_action_pressed("camera_move_down") and position.y < camera_limit_bottom:
		moveAmount.y += 1
		
	moveAmount = moveAmount.normalized()
	position += moveAmount * delta * 1000 * (1/zoom.x)
	
func ClickAndDrag():
	if !isDragging and Input.is_action_just_pressed("camera_pan"):
		dragStartMousePos = get_viewport().get_mouse_position()
		dragStartCameraPos = position
		isDragging = true
		
	if isDragging and Input.is_action_just_released("camera_pan"):
		isDragging = false
		
	if isDragging:
		var moveVector = get_viewport().get_mouse_position() - dragStartMousePos
		var desiredPosition = dragStartCameraPos - moveVector * 1/zoom.x
		
		desiredPosition.x = clamp(desiredPosition.x,camera_limit_left, camera_limit_right)
		desiredPosition.y = clamp(desiredPosition.y,camera_limit_top, camera_limit_bottom)
		position = desiredPosition
