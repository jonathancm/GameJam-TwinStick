extends RigidBody



puppet var net_position:Vector3
puppet var net_rotation:Quat
puppet var net_timeleft:float

export var timeleft:float = 5.0


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
	
	rset("net_timeleft", timeleft)
	rset("net_position", global_transform.origin)
	rset("net_rotation", global_transform.basis.get_rotation_quat())
	
	if(timeleft < 0):
		set_process(false)
		rpc("net_destroy")
		
	
func process_puppet():
	global_transform = Transform(Basis(net_rotation), net_position)
	
remotesync func net_destroy():
	queue_free()
	
	
