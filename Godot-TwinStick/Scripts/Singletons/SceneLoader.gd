extends Node

enum GameScene{
	#Start,
	MainMenu,
	ForestMap,
   }

#
# Internal Variables
#
var currentGameScene = GameScene.MainMenu


func load_scene(newSceneID):
	var newSceneName = get_scene_name(newSceneID)
	if(newSceneName == ""):
		return

	var oldSceneName = get_scene_name(currentGameScene)
	if(oldSceneName != ""):
		var oldScene = get_tree().get_root().get_node(oldSceneName)
		get_tree().get_root().remove_child(oldScene)
		oldScene.call_deferred("free")

	var newScene = load("res://Scenes/" + newSceneName + ".tscn").instance()
	get_tree().get_root().add_child(newScene)
	currentGameScene = newSceneID
	return newScene


func get_scene_name(sceneID):
	match(sceneID):
		GameScene.MainMenu:
			return "MainMenu"
		GameScene.ForestMap:
			return "ForestMap"
		_:
			return ""
