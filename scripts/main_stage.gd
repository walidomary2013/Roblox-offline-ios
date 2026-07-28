extends Node3D

## Main Stage Manager for Roblox 2017 Map Viewer

@export var map_path: String = "res://maps/sample_2017_place.rbxl"

@onready var map_root: Node3D = $MapRoot
@onready var player: PlayerController = $PlayerCharacter
@onready var joystick_hud: VirtualJoystickHUD = $CanvasLayer/VirtualJoystick
@onready var status_label: Label = $CanvasLayer/DebugPanel/StatusLabel

var parser: RBXLParser

func _ready() -> void:
	parser = RBXLParser.new()
	load_map(map_path)

func load_map(path: String) -> void:
	if status_label:
		status_label.text = "Loading Roblox Map: " + path.get_file()
		
	# Clear existing map nodes if re-loading
	for child in map_root.get_children():
		child.queue_free()

	# Parse 2017 .rbxl XML map
	var spawns: Array[Vector3] = parser.parse_rbxl_file(path, map_root)
	
	# Determine spawn position
	var target_spawn := Vector3(0.0, 10.0, 0.0)
	if spawns.size() > 0:
		target_spawn = spawns[0]
		print("[MainStage] Spawning player at SpawnLocation: ", target_spawn)
	else:
		print("[MainStage] No SpawnLocation found, spawning at default origin: ", target_spawn)

	# Position player character
	if player:
		player.global_position = target_spawn
		player.velocity = Vector3.ZERO
		
	# Hook HUD touch controls to player
	if joystick_hud and player:
		joystick_hud.set_player(player)

	if status_label:
		status_label.text = "Map Loaded | Parts: %d | Spawns: %d" % [parser.part_count, spawns.size()]
