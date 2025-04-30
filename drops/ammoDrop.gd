extends StaticBody2D

var ammoCount : int = 5


func setCount(val : int) -> void:
	ammoCount = val


func pickupHandler(caller : Node2D) -> void:
	caller.call("addAmmo", ammoCount)
	queue_free()