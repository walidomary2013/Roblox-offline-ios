class_name MainStage
extends Node3D

## Main Stage Controller with Novetus Standalone Engine Integration

const NovetusLauncherScript = preload("res://scripts/novetus_launcher.gd")

@export var map_path: String = "res://REAL.rbxlx"
@export var map_root: Node3D
@export var player: CharacterBody3D
@export var map_option_button: OptionButton
@export var load_file_button: Button
@export var file_dialog: FileDialog
@export var joystick_hud: Control
@export var status_label: Label

var parser: RBXLParser
var novetus: RefCounted

const MAP_PRESETS: Array[Dictionary] = [
	{"name": "Work at a Pizza Place (2017)", "path": "res://REAL.rbxlx"},
	{"name": "David Baszucki - 8 Towers (2007)", "path": "res://maps/DavidBaszucki_8Towers_2007.rbxlx"},
	{"name": "Erik Cassel - Jetpack (2007)", "path": "res://maps/ErikCassel_Jetpack_2007.rbxlx"},
	{"name": "Shedletsky - Moon Mission (2007)", "path": "res://maps/Shedletsky_Moon_2007.rbxlx"},
	{"name": "Classic Crossroads (2017)", "path": "res://maps/crossroads_2017.rbxl"},
	{"name": "Obby & Playground", "path": "res://maps/sample_2017_place.rbxl"}
]

func _ready() -> void:
	parser = RBXLParser.new()
	novetus = NovetusLauncherScript.new()
	if novetus.has_signal("client_launched"):
		novetus.client_launched.connect(_on_novetus_client_launched)

	# Ensure map_root exists
	if not map_root:
		if has_node("MapRoot"):
			map_root = get_node("MapRoot")
		else:
			map_root = Node3D.new()
			map_root.name = "MapRoot"
			add_child(map_root)
	
	if map_option_button:
		map_option_button.clear()
		for preset in MAP_PRESETS:
			map_option_button.add_item(preset["name"])
		map_option_button.item_selected.connect(_on_map_selected)

	if load_file_button and file_dialog:
		load_file_button.pressed.connect(_on_open_file_dialog_pressed)
		file_dialog.file_selected.connect(_on_custom_file_selected)

	load_map(map_path)

func _on_map_selected(index: int) -> void:
	if index >= 0 and index < MAP_PRESETS.size():
		var selected_path: String = MAP_PRESETS[index]["path"]
		load_map(selected_path)

func _on_open_file_dialog_pressed() -> void:
	if file_dialog:
		file_dialog.popup_centered(Vector2i(800, 500))

func _on_custom_file_selected(path: String) -> void:
	load_map(path)

func load_map(path: String) -> void:
	map_path = path
	if status_label:
		status_label.text = "Map Loaded: " + path.get_file()

	# Ensure map_root is non-null
	if not map_root:
		if has_node("MapRoot"):
			map_root = get_node("MapRoot")
		else:
			map_root = Node3D.new()
			map_root.name = "MapRoot"
			add_child(map_root)
		
	for child in map_root.get_children():
		child.queue_free()

	var spawns: Array[Vector3] = parser.parse_rbxl_file(path, map_root)
	
	const RobloxEnvScript = preload("res://scripts/roblox_environment.gd")
	if not map_root.has_node("RobloxEnvironment"):
		var env_node = RobloxEnvScript.new()
		env_node.name = "RobloxEnvironment"
		map_root.add_child(env_node)

	var target_spawn := Vector3(0.0, 10.0, 0.0)
	if spawns.size() > 0:
		target_spawn = spawns[0]
		print("[MainStage] Spawning player at SpawnLocation: ", target_spawn)
	else:
		print("[MainStage] No SpawnLocation found, spawning at default origin: ", target_spawn)

	if player:
		player.global_position = target_spawn
		player.velocity = Vector3.ZERO
		
	if joystick_hud and player:
		if joystick_hud.has_signal("joystick_moved"):
			joystick_hud.joystick_moved.connect(func(dir: Vector2): player.input_vector = dir)
		if joystick_hud.has_signal("jump_pressed"):
			joystick_hud.jump_pressed.connect(func(): player.request_jump())

	# Launch Novetus Native Client Bridge
	if novetus and novetus.has_method("launch_standalone_roblox_client"):
		var v_enum_val = 3 # CLIENT_2017_LATE
		if "2007" in path:
			v_enum_val = 0 # CLIENT_2007_MARCH
		novetus.launch_standalone_roblox_client(path, v_enum_val)

func _on_novetus_client_launched(client_name: String, place_path: String) -> void:
	print("[MainStage] Novetus Engine Bridge active for: ", client_name, " | ", place_path)
