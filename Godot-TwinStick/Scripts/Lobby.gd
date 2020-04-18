extends Control

func _ready():
	# Called every time the node is added to the scene.
	networkController.connect("connection_failed", self, "_on_connection_failed")
	networkController.connect("connection_succeeded", self, "_on_connection_success")
	networkController.connect("player_list_changed", self, "refresh_lobby")
	networkController.connect("game_ended", self, "_on_game_ended")
	networkController.connect("game_error", self, "_on_game_error")
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		$Connect/VBox1/Name.text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		$Connect/VBox1/Name.text = desktop_path[desktop_path.size() - 2]


func _on_host_pressed():
	if $Connect/VBox1/Name.text == "":
		$Connect/VBox1/ErrorLabel.text = "Invalid name!"
		return

	$Connect.hide()
	$Players.show()
	$Connect/VBox1/ErrorLabel.text = ""

	var player_name = $Connect/VBox1/Name.text
	networkController.host_game(player_name)
	refresh_lobby()


func _on_join_pressed():
	if $Connect/VBox1/Name.text == "":
		$Connect/VBox1/ErrorLabel.text = "Invalid name!"
		return

	var ip = $Connect/VBox1/IPAddress.text
	if not ip.is_valid_ip_address():
		$Connect/VBox1/ErrorLabel.text = "Invalid IP address!"
		return

	$Connect/VBox1/ErrorLabel.text = ""
	$Connect/VBox1/HBox1/Host.disabled = true
	$Connect/VBox1/HBox1/Join.disabled = true

	var player_name = $Connect/VBox1/Name.text
	networkController.join_game(ip, player_name)


func _on_connection_success():
	$Connect.hide()
	$Players.show()


func _on_connection_failed():
	$Connect/VBox1/HBox1/Host.disabled = false
	$Connect/VBox1/HBox1/Join.disabled = false
	$Connect/VBox1/ErrorLabel.set_text("Connection failed.")


func _on_game_ended():
	show()
	$Connect.show()
	$Players.hide()
	$Connect/VBox1/HBox1/Host.disabled = false
	$Connect/VBox1/HBox1/Join.disabled = false


func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered_minsize()
	$Connect/VBox1/HBox1/Host.disabled = false
	$Connect/VBox1/HBox1/Join.disabled = false


func refresh_lobby():
	var players = networkController.get_player_list()
	players.sort()
	$Players/List.clear()
	$Players/List.add_item(networkController.get_player_name() + " (You)")
	for p in players:
		$Players/List.add_item(p)

	$Players/Start.disabled = not get_tree().is_network_server()


func _on_start_pressed():
	networkController.begin_game()
