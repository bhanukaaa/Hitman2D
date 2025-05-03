extends Node

enum GAME_STATES {
	PLAYING,
	PAUSED
}


var currGameState: GAME_STATES = GAME_STATES.PLAYING


func pauseGame() -> void:
	currGameState = GAME_STATES.PAUSED


func resumeGame() -> void:
	currGameState = GAME_STATES.PLAYING


func isGamePaused() -> bool:
	return currGameState == GAME_STATES.PAUSED


func toMainMenu() -> void:
	get_tree().change_scene_to_file("res://menus/mainMenu.tscn")
	currGameState = GAME_STATES.PLAYING


func quitGame() -> void:
	get_tree().quit()