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

# Pinch-to-zoom variables
var touch_points = {}
var initial_distance = 0.0
var initial_zoom = Vector2.ONE
var is_pinching = false

# Two-finger pan variables
var is_two_finger_panning = false
var pan_start_position = Vector2.ZERO
var camera_start_position = Vector2.ZERO
var touch_pan_sensitivity = 10.0
var trackpad_pan_sensitivity = 15.0

# Called when the node enters the scene tree for the first time.
func _ready():
	zoomTarget = zoom
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	Zoom(delta)
	SimplePan(delta)
	ClickAndDrag()

func _input(event):
	if event is InputEventScreenTouch:
		handle_touch(event)
	elif event is InputEventScreenDrag:
		handle_drag(event)
	elif event is InputEventMouseButton:
		handle_mouse_wheel(event)
	elif event is InputEventMagnifyGesture:
		handle_magnify_gesture(event)
	elif event is InputEventPanGesture:
		handle_pan_gesture(event)
	
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

func handle_touch(event: InputEventScreenTouch):
	if event.pressed:
		touch_points[event.index] = event.position
		
		# Start two-finger panning or pinch gesture
		if touch_points.size() == 2:
			start_two_finger_gesture()
	else:
		if touch_points.has(event.index):
			touch_points.erase(event.index)
		
		# End gestures if we have less than 2 touch points
		if touch_points.size() < 2:
			end_two_finger_gesture()

func handle_drag(event: InputEventScreenDrag):
	if touch_points.has(event.index):
		touch_points[event.index] = event.position
		
		# Update two-finger gestures
		if touch_points.size() == 2:
			update_two_finger_gesture()

func start_two_finger_gesture():
	var points = touch_points.values()
	if points.size() == 2:
		# Initialize pinch gesture
		initial_distance = points[0].distance_to(points[1])
		initial_zoom = zoom
		is_pinching = true
		
		# Initialize pan gesture
		pan_start_position = (points[0] + points[1]) / 2.0
		camera_start_position = position
		is_two_finger_panning = true

func update_two_finger_gesture():
	var points = touch_points.values()
	if points.size() == 2:
		# Update pinch zoom
		var current_distance = points[0].distance_to(points[1])
		
		if initial_distance > 0:
			var zoom_factor = current_distance / initial_distance
			var new_zoom = initial_zoom * zoom_factor
			
			# Clamp the zoom to the defined limits
			new_zoom = Vector2(
				clamp(new_zoom.x, zoom_min.x, zoom_max.x),
				clamp(new_zoom.y, zoom_min.y, zoom_max.y)
			)
			
			zoomTarget = new_zoom
		
		# Update two-finger pan
		var current_center = (points[0] + points[1]) / 2.0
		var pan_delta = (pan_start_position - current_center) * touch_pan_sensitivity
		var desired_position = camera_start_position + pan_delta / zoom.x
		
		# Apply camera limits
		desired_position.x = clamp(desired_position.x, camera_limit_left, camera_limit_right)
		desired_position.y = clamp(desired_position.y, camera_limit_top, camera_limit_bottom)
		position = desired_position

func end_two_finger_gesture():
	is_pinching = false
	initial_distance = 0.0
	is_two_finger_panning = false

func handle_mouse_wheel(event: InputEventMouseButton):
	# Handle Ctrl+scroll wheel for zoom (common on Mac)
	if event.pressed and Input.is_key_pressed(KEY_CTRL):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoomTarget *= 1.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoomTarget *= 0.9
		
		zoomTarget = Vector2(
			clamp(zoomTarget.x, zoom_min.x, zoom_max.x),
			clamp(zoomTarget.y, zoom_min.y, zoom_max.y)
		)

func handle_magnify_gesture(event: InputEventMagnifyGesture):
	# Handle native trackpad pinch-to-zoom gestures
	var zoom_factor = event.factor
	zoomTarget *= zoom_factor
	
	zoomTarget = Vector2(
		clamp(zoomTarget.x, zoom_min.x, zoom_max.x),
		clamp(zoomTarget.y, zoom_min.y, zoom_max.y)
	)

func handle_pan_gesture(event: InputEventPanGesture):
	# Handle native trackpad two-finger pan gestures
	var pan_delta = event.delta * trackpad_pan_sensitivity
	var desired_position = position + pan_delta / zoom.x
	
	# Apply camera limits
	desired_position.x = clamp(desired_position.x, camera_limit_left, camera_limit_right)
	desired_position.y = clamp(desired_position.y, camera_limit_top, camera_limit_bottom)
	position = desired_position
