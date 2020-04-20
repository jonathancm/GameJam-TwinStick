extends Node

enum GameScene{
	Start,
	Lobby,
	ForestMap,
   }

#
# Internal Variables
#
var currentGameScene = GameScene.Start


#
# Node functions
#
func _ready():
	pass




func load_scene(newSceneID):
	var newSceneName = get_scene_name(newSceneID)
	if(newSceneName == ""):
		return

	var oldSceneName = get_scene_name(currentGameScene)
	if(oldSceneName != ""):
		get_tree().get_root().remove_child(oldSceneName)
		oldSceneName.call_deferred("free")

	var newScene = load("res://Scenes/" + newSceneName + ".tscn").instance()
	get_tree().get_root().get_node("MainMenu").hide()
	get_tree().get_root().add_child(newScene)
	return newScene




func get_scene_name(sceneID):
	match(sceneID):
		GameScene.Lobby:
			return ""
		GameScene.ForestMap:
			return "ForestMap"
		_:
			return ""
