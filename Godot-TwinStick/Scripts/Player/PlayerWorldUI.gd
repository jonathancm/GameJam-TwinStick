extends Control

export(NodePath) var path_name_label

func _set_username(username):
	get_node(path_name_label).text = username
