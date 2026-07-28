class_name PlayerController
extends CharacterBody3D

## 2017 Roblox-style R6 Character Controller with Jetpack Flight Engine
## Supports physical collisions, WASD / Arrow keys, Jump, Jetpack flight, R6 animations, and camera control.

@export var move_speed: float = 12.0
@export var jump_velocity: float = 14.0
@export var jetpack_thrust_power: float = 22.0
@export var mouse_sensitivity: float = 0.005

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D

var r6_avatar: R6Character
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 25.0)
var input_vector: Vector2 = Vector2.ZERO

var has_jetpack: bool = false
var is_jetpacking: bool = false

func _ready() -> void:
	if camera_3d:
		camera_3d.make_current()

	if has_node("MeshInstance3D"):
		get_node("MeshInstance3D").queue_free()

	r6_avatar = R6Character.new()
	r6_avatar.name = "R6Avatar"
	add_child(r6_avatar)
	
	# Equip Jetpack by default for testing flight!
	equip_jetpack_tool()

func equip_jetpack_tool() -> void:
	has_jetpack = true
	if r6_avatar and r6_avatar.has_method("attach_jetpack_mesh"):
		r6_avatar.attach_jetpack_mesh()
	print("[PlayerController] Jetpack equipped! Press SPACEBAR or W/A/S/D to move & fly!")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		apply_look_rotation(event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE)

func apply_look_rotation(delta: Vector2) -> void:
	rotate_y(-delta.x * mouse_sensitivity)
	if camera_pivot:
		camera_pivot.rotate_x(-delta.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	# Calculate input vector combining WASD, Arrow keys, and Virtual Joystick
	var move_x := 0.0
	var move_z := 0.0

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_z += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_x += 1.0

	if input_vector != Vector2.ZERO:
		move_x = input_vector.x
		move_z = input_vector.y

	var move_dir := Vector3.ZERO
	if move_x != 0.0 or move_z != 0.0:
		var forward = -transform.basis.z
		var right = transform.basis.x
		forward.y = 0.0
		right.y = 0.0
		forward = forward.normalized()
		right = right.normalized()
		move_dir = (forward * move_z + right * move_x).normalized()

	if move_dir != Vector3.ZERO:
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0, move_speed * 8.0 * delta)

	# Jump / Jetpack Flight Logic (SPACEBAR or JUMP button)
	var space_pressed := Input.is_key_pressed(KEY_SPACE) or Input.is_action_pressed("ui_accept")
	
	if space_pressed:
		if has_jetpack:
			is_jetpacking = true
			velocity.y = move_toward(velocity.y, jetpack_thrust_power, jetpack_thrust_power * 4.0 * delta)
		elif is_on_floor():
			velocity.y = jump_velocity
	else:
		is_jetpacking = false
		if not is_on_floor():
			velocity.y -= gravity * delta

	move_and_slide()

	# Animate R6 Avatar (Limb swings & Jumping/Flying poses)
	if r6_avatar:
		var horizontal_speed = Vector2(velocity.x, velocity.z).length()
		r6_avatar.animate_movement(horizontal_speed, is_on_floor(), delta)

	# Void reset (Respawn if fallen off platform)
	if global_position.y < -100.0:
		global_position = Vector3(0, 10, 0)
		velocity = Vector3.ZERO

func request_jump() -> void:
	if has_jetpack:
		velocity.y = jetpack_thrust_power
	elif is_on_floor():
		velocity.y = jump_velocity
