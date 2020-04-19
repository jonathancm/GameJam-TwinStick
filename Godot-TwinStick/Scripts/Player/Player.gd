extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var left_stick = Vector2.ZERO
onready var mouse_direction = Vector3.ZERO
onready var jump = false
onready var velocity = Vector3.ZERO

export var max_speed = 0.5
export var jump_velocity = 10.0
export var inertia = 0.5
export var gravity = 9.8

puppet var net_position:Vector3
puppet var net_rotation:Quat



# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(dt:float):
	
	if(is_network_master()):
		_physics_process_master(dt)
		return
		
	global_transform = Transform(Basis(net_rotation), net_position)
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
master func _physics_process_master(dt:float):
	
	
	var direction:Vector3 = mouse_direction
	direction.y = 0
	
	if(direction.length() > 0.1):
		transform = transform.looking_at(global_transform.origin + direction, Vector3.UP)
	
	
	var targetVelocity = max_speed * left_stick.normalized()
	
	velocity = velocity.linear_interpolate(
					Vector3(targetVelocity.x, velocity.y, targetVelocity.y), 
					dt*(1.0/inertia))
					
	velocity.y -= gravity*dt
	
	if(is_on_floor() && jump):
		velocity.y = jump_velocity
	
	velocity = move_and_slide(velocity, Vector3.UP)
	
	rset("net_position", global_transform.origin)
	rset("net_rotation", global_transform.basis.get_rotation_quat())
	
	


func _on_update_controls(left_stick:Vector2, mouse_direction:Vector3, jump:bool):
	self.mouse_direction = mouse_direction
	self.left_stick = left_stick
	self.jump = jump
	
