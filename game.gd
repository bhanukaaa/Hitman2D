extends Node2D

@export var playerReference : CharacterBody2D
@export var mapReference : Node
@export var pauseMenu : Control


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") and not GameManager.isGamePaused():
		pauseMenu.visible = true
		GameManager.pauseGame()
