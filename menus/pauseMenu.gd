extends Control


func _on_resume_pressed() -> void:
	GameManager.resumeGame()
	visible = false


func _on_main_menu_pressed() -> void:
	GameManager.toMainMenu()


func _on_quit_pressed() -> void:
	GameManager.quitGame()