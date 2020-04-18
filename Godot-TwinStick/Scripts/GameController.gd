extends Node


remote func pre_start_game(spawn_points):
	# Change scene.
	var world = load("res://Scenes/Prototype0.tscn").instance()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Lobby").hide()

	var player_scene = load("res://Prefabs/Player.tscn")

	for p_id in spawn_points:
		var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).position
		var player = player_scene.instance()

		player.set_name(str(p_id)) # Use unique ID as node name.
		player.position=spawn_pos
		player.set_network_master(p_id) #set unique id as master.

		if p_id == get_tree().get_network_unique_id():
			# If node for this peer id, set name.
			networkController.player.set_player_name(networkController.player_name)
		else:
			# Otherwise set name from peer.
			player.set_player_name(networkController.players[p_id])

		world.get_node("Players").add_child(player)

	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif networkController.players.size() == 0:
		post_start_game()




remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if not id in networkController.players_ready:
		networkController.players_ready.append(id)

	if networkController.players_ready.size() == networkController.players.size():
		for p in networkController.players:
			rpc_id(p, "post_start_game")
		post_start_game()




remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!
