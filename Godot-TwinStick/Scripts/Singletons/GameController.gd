extends Node

#
# Internal variables
#
var players = {}
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
			player.rpc("rpc_respawn", player.network_id)

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
	var isHost:bool = is_network_master()
	var sceneTree:MultiplayerAPI = get_tree().multiplayer
	var myId:int = sceneTree.get_network_unique_id()

	var world = sceneLoader.load_scene(sceneLoader.GameScene.ForestMap)
	var player_prefab = load("res://Prefabs/Player/Player.tscn")
	var camera_prefab = load("res://Prefabs/Player/Camera.tscn")

	for net_player in networkController.registered_players.values():
		var spawn_pos = world.get_node("SpawnPoints/" + str(net_player.seat_number)).translation

		var player = player_prefab.instance()
		player.set_name(net_player.username)
		player.network_id = net_player.id
		player.network_name = net_player.username
		player.translation = spawn_pos
		player.set_network_master(net_player.id)
		world.get_node("Players").add_child(player)

		if(isHost):
			player.connect("state_change", self, "_on_player_state_change")
			players[player.network_id] = player

		if(myId != net_player.id):
			continue

		print("Init Camera")
		var camera = camera_prefab.instance()
		world.add_child(camera)
		camera.connect("update_controls", player, "_on_update_controls")
		camera.set_target(player)


	if not get_tree().is_network_server():
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif networkController.registered_players.size() == 0:
		post_start_game()




remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if not id in networkController.players_ready:
		networkController.players_ready.append(id)

	if networkController.players_ready.size() == networkController.registered_players.size():
		for p in networkController.players:
			rpc_id(p, "post_start_game")
		post_start_game()




remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!
