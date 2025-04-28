extends CharacterBody2D


@onready var interactionRayCast: RayCast2D = $InteractionRayCast

const SPEED: int = 300
const ACCELERATION: int = 300
const DECELERATION: int = 500
const ROTATION_SPEED: int = 10


const MAX_LIVE_AMMO: int = 15


var liveAmmo : int = 0
var reserveAmmo : int = 0
var health : int = 0


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

	if Input.is_action_just_pressed("interact"):
		interact()

	move_and_slide()


func interact() -> void:
	if not interactionRayCast.is_colliding():
		return

	var collider : Node2D = interactionRayCast.get_collider()
	collider.call("interactionHandler")
