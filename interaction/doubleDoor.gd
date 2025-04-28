extends StaticBody2D

@onready var grouper: Node2D = $'..'

func interactionHandler() -> void:
	grouper.call("groupedInteraction")
