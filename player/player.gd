extends CharacterBody2D

@export var ammoLabel: Label

@onready var interactionRayCast: RayCast2D = $InteractionRayCast
@onready var firingRayCast: RayCast2D = $FiringRayCast
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var firingLine: Line2D = $FiringRayCast/FiringLine
@onready var pickupArea: Area2D = $PickupArea

const SPEED: int = 300
const ACCELERATION: int = 1000
const DECELERATION: int = 500
const ROTATION_SPEED: int = 8
const MAX_LIVE_AMMO: int = 15


const FOOTSTEP_SPEED_THRESHOLD: int = 200


var liveAmmo: int = MAX_LIVE_AMMO
var reserveAmmo: int = MAX_LIVE_AMMO * 3
var health: int = 100
var shootCD: bool = false


# Updaters ==============================

func _ready() -> void:
	updateAmmoLabel()


func _physics_process(delta: float) -> void:
	# movement
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

	# action triggers
	if Input.is_action_just_pressed("interact"):
		interact()

	if Input.is_action_just_pressed("primaryFire"):
		shoot()


	updateFiringLine()
	move_and_slide()


# Actions ===============================

func interact() -> void:
	if not interactionRayCast.is_colliding():
		return

	var collider: Node2D = interactionRayCast.get_collider()
	collider.call("interactionHandler")


func shoot() -> void:
	if shootCD:
		return

	if not liveAmmo:
		if not reserveAmmo:
			return
		animationPlayer.play("reload")
		shootCD = true
		reserveAmmo -= MAX_LIVE_AMMO
		liveAmmo = MAX_LIVE_AMMO
		updateAmmoLabel()
		return

	animationPlayer.play("shoot")
	shootCD = true

	liveAmmo -= 1
	updateAmmoLabel()

	if not firingRayCast.is_colliding():
		return
	var collider: Node2D = firingRayCast.get_collider()

	if collider.is_in_group("enemy"):
		collider.call("attackReceiver", 100)


# Handlers ==============================

func attackReceiver(dmg: int) -> void:
	health -= dmg
	if health <= 0:
		deathHandler()


func deathHandler() -> void:
	pass


# Signals ===============================

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	shootCD = false


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("pickups"):
		return # kinda redundant coz only pickups layer 4

	body.call("pickupHandler", self)


# Helpers ===============================

func addAmmo(count: int) -> void:
	reserveAmmo += count
	updateAmmoLabel()


func updateAmmoLabel() -> void:
	ammoLabel.text = str(liveAmmo) + " / " + str(reserveAmmo)


func updateFiringLine() -> void:
	if firingRayCast.is_colliding():
		var hitDistance: float = firingRayCast.global_position.distance_to(
			firingRayCast.get_collision_point()
		)
		firingLine.points[1].x = hitDistance
	else:
		firingLine.points[1].x = 1000
