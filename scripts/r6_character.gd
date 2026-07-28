class_name R6Character
extends Node3D

## Roblox 2017 R6 Blocky Character Avatar & Limb Swing Animator
## Features Head, Torso, Left/Right Arm, Left/Right Leg with classic 2017 Roblox colors & animations.

@export var head_color: Color = Color(0.96, 0.80, 0.19)  # Bright Yellow #F5CD30
@export var torso_color: Color = Color(0.05, 0.41, 0.67) # Bright Blue #0D69AC
@export var arm_color: Color = Color(0.96, 0.80, 0.19)   # Bright Yellow #F5CD30
@export var leg_color: Color = Color(0.16, 0.50, 0.27)   # Bright Green #287F46

var head_mesh: MeshInstance3D
var torso_mesh: MeshInstance3D
var left_arm_mesh: MeshInstance3D
var right_arm_mesh: MeshInstance3D
var left_leg_mesh: MeshInstance3D
var right_leg_mesh: MeshInstance3D

var left_arm_pivot: Node3D
var right_arm_pivot: Node3D
var left_leg_pivot: Node3D
var right_leg_pivot: Node3D

var walk_time: float = 0.0

func _ready() -> void:
	build_r6_avatar()

func build_r6_avatar() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()

	# Scale factor: 1 Roblox Stud = 0.5 Godot meters
	# Total R6 Height = 5.0 studs = 2.5 Godot meters
	
	# 1. TORSO (2.0 x 2.0 x 1.0 studs -> 1.0 x 1.0 x 0.5 Godot m)
	torso_mesh = _create_block("Torso", Vector3(1.0, 1.0, 0.5), torso_color)
	torso_mesh.position = Vector3(0, 1.25, 0)
	add_child(torso_mesh)

	# 2. HEAD (1.2 x 1.2 x 1.2 studs -> 0.6 x 0.6 x 0.6 Godot m)
	head_mesh = _create_head("Head", Vector3(0.6, 0.6, 0.6), head_color)
	head_mesh.position = Vector3(0, 0.8, 0) # Relative to torso top
	torso_mesh.add_child(head_mesh)

	# 3. LEFT ARM (1.0 x 2.0 x 1.0 studs -> 0.5 x 1.0 x 0.5 Godot m)
	left_arm_pivot = Node3D.new()
	left_arm_pivot.name = "LeftArmPivot"
	left_arm_pivot.position = Vector3(-0.75, 0.5, 0) # Shoulder joint
	torso_mesh.add_child(left_arm_pivot)

	left_arm_mesh = _create_block("LeftArm", Vector3(0.5, 1.0, 0.5), arm_color)
	left_arm_mesh.position = Vector3(0, -0.5, 0)
	left_arm_pivot.add_child(left_arm_mesh)

	# 4. RIGHT ARM (1.0 x 2.0 x 1.0 studs -> 0.5 x 1.0 x 0.5 Godot m)
	right_arm_pivot = Node3D.new()
	right_arm_pivot.name = "RightArmPivot"
	right_arm_pivot.position = Vector3(0.75, 0.5, 0) # Shoulder joint
	torso_mesh.add_child(right_arm_pivot)

	right_arm_mesh = _create_block("RightArm", Vector3(0.5, 1.0, 0.5), arm_color)
	right_arm_mesh.position = Vector3(0, -0.5, 0)
	right_arm_pivot.add_child(right_arm_mesh)

	# 5. LEFT LEG (1.0 x 2.0 x 1.0 studs -> 0.5 x 1.0 x 0.5 Godot m)
	left_leg_pivot = Node3D.new()
	left_leg_pivot.name = "LeftLegPivot"
	left_leg_pivot.position = Vector3(-0.25, -0.5, 0) # Hip joint
	torso_mesh.add_child(left_leg_pivot)

	left_leg_mesh = _create_block("LeftLeg", Vector3(0.5, 1.0, 0.5), leg_color)
	left_leg_mesh.position = Vector3(0, -0.5, 0)
	left_leg_pivot.add_child(left_leg_mesh)

	# 6. RIGHT LEG (1.0 x 2.0 x 1.0 studs -> 0.5 x 1.0 x 0.5 Godot m)
	right_leg_pivot = Node3D.new()
	right_leg_pivot.name = "RightLegPivot"
	right_leg_pivot.position = Vector3(0.25, -0.5, 0) # Hip joint
	torso_mesh.add_child(right_leg_pivot)

	right_leg_mesh = _create_block("RightLeg", Vector3(0.5, 1.0, 0.5), leg_color)
	right_leg_mesh.position = Vector3(0, -0.5, 0)
	right_leg_pivot.add_child(right_leg_mesh)

func animate_movement(speed: float, is_on_floor: bool, delta: float) -> void:
	if not left_arm_pivot or not right_arm_pivot or not left_leg_pivot or not right_leg_pivot:
		return

	if not is_on_floor:
		# Classic Roblox R6 Jump Pose
		left_arm_pivot.rotation.x = deg_to_rad(-160)
		right_arm_pivot.rotation.x = deg_to_rad(-160)
		left_leg_pivot.rotation.x = deg_to_rad(30)
		right_leg_pivot.rotation.x = deg_to_rad(-30)
	elif speed > 0.1:
		# Classic R6 Walk Swing
		walk_time += delta * speed * 1.5
		var swing_angle = sin(walk_time) * deg_to_rad(45)
		
		left_arm_pivot.rotation.x = -swing_angle
		right_arm_pivot.rotation.x = swing_angle
		left_leg_pivot.rotation.x = swing_angle
		right_leg_pivot.rotation.x = -swing_angle
	else:
		# Idle Pose
		walk_time = 0.0
		left_arm_pivot.rotation.x = move_toward(left_arm_pivot.rotation.x, 0.0, delta * 8.0)
		right_arm_pivot.rotation.x = move_toward(right_arm_pivot.rotation.x, 0.0, delta * 8.0)
		left_leg_pivot.rotation.x = move_toward(left_leg_pivot.rotation.x, 0.0, delta * 8.0)
		right_leg_pivot.rotation.x = move_toward(right_leg_pivot.rotation.x, 0.0, delta * 8.0)

func _create_block(part_name: String, size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.4
	mi.material_override = mat

	return mi

func attach_jetpack_mesh() -> void:
	if not torso_mesh: return
	if torso_mesh.has_node("JetpackMesh"): return

	var jetpack := MeshInstance3D.new()
	jetpack.name = "JetpackMesh"
	
	# Create Jetpack dual thruster barrels mesh
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 1.2, 0.4)
	jetpack.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2) # Dark metallic grey
	mat.metallic = 0.8
	mat.roughness = 0.3
	jetpack.material_override = mat

	# Attach to back of torso
	jetpack.position = Vector3(0, 0, -0.45)
	torso_mesh.add_child(jetpack)

	# Left thruster flame nozzle
	var flame1 := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.0
	cyl.height = 0.4
	flame1.mesh = cyl

	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.5, 0.0) # Bright orange jet flame
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.6, 0.1)
	flame_mat.emission_energy_multiplier = 3.0
	flame1.material_override = flame_mat

	flame1.position = Vector3(-0.25, -0.7, 0)
	jetpack.add_child(flame1)

	# Right thruster flame nozzle
	var flame2 = flame1.duplicate()
	flame2.position = Vector3(0.25, -0.7, 0)
	jetpack.add_child(flame2)

	print("[R6Character] Jetpack 3D mesh attached to player back!")

