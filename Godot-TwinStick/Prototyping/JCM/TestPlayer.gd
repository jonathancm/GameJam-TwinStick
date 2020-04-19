extends KinematicBody

onready var left_stick = Vector2.ZERO
onready var mouse_direction = Vector3.ZERO
onready var velocity = Vector3.ZERO
onready var shoot = false
export var max_speed = 0.5
export var inertia = 0.5
export var gravity = 9.8

var bombPrefab = load("res://Prototyping/JCM/Bomb.tscn")

func _physics_process(dt:float):
	var direction:Vector3 = mouse_direction
	direction.y = 0

	transform = transform.looking_at(global_transform.origin + direction, Vector3.UP)


	var targetVelocity = max_speed * left_stick.normalized()

	velocity = velocity.linear_interpolate(
					Vector3(targetVelocity.x, velocity.y, targetVelocity.y),
					dt*(1.0/inertia))

	velocity.y -= gravity*dt

	velocity = move_and_slide(velocity, Vector3.UP)

	if(shoot):
		var gunSocket = get_node("GunSocket")
		var instance = bombPrefab.instance()
		instance.set_global_transform(gunSocket.get_global_transform())
		get_parent().add_child(instance)
		var impulseStrength = 2.0
		var impulseDirection = -gunSocket.get_global_transform().basis.z
		instance.apply_impulse(Vector3.ZERO, impulseStrength*impulseDirection)
		instance.apply_torque_impulse (impulseStrength/20.0*Vector3.LEFT)




func _on_update_controls(_left_stick:Vector2, _mouse_direction:Vector3, _shoot:bool):
	mouse_direction = _mouse_direction
	left_stick = _left_stick
	shoot = _shoot
