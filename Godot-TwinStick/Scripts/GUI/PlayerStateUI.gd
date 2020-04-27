extends VBoxContainer

#
# Cached References
#
export(NodePath) var path_label_username
export(NodePath) var path_icon_avatar
export(NodePath) var path_label_score

#
# Internal Variables
#
onready var label_username = get_node(path_label_username)
onready var icon_avatar = get_node(path_icon_avatar)
onready var label_score = get_node(path_label_score)

func set_username(name:String):
	label_username.text = name

func set_icon(seat_number:int):
	pass

func set_score(score:int):
	label_score.text = str(score)
