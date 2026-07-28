class_name PlayerController
extends CharacterBody3D

## 2017 Roblox-style Character Controller for Godot 4
## Supports physical collisions, gravity, jump, camera pitch/yaw, and mobile touch input.

@export var move_speed: float = 12.0
@export var jump_velocity: float = 14.0
@export var mouse_sensitivity: float = 0.005

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 25.0)
var input_vector: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Enable camera by default
	if camera_3d:
		camera_3d.make_current()

func _unhandled_input(event: InputEvent) -> void:
	# Mouse look support for desktop testing
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		apply_look_rotation(event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE)

func apply_look_rotation(delta: Vector2) -> void:
	# Rotate character body horizontally (Yaw)
	rotate_y(-delta.x * mouse_sensitivity)
	
	# Pitch camera vertically
	if camera_pivot:
		camera_pivot.rotate_x(-delta.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Process input direction (Keyboard or Virtual Joystick)
	var move_dir := Vector3.ZERO
	if input_vector != Vector2.ZERO:
		var forward = -transform.basis.z
		var right = transform.basis.x
		# Keep movement strictly horizontal
		forward.y = 0.0
		right.y = 0.0
		forward = forward.normalized()
		right = right.normalized()
		
		move_dir = (forward * input_vector.y + right * input_vector.x).normalized()
	else:
		var keyboard_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if keyboard_dir != Vector2.ZERO:
			var forward = -transform.basis.z
			var right = transform.basis.x
			forward.y = 0.0
			right.y = 0.0
			move_dir = (-forward * keyboard_dir.y + right * keyboard_dir.x).normalized()

	if move_dir != Vector3.ZERO:
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0, move_speed * 8.0 * delta)

	move_and_slide()

	# Void reset (Respawn if fallen off platform)
	if global_position.y < -100.0:
		global_position = Vector3(0, 10, 0)
		velocity = Vector3.ZERO

func request_jump() -> void:
	if is_on_floor():
		velocity.y = jump_velocity
