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
const APPROACH_SPEED: int = 30
const STRAFE_SPEED: int = 100
const WANDER_ACCEL: int = 250
const ENGAGE_ACCEL: int = 500
const DECELERATION: int = 500
const ROTATION_SPEED: int = 7
const SHOOT_COOLDOWN: int = 50

var stateTimer: int = 10
var currState: states = states.IDLE
var currPOI: Vector2 = Vector2(0, 0)
var playerInArea: bool = false
var playerInFOV: bool = false

var strafeDirection: int = 1
var aimingAtTimer: int = SHOOT_COOLDOWN

var health: int = 100
var alive: bool = true


# Initialization ========================

func _ready() -> void:
	hpBar.max_value = health
	hpBar.value = health


# Updaters ==============================

func _physics_process(delta: float) -> void:
	if GameManager.isGamePaused():
		return

	if not alive:
		return

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
			rotation = rotate_toward(rotation, position.angle_to_point(currPOI), ROTATION_SPEED * delta)
			var toPlayer: Vector2 = (currPOI - global_position).normalized()
			velocity = velocity.move_toward(toPlayer * APPROACH_SPEED, ENGAGE_ACCEL * delta)

			if stateTimer == 0:
				stateTimer = randi_range(100, 400)
				currState = states.IDLE

		states.ENGAGE:
			if stateTimer == 0:
				stateTimer = 30
				strafeDirection *= -1

			var toPlayer: Vector2 = (currPOI - global_position).normalized()
			var perp: Vector2 = Vector2(-toPlayer.y, toPlayer.x)
			if position.distance_to(currPOI) < 300:
				toPlayer = Vector2(0, 0) # keep distance from target

			var moveDir: Vector2 = (toPlayer + perp * strafeDirection).normalized()
			var targetVelocity: Vector2 = moveDir * STRAFE_SPEED
			velocity = velocity.move_toward(targetVelocity, ENGAGE_ACCEL * delta)

			var angleToPlayer: float = position.angle_to_point(currPOI)
			if abs(angle_difference(rotation, angleToPlayer)) <= 0.01:
				aimingAtTimer -= 1
			else:
				aimingAtTimer = SHOOT_COOLDOWN

			rotation = rotate_toward(rotation, angleToPlayer, ROTATION_SPEED * delta)

			if aimingAtTimer == 0:
				animationPlayer.play("shoot")
				aimingAtTimer = SHOOT_COOLDOWN

			if not playerInFOV:
				currState = states.AWARE
				stateTimer = 500

	stateTimer -= 1

	if playerInArea:
		checkFOV()

	move_and_slide()


func shoot() -> void:
	if randi_range(0, 1) == 0:
		playerReference.attackReceiver(20)


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
	alive = false
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
