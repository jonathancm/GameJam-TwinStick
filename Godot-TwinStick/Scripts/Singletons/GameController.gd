extends Node

#
# Internal variables
#
var isMatchRunning:bool = false
var lastErrorMessage:String = ""
var respawning = false
var round_number = 0
var players = {}
var players_ready = []
var spawn_positions = {}

#
# Signals
#
signal round_started()
signal round_ended(winner_id)

func _ready():
	var _error = 0
	_error = networkController.connect("player_disconnection", self, "_on_player_disconnect")
	_error = networkController.connect("network_error", self, "_on_network_error")



func _on_player_disconnect(player_name):
	if(isMatchRunning):
		lastErrorMessage = "Player " + player_name + " disconnected"
		end_game()


func _on_network_error(message):
	lastErrorMessage = message
	if(isMatchRunning):
		end_game()


func _on_player_state_change(player):
	if(respawning):
		return

	players[player.network_id] = player

	if(end_condition()):
		respawning = true

		# End current round
		var winner_id = -1
		for player in players.values():
			if(player.isAlive):
				winner_id = player.network_id
				networkController.rpc("increase_player_score", player.network_id, 1)
		rpc("trigger_round_end", winner_id)

		# Start new round after delay
		yield(get_tree().create_timer(5.0), "timeout")
		rpc("trigger_round_start", round_number + 1)
		for player in players.values():
			player.rpc("rpc_respawn", spawn_positions[player.network_id])

		respawning = false



func end_condition():
	var playersAlive = 0
	var totalPlayers = len(players.keys())
	for player in players.values():
		playersAlive += 1 if player.isAlive else 0

	if(totalPlayers == 1 and playersAlive < 1):
		return true

	if(playersAlive <= 1):
		return true

	return false

	#var totalAlive = sum(1 for alive in values)



remotesync func trigger_round_start(_round_number):
	round_number = _round_number
	emit_signal("round_started")



remotesync func trigger_round_end(winner_id):
	emit_signal("round_ended",winner_id)



remotesync func pre_start_game():
	var isHost:bool = is_network_master()
	var sceneTree:MultiplayerAPI = get_tree().multiplayer
	var myId:int = sceneTree.get_network_unique_id()

	# Reset match state
	reset_state()
	isMatchRunning = true

	var world = sceneLoader.load_scene(sceneLoader.GameScene.ForestMap)
	var player_prefab = load("res://Prefabs/Player/Player.tscn")
	var camera_prefab = load("res://Prefabs/Player/Camera.tscn")

	# Setup Spawn Positions
	for net_player in networkController.registered_players.values():
		var spawn_point = world.get_node("SpawnPoints/" + str(net_player.seat_number))
		spawn_positions[net_player.id] = spawn_point.global_transform.origin

	# Instantiate Player Avatars
	for net_player in networkController.registered_players.values():
		var player = player_prefab.instance()
		player.set_name(net_player.username)
		player.set_network_master(net_player.id)
		player.network_id = net_player.id
		player.network_name = net_player.username
		player.seat_number = net_player.seat_number
		world.get_node("Players").add_child(player)
		player.global_transform.origin = spawn_positions[net_player.id]
		players[player.network_id] = player

		if(isHost):
			player.connect("state_change", self, "_on_player_state_change")

		if(myId != net_player.id):
			continue

		var camera = camera_prefab.instance()
		world.add_child(camera)
		camera.connect("update_controls", player, "_on_update_controls")
		camera.set_target(player)

	# Ready to start
	rpc_id(networkController.server_id, "ready_to_start", get_tree().get_network_unique_id())



remotesync func ready_to_start(id):
	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == networkController.registered_players.size():
		rpc("post_start_game")



remotesync func post_start_game():
	round_number = 1
	emit_signal("round_started")
	get_tree().set_pause(false) # Unpause and unleash the game!



remotesync func end_game():
	isMatchRunning = false
	sceneLoader.load_scene(sceneLoader.GameScene.MainMenu)
	networkController.server_cleanup()


func reset_state():
	isMatchRunning = false
	lastErrorMessage = ""
	round_number = 0
	players.clear()
	players_ready.clear()
	spawn_positions.clear()
