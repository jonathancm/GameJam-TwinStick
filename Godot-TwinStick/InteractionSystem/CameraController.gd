extends Camera

signal update_controls

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var distance = 5.0
export var inertia = 0.5
var target:Spatial = null
var lookPosition = Vector3.ZERO


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	_process_camera_position(delta)
	
	var leftStick = GetLeftStick()
	var mouseDirection = GetMouseDirection()
	
	emit_signal("update_controls", leftStick, mouseDirection)
	

func GetLeftStick() -> Vector2:
	
	var result = Vector2.ZERO
	
	if Input.is_action_pressed("control_up"):
		result += Vector2.UP
	if Input.is_action_pressed("control_down"):
		result += Vector2.DOWN
	if Input.is_action_pressed("control_left"):
		result += Vector2.LEFT
	if Input.is_action_pressed("control_right"):
		result += Vector2.RIGHT
	
	return result;
	
	
func _process_camera_position(dt:float):
	
	if(target == null):
		return
	
	var pos = distance * global_transform.basis.z + target.global_transform.origin
	
	lookPosition = lookPosition.linear_interpolate(pos, dt/inertia)
	
	global_transform.origin = lookPosition;

func GetMouseDirection() -> Vector3:
	
	if(target == null):
		return Vector3.ZERO
	
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = project_ray_origin(mouse_pos)
	var ray_to = ray_from + project_ray_normal(mouse_pos) * 100.0
	var space_state = get_world().direct_space_state
	var selection = space_state.intersect_ray(ray_from, ray_to)
	
	
	if(selection.has("position")):
		return selection.position - target.global_transform.origin
	
	var targetPos = target.global_transform.origin
	
	return (targetPos.y - ray_from.y)/(ray_to.y - ray_from.y) * (ray_to - ray_from) + ray_from - targetPos

	
	
	
