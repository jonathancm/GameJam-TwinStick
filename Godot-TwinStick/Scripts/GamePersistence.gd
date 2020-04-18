extends Spatial

enum GameScene{
	Start,
	MainMenu,
	HostGame,
	JoinGame,
	MainGame
   }

#
# Internal Variables
#
var currentGameScene = GameScene.Start




#
# Node functions
#
func _ready():
	_load_scene(GameScene.MainMenu)




func _load_scene(newSceneID):
	var newSceneName = _get_scene_name(newSceneID)
	if(newSceneName == ""):
		return

	_unload_current_scene()
	var newSceneResource = load("res://Scenes/" + newSceneName + ".tscn")
	var newScene = newSceneResource.instance()
	add_child(newScene)




func _unload_current_scene():
	var oldSceneName = _get_scene_name(currentGameScene)
	if(oldSceneName == ""):
		return

	remove_child(oldSceneName)
	oldSceneName.call_deferred("free")




func _get_scene_name(sceneID):
	match(sceneID):
		GameScene.MainMenu:
			return "Scene_MainMenu"
		GameScene.HostGame:
			return "Scene_HostGame"
		GameScene.JoinGame:
			return "Scene_JoinGame"
		GameScene.MainGame:
			return "Scene_MainGame"
		_:
			return ""
