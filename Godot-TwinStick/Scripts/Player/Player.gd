extends KinematicBody

signal state_change(player)

#
# Configurable Parameters
#
export var network_id = -1
export var network_name = ""
export var seat_number = 0
export var max_speed = 0.5
export var jump_velocity = 10.0
export var inertia = 0.5
export var gravity = 9.8
export var summoningSickness = 1.0
export var bombCooldown = 0.250
export(Resource) var bomb_prefab
export(NodePath) var view_normal_path
export(NodePath) var view_ghost_path
export(NodePath) var path_world_ui
export(Resource) var material_player1
export(Resource) var material_player2
export(Resource) var material_player3
export(Resource) var material_player4
export(Resource) var player_icon_1
export(Resource) var player_icon_2
export(Resource) var player_icon_3
export(Resource) var player_icon_4
export(Resource) var player_icon_ghost

#
# Internal Variables
#
onready var isAlive = true
onready var left_stick = Vector2.ZERO
onready var mouse_direction = Vector3.ZERO
onready var jump = false
onready var shoot = false
onready var velocity = Vector3.ZERO
onready var view_normal:Node
onready var view_ghost:Node
onready var bombID = 0;
onready var currentCooldown = summoningSickness;

puppet var net_position:Vector3
puppet var net_rotation:Quat
var isShootAllowed:bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	var _error = 0
	_error = gameController.connect("round_started", self, "_on_round_started")
	_error = gameController.connect("round_ended", self, "_on_round_ended")

	get_node(path_world_ui)._set_username(network_name)
	view_normal = get_node(view_normal_path)
	view_ghost = get_node(view_ghost_path)

	match seat_number:
		1:
			view_normal.set_material_override(material_player1)
		2:
			view_normal.set_material_override(material_player2)
		3:
			view_normal.set_material_override(material_player3)
		4:
			view_normal.set_material_override(material_player4)

	view_ghost.visible = false
	view_normal.visible = true


func _on_round_started():
	isShootAllowed = true

func _on_round_ended(_winner_id):
	isShootAllowed = false


func _process(delta):
	if(is_network_master() == false):
		return

	currentCooldown -= delta
	if(currentCooldown <= 0):
		currentCooldown = 0

	if(isAlive == false or isShootAllowed == false):
		return

	if(shoot and currentCooldown == 0):
		currentCooldown = bombCooldown
		bombID += 1
		var gunSocket = get_node("GunSocket")
		var transform = gunSocket.get_global_transform()
		var bombName = "Bomb" + "_" + get_name() + "_" + str(bombID)
		rpc("spawn_bomb", bombName, transform)




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






remotesync func spawn_bomb(_name:String, _transform:Transform):
	var impulseStrength = 2.0
	var impulseDirection = -_transform.basis.z
	var instance = bomb_prefab.instance()
	instance.set_name(_name)
	instance.set_global_transform(_transform)
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
	view_normal.visible = isAlive
	view_ghost.visible = !isAlive
	emit_signal("state_change", self)





master func rpc_take_damage(_amount:float):
	if(isAlive && _amount > 0):
		rpc("rpc_set_alive", false)


master func rpc_respawn(_position:Vector3):
	global_transform.origin = _position
	rpc("rpc_set_alive", true)


func get_player_icon():
	var player_icon = null
	if(isAlive):
		match seat_number:
			1:
				player_icon = player_icon_1
			2:
				player_icon = player_icon_2
			3:
				player_icon = player_icon_3
			4:
				player_icon = player_icon_4
			_:
				player_icon = player_icon_1
	else:
		player_icon =  player_icon_ghost

	return player_icon

