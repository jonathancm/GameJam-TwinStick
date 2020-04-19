extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var left_stick = Vector2.ZERO
onready var mouse_direction = Vector3.ZERO
onready var jump = false
onready var shoot = false
onready var velocity = Vector3.ZERO

export var max_speed = 0.5
export var jump_velocity = 10.0
export var inertia = 0.5
export var gravity = 9.8
export(Resource) var bomb_prefab

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
	
	
	if(shoot):
		var gunSocket = get_node("GunSocket")
		var instance = bomb_prefab.instance()
		instance.set_global_transform(gunSocket.get_global_transform())
		get_parent().add_child(instance)
		var impulseStrength = 2.0
		var impulseDirection = -gunSocket.get_global_transform().basis.z
		instance.apply_impulse(Vector3.ZERO, impulseStrength*impulseDirection)
		instance.apply_torque_impulse (impulseStrength/20.0*Vector3.LEFT)
	
	


func _on_update_controls(_left_stick:Vector2, _mouse_direction:Vector3, _jump:bool, _shoot:bool):
	mouse_direction = _mouse_direction
	left_stick = _left_stick
	jump = _jump
	shoot = _shoot
	
