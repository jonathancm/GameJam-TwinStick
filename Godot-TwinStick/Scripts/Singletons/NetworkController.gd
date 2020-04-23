extends Node

class NetworkPlayer:
	var id:int = -1
	var username:String = "Spectator"
	var seat_number:int = 0
	var isReady:bool = false

# Godot default Server ID
const server_id = 1

# Default game port. Can be any number between 1024 and 49151.
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 4

# Name for my player.
var my_username = "Player1"

# Names for remote players in id:NetworkPlayer format.
var registered_players = {}

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)


# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	rpc("register_player", id, my_username)


# Callback from SceneTree.
func _player_disconnected(id):
	if has_node("/root/ForestMap"): # Game is in progress.
		if get_tree().is_network_server():
			emit_signal("game_error", "Player " + registered_players[id].username + " disconnected")
			end_game()
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)


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


# Lobby management functions.

remote func register_player(id, new_player_name):
	registered_players[id] = NetworkPlayer.new()
	registered_players[id].id = id
	registered_players[id].username = new_player_name
	registered_players[id].seat_number = registered_players.size()
	print("New player added: " + str(id))
	emit_signal("player_list_changed")


func unregister_player(id):
	registered_players.erase(id)
	emit_signal("player_list_changed")


func host_game(new_player_name):
	var my_id = server_id
	my_username = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)
	register_player(my_id, my_username)


func join_game(ip, new_player_name):
	my_username = new_player_name
	var client = NetworkedMultiplayerENet.new()
	client.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(client)


func get_player_list():
	var player_names = []
	for player in registered_players.values():
		player_names.append(player.username)

	return player_names


func get_player_name():
	return my_username

func get_my_seat_number():
	return registered_players[get_tree().get_network_unique_id()].seat_number

func begin_game():
	assert(get_tree().is_network_server())
	gameController.launch_game()


func end_game():
	if has_node("/root/ForestMap"): # Game is in progress.
		# End it
		get_node("/root/ForestMap").queue_free()

	emit_signal("game_ended")
	registered_players.clear()


func _ready():
	var _error = 0
	_error = get_tree().connect("network_peer_connected", self, "_player_connected")
	_error = get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	_error = get_tree().connect("connected_to_server", self, "_connected_ok")
	_error = get_tree().connect("connection_failed", self, "_connected_fail")
	_error = get_tree().connect("server_disconnected", self, "_server_disconnected")
