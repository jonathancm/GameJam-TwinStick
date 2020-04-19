extends Spatial

# Called when the node enters the scene tree for the first time.
func _ready():
	var playerPrefab = load("res://Prototyping/JCM/PlayerBombTest.tscn")
	var player:Spatial = playerPrefab.instance()
	#add_child($, player)
	add_child(player)

	$Camera.connect("update_controls", player, "_on_update_controls")
	$Camera.target = player
	$Camera.lookPosition = player.global_transform.origin

func _toggle():
	pass # Replace with function body.
