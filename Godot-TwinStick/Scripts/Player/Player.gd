extends KinematicBody



signal state_change(player)

onready var isAlive = true
onready var left_stick = Vector2.ZERO
onready var mouse_direction = Vector3.ZERO
onready var jump = false
onready var shoot = false
onready var velocity = Vector3.ZERO

export var id = -1
export var max_speed = 0.5
export var jump_velocity = 10.0
export var inertia = 0.5
export var gravity = 9.8
export(Resource) var bomb_prefab

puppet var net_position:Vector3
puppet var net_rotation:Quat

var bombID = 0;




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


	if(isAlive && shoot):
		bombID += 1
		var gunSocket = get_node("GunSocket")
		var transform1 = gunSocket.get_global_transform()
		var transform2 = gunSocket.get_global_transform()
		var bombName = "Bomb" + "_" + get_name() + "_" + str(bombID)
		transform2.origin += Vector3(0,2,0)
		spawn_bomb(bombName, transform1)
		rpc("spawn_bomb", bombName, transform2)






remote func spawn_bomb(name:String, transform:Transform):
	var impulseStrength = 2.0
	var impulseDirection = -transform.basis.z
	var instance = bomb_prefab.instance()
	instance.set_name(name)
	instance.set_global_transform(transform)
	instance.set_network_master(get_network_master())
	get_parent().add_child(instance)
	instance.apply_impulse(Vector3.ZERO, impulseStrength*impulseDirection)
	instance.apply_torque_impulse (impulseStrength/20.0*Vector3.LEFT)




func _on_update_controls(_left_stick:Vector2, _mouse_direction:Vector3, _jump:bool, _shoot:bool):
	mouse_direction = _mouse_direction
	left_stick = _left_stick
	jump = _jump
	shoot = _shoot



remotesync func rpc_set_alive(var _is_alive):
	isAlive = _is_alive
	emit_signal("state_change", self)
	




master func rpc_take_damage(_amount:float):
	if(isAlive && _amount > 0):
		rpc("rpc_set_alive", false)


master func rpc_respawn(_position:Vector3):
	global_transform.origin = _position
	rpc("rpc_set_alive", true)




