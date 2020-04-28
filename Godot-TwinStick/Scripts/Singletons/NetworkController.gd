extends Node

class NetworkPlayer:
	var id:int = -1
	var username:String = "Spectator"
	var seat_number:int = 0
	var score:int = 0

#
# Constants
#
const server_id = 1 # Godot default Server ID
const DEFAULT_PORT = 10567 # Default game port. Can be any number between 1024 and 49151.
const MAX_PEERS = 4 # Max number of players.

#
# Internal Variables
#
var host = null
var my_network_info = NetworkPlayer.new()
var registered_players = {}


# Signals
signal player_connection(player_name)
signal player_disconnection(player_name)
signal connection_failed()
signal connection_succeeded()
signal network_error(message)


func _ready():
	var _error = 0
	_error = get_tree().connect("network_peer_connected", self, "_player_connected")
	_error = get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	_error = get_tree().connect("connected_to_server", self, "_connected_ok")
	_error = get_tree().connect("connection_failed", self, "_connected_fail")
	_error = get_tree().connect("server_disconnected", self, "_server_disconnected")


func _exit_tree():
	server_cleanup()


# On Button press
func host_game(new_player_name):
	my_network_info.username = new_player_name

	if(host != null):
		host.close_connection()

	host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)

	_player_connected(server_id)


# On Button press
func join_game(ip, new_player_name:String):
	my_network_info.username = new_player_name
	var client = NetworkedMultiplayerENet.new()
	client.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(client)


func begin_game():
	assert(get_tree().is_network_server())
	gameController.rpc("pre_start_game")


master func server_cleanup():
	registered_players.clear()


#
# Network Callbacks from SceneTree
#
# Callback from SceneTree.
func _player_connected(id:int):
	if(get_tree().is_network_server()):
		rpc_id(id, "request_username")


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("network_error", "Server disconnected")


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")


# Callback from SceneTree.
func _player_disconnected(id:int):
	if(get_tree().is_network_server()):
		server_unregister_player(id)


# Lobby management functions.
remotesync func request_username():
	rpc_id(server_id,"server_register_player", my_network_info.username)


master func server_register_player(username:String):
	var id = get_tree().get_rpc_sender_id()
	registered_players[id] = NetworkPlayer.new()
	registered_players[id].id = id
	registered_players[id].username = username
	registered_players[id].seat_number = registered_players.size()

	# TODO: modify code to support sending classes by RPC, send registered_players
	for player in registered_players.values():
		rpc("update_player_info", player.id, player.username, player.seat_number, player.score)


master func server_unregister_player(id:int):
	# TODO: modify code to support sending classes by RPC, send registered_players
	rpc("remove_player_info", id)


remotesync func update_player_info(id:int, username:String, seat_number:int, score:int):
	if(id == get_tree().get_network_unique_id()):
		my_network_info.id = id
		my_network_info.seat_number = seat_number

	registered_players[id] = NetworkPlayer.new()
	registered_players[id].id = id
	registered_players[id].username = username
	registered_players[id].seat_number = seat_number
	registered_players[id].score = score
	emit_signal("player_connection", id)


remotesync func remove_player_info(id:int):
	if(id == get_tree().get_network_unique_id()):
		my_network_info.id = -1
		my_network_info.seat_number = 0

	if(registered_players.has(id)):
		var player_name = registered_players[id].username
		registered_players.erase(id)
		emit_signal("player_disconnection", player_name)


remotesync func increase_player_score(id:int, amount:int):
	if(registered_players.has(id)):
		registered_players[id].score += amount


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
	for player in registered_players.values():
		player_names[player.seat_number] = player.username
	return player_names

func get_player_score(id:int):
	if(registered_players.has(id)):
		return registered_players[id].score
	else:
		return 0
