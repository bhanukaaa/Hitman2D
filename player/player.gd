extends CharacterBody2D

@export var ammoLabel: Label
@export var healthBar: TextureProgressBar

@onready var interactionRayCast: RayCast2D = $InteractionRayCast
@onready var firingRayCast: RayCast2D = $FiringRayCast
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var firingLine: Line2D = $FiringRayCast/FiringLine
@onready var pickupArea: Area2D = $PickupArea
@onready var audioListener: AudioListener2D = $AudioListener

const MAX_SPEED: int = 300
const ACCELERATION: int = 1000
const DECELERATION: int = 500
const ROTATION_SPEED: int = 8
const MAX_LIVE_AMMO: int = 15

const FOOTSTEP_SPEED_THRESHOLD: int = 200

var liveAmmo: int = MAX_LIVE_AMMO
var reserveAmmo: int = MAX_LIVE_AMMO * 2
var health: int = 100
var shootCD: bool = false


# Initialization ========================

func _ready() -> void:
	assert(ammoLabel != null, "Player Export Variable AmmoLabel - Not Set")
	assert(healthBar != null, "Player Export Variable HealthBar - Not Set")
	updateAmmoLabel()


# Updaters ==============================

func _physics_process(delta: float) -> void:
	if GameManager.isGamePaused():
		return

	# movement
	var inputV: Vector2 = Vector2(
		Input.get_axis("moveLeft", "moveRight"),
		Input.get_axis("moveUp", "moveDown")
	).normalized()

	if inputV:
		velocity = velocity.move_toward(
			inputV * MAX_SPEED, ACCELERATION * delta
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
	
	if Input.is_action_just_pressed("reload"):
		reload()


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
		reload()
		return

	animationPlayer.play("shoot")
	shootCD = true

	liveAmmo -= 1
	updateAmmoLabel()

	if not firingRayCast.is_colliding():
		return
	var collider: Node2D = firingRayCast.get_collider()

	if not collider.is_in_group("enemy"):
		return

	var hitDistance: int = int(firingRayCast.global_position.distance_to(
		firingRayCast.get_collision_point()
	))

	@warning_ignore("integer_division")
	collider.call("attackReceiver", max(0, 100 - 10 * (max(0, hitDistance - 200) / 100)))


func reload() -> void:
	if liveAmmo == MAX_LIVE_AMMO:
		return
	
	if reserveAmmo == 0:
		return

	reserveAmmo -= MAX_LIVE_AMMO - liveAmmo
	liveAmmo = MAX_LIVE_AMMO
	animationPlayer.play("reload")
	shootCD = true


# Handlers ==============================

func attackReceiver(dmg: int) -> void:
	health -= dmg
	updateHealthBar()
	if health <= 0:
		deathHandler()


func deathHandler() -> void:
	GameManager.toMainMenu()

# Signals ===============================

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	shootCD = false
	updateAmmoLabel()


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


func updateHealthBar() -> void:
	healthBar.value = health


func updateFiringLine() -> void:
	if firingRayCast.is_colliding():
		var hitDistance: float = firingRayCast.global_position.distance_to(
			firingRayCast.get_collision_point()
		)
		firingLine.points[1].x = hitDistance
	else:
		firingLine.points[1].x = 1000
