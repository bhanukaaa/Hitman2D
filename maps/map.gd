extends Node

@export var enemyContainer: Node2D
@onready var timer: Timer = $Timer

func _on_enemies_child_exiting_tree(_node: Node) -> void:
	if enemyContainer.get_child_count() == 1:
		print("won")
		timer.start()


func _on_timer_timeout() -> void:
	GameManager.toMainMenu()
