extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var left_stick = Vector2.ZERO
onready var mouse_direction = Vector3.ZERO
onready var velocity = Vector3.ZERO
export var max_speed = 0.5
export var inertia = 0.5
export var gravity = 9.8


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
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
	
	


func _on_update_controls(left_stick:Vector2, mouse_direction:Vector3):
	self.mouse_direction = mouse_direction
	self.left_stick = left_stick
	
