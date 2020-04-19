extends Node


remote func launch_game():
	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points = {}
	spawn_points[1] = 0 # Server in spawn point 0.
	var spawn_point_idx = 1
	for p in networkController.players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1

	# Call to pre-start game with the spawn points.
	for p in networkController.players:
		rpc_id(p, "pre_start_game", spawn_points)

	pre_start_game(spawn_points)




remote func pre_start_game(spawn_points):


	var sceneTree:MultiplayerAPI = get_tree().multiplayer

	var myId:int = sceneTree.get_network_unique_id()


	var world = sceneLoader.load_scene(sceneLoader.GameScene.ForestMap)
	var player_prefab = load("res://Prefabs/Player/Player.tscn")
	var camera_prefab = load("res://Prefabs/Player/Camera.tscn")

	for p_id in spawn_points:
		var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).translation

		var player = player_prefab.instance()
		player.set_name(str(p_id)) # Use unique ID as node name.
		player.translation=spawn_pos
		player.set_network_master(p_id) #set unique id as master.
		#TODO: Set player name here
		world.get_node("Players").add_child(player)

		if(myId != p_id):
			continue

		print("Init Camera")
		var camera = camera_prefab.instance()
		world.add_child(camera)
		camera.connect("update_controls", player, "_on_update_controls")
		camera.set_target(player)


	if not get_tree().is_network_server():
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
