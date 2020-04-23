extends Control

# Connection Menu References
export(NodePath) var path_menu_connection = null
export(NodePath) var path_username_input = null
export(NodePath) var path_ip_input = null
export(NodePath) var path_button_host = null
export(NodePath) var path_button_join = null
export(NodePath) var path_error_label = null
export(NodePath) var path_button_quit = null

# Lobby Menu References
export(NodePath) var path_menu_lobby = null
export(NodePath) var path_lobby_list = null
export(NodePath) var path_button_start = null

# Error Dialog References
export(NodePath) var path_error_dialog = null

# Internal Variables
onready var menu_connection = get_node(path_menu_connection)
onready var username_input = get_node(path_username_input)
onready var ip_input = get_node(path_ip_input)
onready var button_host = get_node(path_button_host)
onready var button_join = get_node(path_button_join)
onready var error_label = get_node(path_error_label)
onready var button_quit = get_node(path_button_quit)
onready var menu_lobby = get_node(path_menu_lobby)
onready var lobby_list = get_node(path_lobby_list)
onready var button_start = get_node(path_button_start)
onready var error_dialog = get_node(path_error_dialog)


func _ready():
	var _error = 0;
	_error = networkController.connect("connection_failed", self, "_on_connection_failed")
	_error = networkController.connect("connection_succeeded", self, "_on_connection_success")
	_error = networkController.connect("player_list_changed", self, "refresh_lobby")
	_error = networkController.connect("game_ended", self, "_on_game_ended")
	_error = networkController.connect("game_error", self, "_on_game_error")
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		username_input.text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		username_input.text = desktop_path[desktop_path.size() - 2]


func _on_host_pressed():
	if username_input.text == "":
		error_label.text = "Invalid name!"
		return

	menu_connection.hide()
	menu_lobby.show()
	error_label.text = ""

	var player_name = username_input.text
	networkController.host_game(player_name)
	refresh_lobby()


func _on_join_pressed():
	if username_input.text == "":
		error_label.text = "Invalid name!"
		return

	var ip = ip_input.text
	if not ip.is_valid_ip_address():
		error_label.text = "Invalid IP address!"
		return

	error_label.text = ""
	button_host.disabled = true
	button_join.disabled = true

	var player_name = username_input.text
	networkController.join_game(ip, player_name)


func _on_connection_success():
	menu_connection.hide()
	menu_lobby.show()


func _on_connection_failed():
	button_host.disabled = false
	button_join.disabled = false
	error_label.set_text("Connection failed.")


func _on_game_ended():
	show()
	menu_connection.show()
	menu_lobby.hide()
	button_host.disabled = false
	button_join.disabled = false


func _on_game_error(errtxt):
	error_dialog.dialog_text = errtxt
	error_dialog.popup_centered_minsize()
	button_host.disabled = false
	button_join.disabled = false


func refresh_lobby():
	var players = networkController.get_player_list()
	var my_seat_number = networkController.get_my_seat_number()
	players[my_seat_number - 1] += " (You)"
	lobby_list.clear()
	for p in players:
		lobby_list.add_item(p)

	button_start.disabled = not get_tree().is_network_server()


func _on_start_pressed():
	networkController.begin_game()
