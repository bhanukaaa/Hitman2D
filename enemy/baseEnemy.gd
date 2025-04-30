extends CharacterBody2D

@onready var wallDetectRayCast: RayCast2D = $WallDetectRayCast

enum states {
	IDLE, WANDER
}

const MAX_SPEED : int = 200
const WANDER_ACCEL : int = 250
const DECELERATION : int = 500
const ROTATION_SPEED: int = 7

var currState : states = states.IDLE
var stateTimer : int = 100

var currPOI : Vector2 = Vector2(0,0)

var health : int = 100


func _physics_process(delta: float) -> void:
	if currState == states.IDLE:
		velocity = velocity.move_toward(Vector2(0,0), DECELERATION * delta)
		# add scanning for idle
		if stateTimer == 0:
			stateTimer = randi_range(100, 400)
			if updatePOI():
				currState = states.WANDER
	else:
		velocity = velocity.move_toward(position.direction_to(currPOI) * MAX_SPEED, WANDER_ACCEL * delta)
		rotation = rotate_toward(rotation, position.angle_to_point(currPOI), ROTATION_SPEED * delta)
		if stateTimer == 0 or velocity.length() == 0:
			stateTimer = randi_range(100, 400)
			currState = states.IDLE
	stateTimer -= 1

	move_and_slide()


func updatePOI() -> bool:
	var attempts : int = 3
	while attempts:
		attempts -= 1
		var newPOI : Vector2 = Vector2(
			randi_range(-250, 250), randi_range(-250, 250)
		) + position

		wallDetectRayCast.target_position = wallDetectRayCast.to_local(newPOI)
		wallDetectRayCast.force_raycast_update()

		if not wallDetectRayCast.is_colliding():
			currPOI = newPOI
			return true
	return false


func attackReceiver(dmg : int) -> void:
	health -= dmg
	if health <= 0:
		deathHandler()


func deathHandler() -> void:
	var drop: Node2D = load("res://drops/ammoDrop.tscn").instantiate()
	drop.position = position
	drop.call("setCount", randi_range(1, 5))
	get_parent().add_child(drop)
	queue_free()
