extends Node3D

## Main Stage Manager for Roblox 2017 Map Viewer

@export var map_path: String = "res://maps/crossroads_2017.rbxl"

@onready var map_root: Node3D = $MapRoot
@onready var player: PlayerController = $PlayerCharacter
@onready var joystick_hud: VirtualJoystickHUD = $CanvasLayer/VirtualJoystick
@onready var status_label: Label = $CanvasLayer/DebugPanel/VBoxContainer/StatusLabel
@onready var map_option_button: OptionButton = $CanvasLayer/DebugPanel/VBoxContainer/HBoxContainer/MapOptionButton
@onready var load_file_button: Button = $CanvasLayer/DebugPanel/VBoxContainer/HBoxContainer/LoadFileButton
@onready var file_dialog: FileDialog = $CanvasLayer/FileDialog

var parser: RBXLParser

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
	
	# Setup Map Selection OptionButton UI
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
	if status_label:
		status_label.text = "Loading Roblox Map: " + path.get_file()
		
	# Clear existing 3D map nodes
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
		status_label.text = "Map Loaded: %s | Parts: %d | Spawns: %d" % [path.get_file(), parser.part_count, spawns.size()]
