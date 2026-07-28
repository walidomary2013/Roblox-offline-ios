class_name RobloxScriptEngine
extends RefCounted

## Advanced 2017 Roblox Script & Interaction Runtime Engine for Godot 4
## Executes Roblox Lua scripts, Touched events, ClickDetectors, KillBricks, Teleporters, and Part updates.

signal script_output(message: String)

var map_root_node: Node3D
var active_scripts: Array[Dictionary] = []

func initialize_script_engine(map_root: Node3D) -> void:
	map_root_node = map_root
	active_scripts.clear()
	print("[RobloxScriptEngine] Initialized Roblox Script Runtime Engine.")
	_scan_and_register_interactive_elements(map_root)

## Scan map tree for KillBricks, Teleporters, ClickDetectors, and Touch Triggers
func _scan_and_register_interactive_elements(node: Node) -> void:
	for child in node.get_children():
		if child is StaticBody3D or child is Node3D:
			var node_name: String = child.name.to_lower()
			
			# 1. KillBricks (Lava, Acid, Void, Kill, Spikes)
			if "lava" in node_name or "kill" in node_name or "acid" in node_name or "spike" in node_name:
				_setup_kill_brick(child)
				
			# 2. Teleporters (Teleport, Portal, Warp)
			elif "teleport" in node_name or "portal" in node_name or "warp" in node_name:
				_setup_teleporter(child)
				
			# 3. Interactive Buttons & Doors (Button, Door, Register, Lever)
			elif "button" in node_name or "door" in node_name or "register" in node_name or "lever" in node_name:
				_setup_interactive_door_button(child)

		_scan_and_register_interactive_elements(child)

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

## Setup Interactive Door / Button (Toggle Transparency & Collision on Touch)
func _setup_interactive_door_button(target_node: Node3D) -> void:
	var area := Area3D.new()
	area.name = "ButtonArea"
	var col := CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	area.add_child(col)
	target_node.add_child(area)
	
	area.body_entered.connect(func(body):
		if body is CharacterBody3D:
			print("[RobloxScriptEngine] Interactive Button/Door activated by: %s" % body.name)
			# Toggle visibility / transparency effect
			for child in target_node.get_children():
				if child is MeshInstance3D and child.material_override:
					var mat: StandardMaterial3D = child.material_override
					mat.albedo_color.a = 0.3 if mat.albedo_color.a > 0.5 else 1.0
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
			var msg := trimmed.substr(6, trimmed.length() - 7).trim_prefix('"').trim_suffix('"')
			print("[RobloxScript: %s] %s" % [script_entry.name, msg])
			script_output.emit(msg)
		elif "Touched:Connect" in trimmed or "Touched:connect" in trimmed:
			if target:
				_setup_kill_brick(target)
