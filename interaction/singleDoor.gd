extends StaticBody2D

@onready var animationPlayer: AnimationPlayer = $AnimationPlayer

var closed : bool = true

func interactionHandler() -> void:
	if closed:
		animationPlayer.play("open")
	else:
		animationPlayer.play("close")



func _on_animation_player_animation_finished(_anim_name:StringName) -> void:
	closed = not closed