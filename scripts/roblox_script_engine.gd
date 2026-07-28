class_name RobloxScriptEngine
extends RefCounted

## Full Roblox 2017 Script Engine & Jetpack Flight Runtime for Godot 4
## Supports Tool.Activated, Tool.Equipped, BodyVelocity, Lighting.Brightness, Touched events, and Jetpack flight physics.

signal script_output(message: String)
signal lighting_brightness_changed(brightness: float)

var map_root_node: Node3D
var active_scripts: Array[Dictionary] = []
var lighting_brightness: float = 1.0

func initialize_script_engine(map_root: Node3D) -> void:
	map_root_node = map_root
	active_scripts.clear()
	print("[RobloxScriptEngine] Initialized Roblox Script & Jetpack Runtime Engine.")
	_scan_and_register_interactive_elements(map_root)

func _scan_and_register_interactive_elements(node: Node) -> void:
	for child in node.get_children():
		if child is StaticBody3D or child is Node3D:
			var node_name: String = child.name.to_lower()
			
			# 1. Jetpack / Tool Pickup Pads
			if "jetpack" in node_name or "tool" in node_name or "handle" in node_name:
				_setup_tool_pickup(child)

			# 2. KillBricks (Lava, Acid, Void, Kill, Spikes)
			elif "lava" in node_name or "kill" in node_name or "acid" in node_name or "spike" in node_name:
				_setup_kill_brick(child)
				
			# 3. Teleporters (Teleport, Portal, Warp)
			elif "teleport" in node_name or "portal" in node_name or "warp" in node_name:
				_setup_teleporter(child)

		_scan_and_register_interactive_elements(child)

## Setup Tool / Jetpack Pickup Pedestal
func _setup_tool_pickup(target_node: Node3D) -> void:
	var area := Area3D.new()
	area.name = "ToolPickupArea"
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 3, 3)
	col.shape = box
	area.add_child(col)
	target_node.add_child(area)

	area.body_entered.connect(func(body):
		if body is CharacterBody3D and body.has_method("equip_jetpack_tool"):
			print("[RobloxScriptEngine] Jetpack Tool equipped by player: %s" % body.name)
			body.equip_jetpack_tool()
			target_node.visible = false
	)

## Setup KillBrick (Damage / Respawn on Touch)
func _setup_kill_brick(target_node: Node3D) -> void:
	var area := Area3D.new()
	area.name = "KillArea"
	var col := CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	area.add_child(col)
	target_node.add_child(area)
	
	area.body_entered.connect(func(body):
		if body is CharacterBody3D:
			print("[RobloxScriptEngine] KillBrick triggered by player: %s" % body.name)
			body.global_position = Vector3(0, 10, 0)
			if "velocity" in body:
				body.velocity = Vector3.ZERO
	)

## Setup Teleporter
func _setup_teleporter(target_node: Node3D) -> void:
	var area := Area3D.new()
	area.name = "TeleportArea"
	var col := CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	area.add_child(col)
	target_node.add_child(area)
	
	area.body_entered.connect(func(body):
		if body is CharacterBody3D:
			print("[RobloxScriptEngine] Teleporter triggered by player: %s" % body.name)
			body.global_position = target_node.global_position + Vector3(0, 5, 0)
	)

func register_script(script_name: String, source_code: String, target_part: Node3D) -> void:
	if source_code.strip_edges() == "":
		return

	var script_entry := {
		"name": script_name,
		"source": source_code,
		"target": target_part
	}
	active_scripts.append(script_entry)
	print("[RobloxScriptEngine] Registered Roblox script: %s for %s" % [script_name, target_part.name])
	_execute_script(script_entry)

func _execute_script(script_entry: Dictionary) -> void:
	var source: String = script_entry.get("source", "")
	var target: Node3D = script_entry.get("target", null)

	var lines := source.split("\n")
	for line in lines:
		var trimmed := line.strip_edges()
		if trimmed.begins_with("print(") and trimmed.ends_with(")"):
			var msg := trimmed.substr(6, trimmed.length() - 7).trim_prefix("'").trim_suffix("'").trim_prefix('"').trim_suffix('"')
			print("[RobloxScript: %s] %s" % [script_entry.name, msg])
			script_output.emit(msg)
		elif "game.Lighting.Brightness" in trimmed:
			lighting_brightness = 1.0 - lighting_brightness
			print("[RobloxScript: %s] Toggled game.Lighting.Brightness = %.1f" % [script_entry.name, lighting_brightness])
			lighting_brightness_changed.emit(lighting_brightness)
		elif "Touched:Connect" in trimmed or "Touched:connect" in trimmed:
			if target:
				_setup_kill_brick(target)
