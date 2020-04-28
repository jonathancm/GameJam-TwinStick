extends RigidBody


puppet var net_position:Vector3
puppet var net_rotation:Quat
puppet var net_timeleft:float

var exploded:bool

export(NodePath) var explosionArea
export var timeleft:float = 5.0
export var damage:float = 1.0
export(Resource) var explosion_prefab


func _ready():
	var _error = gameController.connect("round_ended", self, "_on_round_ended")

func _on_round_ended(_winner_id):
	if(is_network_master()):
		timeleft = 0
		damage = 0

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
		set_process(false)
		deal_area_damage()
		rpc("net_explode_and_destroy")


func process_puppet():
	global_transform = Transform(Basis(net_rotation), net_position)


func deal_area_damage():
	var area = get_node(explosionArea)
	for body in area.get_overlapping_bodies():
		if body.has_method("rpc_take_damage"):
			body.rpc("rpc_take_damage", damage)


remotesync func net_explode_and_destroy():
	var instance = explosion_prefab.instance()
	instance.set_name("bomb_explosion")
	get_parent().add_child(instance)
	instance.global_transform.origin = global_transform.origin
	queue_free()


master func rpc_take_damage(_damage:float):
	if(damage <= 0):
		return

	if(timeleft > 0):
		timeleft = 0.1
