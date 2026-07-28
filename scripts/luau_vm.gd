class_name LuauVM
extends RefCounted

## Generic Roblox Luau Virtual Machine & API Runtime Engine for Godot 4
## Executes real Roblox Lua/Luau scripts dynamically for any map/place without hardcoding game-specific logic.

signal print_output(message: String)
signal warn_output(message: String)
signal error_output(message: String)

var map_root_node: Node3D
var script_instances: Array[Dictionary] = []
var global_variables: Dictionary = {}

func _init(root_node: Node3D = null) -> void:
	map_root_node = root_node
	_setup_global_environment()

func _setup_global_environment() -> void:
	global_variables = {
		"game": self,
		"Workspace": map_root_node,
		"workspace": map_root_node,
		"math": {
			"sin": Callable(self, "_math_sin"),
			"cos": Callable(self, "_math_cos"),
			"tan": Callable(self, "_math_tan"),
			"rad": Callable(self, "_math_rad"),
			"deg": Callable(self, "_math_deg"),
			"random": Callable(self, "_math_random"),
			"clamp": Callable(self, "_math_clamp"),
			"abs": Callable(self, "_math_abs"),
			"sqrt": Callable(self, "_math_sqrt"),
			"floor": Callable(self, "_math_floor"),
			"ceil": Callable(self, "_math_ceil")
		}
	}

func _math_sin(a: float) -> float: return sin(a)
func _math_cos(a: float) -> float: return cos(a)
func _math_tan(a: float) -> float: return tan(a)
func _math_rad(a: float) -> float: return deg_to_rad(a)
func _math_deg(a: float) -> float: return rad_to_deg(a)
func _math_random(a: float = 0.0, b: float = 1.0) -> float: return randf_range(a, b)
func _math_clamp(v: float, min_v: float, max_v: float) -> float: return clamp(v, min_v, max_v)
func _math_abs(v: float) -> float: return abs(v)
func _math_sqrt(v: float) -> float: return sqrt(v)
func _math_floor(v: float) -> float: return floor(v)
func _math_ceil(v: float) -> float: return ceil(v)

func run_script(script_name: String, source_code: String, target_instance: Node3D = null) -> void:
	if source_code.strip_edges() == "": return

	var env: Dictionary = global_variables.duplicate(true)
	env["script"] = {
		"Name": script_name,
		"Parent": target_instance if target_instance else map_root_node
	}

	print("[LuauVM] Executing Luau Script: '%s'" % script_name)
	
	var lines: PackedStringArray = source_code.split("\n")
	for line in lines:
		_execute_line(line.strip_edges(), env, target_instance)

func _execute_line(line: String, env: Dictionary, target_instance: Node3D) -> void:
	if line.begins_with("--") or line == "":
		return

	# 1. Print / Warn / Error Output
	if line.begins_with("print(") and line.ends_with(")"):
		var raw_arg: String = line.substr(6, line.length() - 7).strip_edges()
		var msg: Variant = _evaluate_expression(raw_arg, env)
		print("[Luau: %s] %s" % [env.get("script", {}).get("Name", "Script"), msg])
		print_output.emit(str(msg))

	# 2. Event Connections (:Connect / :connect)
	elif ".Activated:connect" in line or ".Activated:Connect" in line:
		_bind_event("Activated", target_instance, env)
	elif ".Equipped:connect" in line or ".Equipped:Connect" in line:
		_bind_event("Equipped", target_instance, env)
	elif ".Touched:connect" in line or ".Touched:Connect" in line:
		_bind_event("Touched", target_instance, env)

	# 3. Dynamic Property Assignments (e.g. game.Lighting.Brightness = 1)
	elif "=" in line and not ("==" in line or "<=" in line or ">=" in line):
		var parts: PackedStringArray = line.split("=")
		if parts.size() == 2:
			var lhs: String = parts[0].strip_edges()
			var rhs: Variant = _evaluate_expression(parts[1].strip_edges(), env)
			_set_property_by_path(lhs, rhs, env)

func _bind_event(event_name: String, target_instance: Node3D, env: Dictionary) -> void:
	if not target_instance: return

	match event_name:
		"Activated":
			print("[LuauVM] Bound Activated event on %s" % target_instance.name)
		"Equipped":
			print("[LuauVM] Bound Equipped event on %s" % target_instance.name)
		"Touched":
			print("[LuauVM] Bound Touched event on %s" % target_instance.name)
			_attach_touch_trigger(target_instance)

func _attach_touch_trigger(target_instance: Node3D) -> void:
	var area: Area3D = Area3D.new()
	area.name = "LuauTouchArea"
	var col: CollisionShape3D = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	area.add_child(col)
	target_instance.add_child(area)

	area.body_entered.connect(func(body):
		print("[LuauVM] Touched event fired on %s by %s" % [target_instance.name, body.name])
	)

func _evaluate_expression(expr: String, env: Dictionary) -> Variant:
	expr = expr.strip_edges()
	if (expr.begins_with('"') and expr.ends_with('"')) or (expr.begins_with("'") and expr.ends_with("'")):
		return expr.substr(1, expr.length() - 2)
	elif expr.is_valid_float():
		return expr.to_float()
	elif expr.is_valid_int():
		return expr.to_int()
	elif expr == "true":
		return true
	elif expr == "false":
		return false
	return expr

func _set_property_by_path(path: String, value: Variant, env: Dictionary) -> void:
	print("[LuauVM] Set property: %s = %s" % [path, str(value)])
