class_name RobloxScriptEngine
extends RefCounted

## 2017 Roblox Script & Interaction Runtime Engine for Godot 4
## Executes Roblox Lua scripts, Touched events, ClickDetectors, and Part property updates.

signal script_output(message: String)

var map_root_node: Node3D
var active_scripts: Array[Dictionary] = []

func initialize_script_engine(map_root: Node3D) -> void:
	map_root_node = map_root
	active_scripts.clear()
	print("[RobloxScriptEngine] Initialized Roblox Script Runtime Engine.")

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

	# Execute basic print commands
	var lines := source.split("\n")
	for line in lines:
		var trimmed := line.strip_edges()
		if trimmed.begins_with("print(") and trimmed.ends_with(")"):
			var msg := trimmed.substr(6, trimmed.length() - 7).trim_prefix('"').trim_suffix('"')
			print("[RobloxScript: %s] %s" % [script_entry.name, msg])
			script_output.emit(msg)
		elif "Touched:Connect" in trimmed or "Touched:connect" in trimmed:
			_hook_touched_event(target, script_entry.name)

func _hook_touched_event(target_part: Node3D, script_name: String) -> void:
	if target_part is Area3D:
		target_part.body_entered.connect(func(body):
			print("[RobloxScript: %s] Touched event triggered by %s!" % [script_name, body.name])
		)
	elif target_part is StaticBody3D:
		var area := Area3D.new()
		area.name = "TouchArea"
		var col := CollisionShape3D.new()
		col.shape = BoxShape3D.new()
		area.add_child(col)
		target_part.add_child(area)
		area.body_entered.connect(func(body):
			print("[RobloxScript: %s] Touched event triggered by %s!" % [script_name, body.name])
		)
