extends Node

class NetworkPlayer:
	var id:int = -1
	var username:String = "Spectator"
	var seat_number:int = 0

# Godot default Server ID
const server_id = 1

# Default game port. Can be any number between 1024 and 49151.
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 4

# Player Network Infos
var my_network_info = NetworkPlayer.new()
var registered_players = {}
var players_ready = []

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)


func _ready():
	var _error = 0
	_error = get_tree().connect("network_peer_connected", self, "_player_connected")
	_error = get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	_error = get_tree().connect("connected_to_server", self, "_connected_ok")
	_error = get_tree().connect("connection_failed", self, "_connected_fail")
	_error = get_tree().connect("server_disconnected", self, "_server_disconnected")


# On Button press
func host_game(new_player_name):
	my_network_info.username = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)
	_player_connected(server_id)


# On Button press
func join_game(ip, new_player_name):
	my_network_info.username = new_player_name
	var client = NetworkedMultiplayerENet.new()
	client.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(client)


func begin_game():
	assert(get_tree().is_network_server())
	gameController.launch_game()


func end_game():
	if has_node("/root/ForestMap"): # Game is in progress.
		get_node("/root/ForestMap").queue_free()

	emit_signal("game_ended")
	registered_players.clear()
	if(is_network_master()):
		get_tree().set_network_peer(null)


#
# Network Callbacks from SceneTree
#
# Callback from SceneTree.
func _player_connected(id):
	if(get_tree().is_network_server()):
		rpc_id(id, "request_username")


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")


# Callback from SceneTree.
func _player_disconnected(id):
	if has_node("/root/ForestMap"): # Game is in progress.
		emit_signal("game_error", "Player " + registered_players[id].username + " disconnected")
		end_game()
	elif get_tree().is_network_server(): # Game is not in progress.
		host_unregister_player(id)


# Lobby management functions.
remotesync func request_username():
	rpc_id(server_id,"host_register_player", my_network_info.username)


remotesync func host_register_player(username):
	assert(is_network_master())
	var id = get_tree().get_rpc_sender_id()
	registered_players[id] = NetworkPlayer.new()
	registered_players[id].id = id
	registered_players[id].username = username
	registered_players[id].seat_number = registered_players.size()

	# TODO: modify code to support sending classes by RPC
	for player in registered_players.values():
		rpc("update_player_info", player.id, player.username, player.seat_number)


func host_unregister_player(id):
	assert(is_network_master())
	registered_players.erase(id)

	# TODO: modify code to support sending classes by RPC
	rpc("remove_player_info", registered_players)


remotesync func update_player_info(id, username, seat_number):
	if(id == get_tree().get_network_unique_id()):
		my_network_info.id = id
		my_network_info.seat_number = seat_number

	registered_players[id] = NetworkPlayer.new()
	registered_players[id].id = id
	registered_players[id].username = username
	registered_players[id].seat_number = seat_number
	emit_signal("player_list_changed")

remotesync func remove_player_info(id):
	if(id == get_tree().get_network_unique_id()):
		my_network_info.id = -1
		my_network_info.seat_number = 0

	registered_players.remove(id)
	emit_signal("player_list_changed")



#
# Usefeul Getters
#
func get_server_port():
	return DEFAULT_PORT

func get_my_player_name():
	return my_network_info.username

func get_my_seat_number():
	return my_network_info.seat_number

func get_player_list():
	var player_names = {}
	print(str(registered_players))
	for player in registered_players.values():
		player_names[player.seat_number] = player.username
	return player_names
