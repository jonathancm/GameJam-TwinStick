extends Node

enum GameScene{
	Start,
	Lobby,
	MainGame,
	TestEnviro
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




func _load_scene(newSceneID):
	var newSceneName = _get_scene_name(newSceneID)
	if(newSceneName == ""):
		return

	var oldSceneName = _get_scene_name(currentGameScene)
	if(oldSceneName != ""):
		get_tree().get_root().remove_child(oldSceneName)
		oldSceneName.call_deferred("free")

	var newScene = load("res://Scenes/" + newSceneName + ".tscn").instance()
	get_tree().get_root().get_node("Lobby").hide()
	get_tree().get_root().add_child(newScene)




func _get_scene_name(sceneID):
	match(sceneID):
		GameScene.Lobby:
			return ""
		GameScene.MainGame:
			return "MainGame"
		GameScene.TestEnviro:
			return "TestEnviro"
		_:
			return ""
