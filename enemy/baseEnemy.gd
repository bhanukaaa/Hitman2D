extends CharacterBody2D

@onready var wallDetectRayCast: RayCast2D = $WallDetectRayCast
@onready var hpBar: TextureProgressBar = $Static/HPBar
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var playerDetectRayCast: RayCast2D = $PlayerDetectRayCast
var playerReference: Node2D

enum states {
	IDLE, WANDER, AWARE, ENGAGE
}

const MAX_SPEED: int = 200
const STRAFE_SPEED: int = 100
const WANDER_ACCEL: int = 250
const ENGAGE_ACCEL: int = 500
const DECELERATION: int = 500
const ROTATION_SPEED: int = 7

var stateTimer: int = 10
var currState: states = states.IDLE
var currPOI: Vector2 = Vector2(0, 0)
var playerInArea: bool = false
var playerInFOV: bool = false
var strafeDirection: int = 1

var health: int = 100


# Initialization ========================

func _ready() -> void:
	hpBar.max_value = health
	hpBar.value = health


# Updaters ==============================

func _physics_process(delta: float) -> void:
	match currState:
		states.IDLE:
			velocity = velocity.move_toward(Vector2(0, 0), DECELERATION * delta)

			if stateTimer == 0:
				stateTimer = randi_range(100, 400)
				if randomPOI():
					currState = states.WANDER

		states.WANDER:
			velocity = velocity.move_toward(position.direction_to(currPOI) * MAX_SPEED, WANDER_ACCEL * delta)
			rotation = rotate_toward(rotation, position.angle_to_point(currPOI), ROTATION_SPEED * delta)

			if stateTimer == 0 or position == currPOI:
				stateTimer = randi_range(100, 400)
				currState = states.IDLE

		states.AWARE:
			velocity = velocity.move_toward(Vector2(0, 0), DECELERATION * delta)
			rotation = rotate_toward(rotation, position.angle_to_point(currPOI), ROTATION_SPEED * delta)

			if stateTimer == 0:
				stateTimer = randi_range(100, 400)
				currState = states.IDLE

		states.ENGAGE:
			if stateTimer == 0:
				stateTimer = 30
				strafeDirection *= -1
			var toPlayer: Vector2 = (currPOI - global_position).normalized()
			var perp: Vector2 = Vector2(-toPlayer.y, toPlayer.x)
			var moveDir: Vector2 = (toPlayer + perp * strafeDirection).normalized()
			var targetVelocity: Vector2 = moveDir * STRAFE_SPEED

			velocity = velocity.move_toward(targetVelocity, ENGAGE_ACCEL * delta)
			rotation = rotate_toward(rotation, position.angle_to_point(currPOI), ROTATION_SPEED * delta)
			if not playerInFOV:
				currState = states.AWARE
				stateTimer = 500

	stateTimer -= 1

	if playerInArea:
		checkFOV()

	move_and_slide()


func randomPOI() -> bool:
	var attempts: int = 3
	while attempts:
		attempts -= 1
		var newPOI: Vector2 = Vector2(
			randi_range(-250, 250), randi_range(-250, 250)
		) + position

		wallDetectRayCast.target_position = wallDetectRayCast.to_local(newPOI)
		wallDetectRayCast.force_raycast_update()

		if not wallDetectRayCast.is_colliding():
			currPOI = newPOI
			return true
	return false


func checkFOV() -> void:
	playerDetectRayCast.target_position = playerDetectRayCast.to_local(playerReference.position)
	playerDetectRayCast.force_raycast_update()

	if not playerDetectRayCast.is_colliding():
		playerInFOV = false
		return

	var collider: Node2D = playerDetectRayCast.get_collider()

	if not collider.is_in_group("player"):
		playerInFOV = false
		return

	# player in FOV
	currPOI = playerReference.position
	currState = states.ENGAGE
	playerInFOV = true


# Handlers ==============================

func attackReceiver(dmg: int) -> void:
	health -= dmg
	hpBar.value = health
	if health <= 0:
		deathHandler()


func deathHandler() -> void:
	var drop: Node2D = load("res://drops/ammoDrop.tscn").instantiate()
	drop.position = position
	drop.call("setCount", randi_range(1, 5))
	get_parent().add_child(drop)
	animationPlayer.play("death")


# Signals ===============================

func _on_player_detect_area_body_entered(body: Node2D) -> void:
	playerReference = body
	playerInArea = true


func _on_player_detect_area_body_exited(_body: Node2D) -> void:
	playerInArea = false
	playerInFOV = false
