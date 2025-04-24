extends CharacterBody2D


const SPEED: int = 300
const ACCELERATION: int = 250
const DECELERATION: int = 500
const ROTATION_SPEED: int = 10


func _physics_process(delta: float) -> void:
	var inputV: Vector2 = Vector2( 
		Input.get_axis("moveLeft", "moveRight"),
		Input.get_axis("moveUp", "moveDown")
	).normalized()

	if inputV:
		velocity = velocity.move_toward(
			inputV * SPEED, ACCELERATION * delta
		)
	else:
		velocity = velocity.move_toward(
			inputV * 0, DECELERATION * delta
		)

	rotation = rotate_toward(
		rotation,
		transform.y.angle_to_point( # relative mouse position
			get_global_mouse_position() - global_position
		),
		ROTATION_SPEED * delta
	)

	move_and_slide()
