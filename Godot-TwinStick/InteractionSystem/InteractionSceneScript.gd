extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	
	var playerPrefab = load("res://InteractionSystem/Player.tscn")
	var player:Spatial = playerPrefab.instance()
	#add_child($, player)
	add_child(player)
	
	$Camera.connect("update_controls", player, "_on_update_controls")
	$Camera.target = player
	$Camera.lookPosition = player.global_transform.origin
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _toggle():
	pass # Replace with function body.
