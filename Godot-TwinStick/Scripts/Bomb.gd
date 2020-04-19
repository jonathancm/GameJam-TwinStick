extends RigidBody


puppet var net_position:Vector3
puppet var net_rotation:Quat
puppet var net_timeleft:float

var exploded:bool

export(NodePath) var explosionArea
export var timeleft:float = 5.0
export var damage:float = 1.0
export(Resource) var explosion_prefab


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(dt):
	if(is_network_master()):
		process_master(dt)
	else:
		process_puppet()


func process_master(dt:float):
	timeleft -= dt

	rset_unreliable("net_timeleft", timeleft)
	rset_unreliable("net_position", global_transform.origin)
	rset_unreliable("net_rotation", global_transform.basis.get_rotation_quat())

	if(timeleft < 0):
		var instance = explosion_prefab.instance()
		instance.set_name("bomb_explosion")
		instance.global_transform.origin = global_transform.origin
		get_parent().add_child(instance)
		deal_area_damage()
		set_process(false)
		rpc("net_explode_and_destroy")


func process_puppet():
	global_transform = Transform(Basis(net_rotation), net_position)


func deal_area_damage():
	var area = get_node(explosionArea)
	for body in area.get_overlapping_bodies():
		if body.has_method("rpc_take_damage"):
			body.rpc("rpc_take_damage", damage)


remotesync func net_explode_and_destroy():
	queue_free()
