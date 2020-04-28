extends VBoxContainer

#
# Cached References
#
export(NodePath) var path_label_username
export(NodePath) var path_icon_avatar
export(NodePath) var path_label_score
onready var label_username = get_node(path_label_username)
onready var icon_avatar = get_node(path_icon_avatar)
onready var label_score = get_node(path_label_score)

#
# Internal Variables
#
var player = null

func set_assigned_player(player_node):
	player = player_node
	label_username.text = player.network_name
	_on_player_state_change(player)
	var _error = player.connect("state_change", self, "_on_player_state_change")

func _on_player_state_change(_player):
	label_score.text = str(networkController.get_player_score(player.network_id))
	icon_avatar.texture = player.get_player_icon()
