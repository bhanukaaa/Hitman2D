extends Node2D

@onready var animationPlayer: AnimationPlayer = $'AnimationPlayer'

var closed : bool = true

func groupedInteraction() -> void:
	if closed:
		animationPlayer.play("open")
	else:
		animationPlayer.play("close")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	closed = not closed
