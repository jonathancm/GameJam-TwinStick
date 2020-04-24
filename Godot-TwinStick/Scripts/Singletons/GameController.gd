extends Node

#
# Internal variables
#
var players = {}
var spawn_positions = {}
var respawning = false


func _on_player_state_change(player):
	if(respawning):
		return

	players[player.network_id] = player

	if(end_condition()):
		print("A player has won! But I don't know who!")
		respawning = true
		yield(get_tree().create_timer(5.0), "timeout")

		print("Restarting Game...")
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



func launch_game():
	rpc("pre_start_game")



remotesync func pre_start_game():
	print("func pre_start_game called!")
	var isHost:bool = is_network_master()
	var sceneTree:MultiplayerAPI = get_tree().multiplayer
	var myId:int = sceneTree.get_network_unique_id()

	var world = sceneLoader.load_scene(sceneLoader.GameScene.ForestMap)
	var player_prefab = load("res://Prefabs/Player/Player.tscn")
	var camera_prefab = load("res://Prefabs/Player/Camera.tscn")

	# Setup Spawn Positions
	spawn_positions.clear()
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

		if(isHost):
			player.connect("state_change", self, "_on_player_state_change")
			players[player.network_id] = player

		if(myId != net_player.id):
			continue

		var camera = camera_prefab.instance()
		world.add_child(camera)
		camera.connect("update_controls", player, "_on_update_controls")
		camera.set_target(player)

	# Ready to start
	rpc_id(networkController.server_id, "ready_to_start", get_tree().get_network_unique_id())




remotesync func ready_to_start(id):
	print("func ready_to_start called!")
	if not id in networkController.players_ready:
		networkController.players_ready.append(id)

	if networkController.players_ready.size() == networkController.registered_players.size():
		rpc("post_start_game")




remotesync func post_start_game():
	print("func post_start_game called!")
	get_tree().set_pause(false) # Unpause and unleash the game!
