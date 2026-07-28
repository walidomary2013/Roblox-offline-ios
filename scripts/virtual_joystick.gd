class_name VirtualJoystickHUD
extends Control

## Touch Virtual Joystick and Camera Look Controller for iOS / Mobile Devices

@export var joystick_radius: float = 80.0
@export var knob_radius: float = 35.0

var move_touch_index: int = -1
var look_touch_index: int = -1

var joystick_center: Vector2 = Vector2.ZERO
var joystick_pos: Vector2 = Vector2.ZERO

var player_ref: PlayerController = null
var output_vector: Vector2 = Vector2.ZERO

@onready var jump_button: Button = $JumpButton

func _ready() -> void:
	# Ensure Control expands across screen
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	if jump_button:
		jump_button.pressed.connect(_on_jump_pressed)

func set_player(player: PlayerController) -> void:
	player_ref = player

func _on_jump_pressed() -> void:
	if player_ref:
		player_ref.request_jump()

func _input(event: InputEvent) -> void:
	var screen_width = get_viewport_rect().size.x

	if event is InputEventScreenTouch:
		if event.pressed:
			# Left side of screen -> Joystick touch
			if event.position.x < screen_width * 0.5 and move_touch_index == -1:
				move_touch_index = event.index
				joystick_center = event.position
				joystick_pos = event.position
				queue_redraw()
			# Right side of screen -> Camera look touch (if not clicking jump button)
			elif event.position.x >= screen_width * 0.5 and look_touch_index == -1:
				if jump_button and not jump_button.get_global_rect().has_point(event.position):
					look_touch_index = event.index
		else:
			if event.index == move_touch_index:
				move_touch_index = -1
				output_vector = Vector2.ZERO
				if player_ref:
					player_ref.input_vector = Vector2.ZERO
				queue_redraw()
			elif event.index == look_touch_index:
				look_touch_index = -1

	elif event is InputEventScreenDrag:
		if event.index == move_touch_index:
			var drag_offset = event.position - joystick_center
			if drag_offset.length() > joystick_radius:
				drag_offset = drag_offset.normalized() * joystick_radius
			joystick_pos = joystick_center + drag_offset
			
			output_vector = drag_offset / joystick_radius
			# Invert Y for forward direction mapping (Y up = move forward)
			output_vector.y = -output_vector.y
			
			if player_ref:
				player_ref.input_vector = output_vector
			queue_redraw()
			
		elif event.index == look_touch_index:
			if player_ref:
				player_ref.apply_look_rotation(event.relative * 0.5)

func _draw() -> void:
	if move_touch_index != -1:
		# Draw translucent joystick outer ring
		draw_circle(joystick_center, joystick_radius, Color(1, 1, 1, 0.25))
		draw_arc(joystick_center, joystick_radius, 0, TAU, 32, Color(1, 1, 1, 0.6), 3.0)
		
		# Draw inner knob
		draw_circle(joystick_pos, knob_radius, Color(0.2, 0.6, 1.0, 0.8))
