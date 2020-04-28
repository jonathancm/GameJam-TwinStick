extends Control

#
# Cached References
#
export(NodePath) var path_label_round_number
export(NodePath) var path_label_round_end
export(NodePath) var path_conatiner_player_uis
export(Resource) var prefab_player_ui

#
# Internal Variables
#
onready var label_round_number = get_node(path_label_round_number)
onready var label_round_end = get_node(path_label_round_end)
onready var container_player_uis = get_node(path_conatiner_player_uis)
var player_uis = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	var _error = 0
	_error = gameController.connect("game_started", self, "_on_game_start")
	_error = gameController.connect("round_started", self, "_on_round_start")
	_error = gameController.connect("round_ended", self, "_on_round_end")


func _on_game_start():
	for player in gameController.players.values():
		if(player.seat_number <= 0):
			continue

		player_uis[player.network_id] = prefab_player_ui.instance()
		container_player_uis.add_child(player_uis[player.network_id])
		player_uis[player.network_id].set_assigned_player(player)
		_on_round_start()


func _on_round_start():
	label_round_end.text = ""
	label_round_number.text = str(gameController.round_number)


func _on_round_end(winner_id):
	if(gameController.players.has(winner_id)):
		var winner_name = gameController.players[winner_id].network_name
		label_round_end.text = winner_name + " wins the round!"
	else:
		label_round_end.text = "Everybody lost!"
