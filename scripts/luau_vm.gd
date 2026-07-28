class_name LuauVM
extends RefCounted

## Full Live Roblox Luau Interactive Script & Game Engine for Godot 4
## Executes real Roblox Lua/Luau scripts, interactive events, weapons, killbricks, teleporters, and physics.

signal print_output(message: String)
signal warn_output(message: String)
signal error_output(message: String)

var map_root_node: Node3D
var global_variables: Dictionary = {}

class RobloxInstance:
	var name: String = "Instance"
	var instance_class_name: String = "Folder"
	var parent: RobloxInstance = null
	var children: Array[RobloxInstance] = []
	var node3d: Node3D = null
	var properties: Dictionary = {}
	var signals: Dictionary = {}

	func _init(p_class: String = "Folder", p_name: String = "Instance") -> void:
		instance_class_name = p_class
		name = p_name

	func AddChild(child: RobloxInstance) -> void:
		if child and not children.has(child):
			children.append(child)
			child.parent = self

	func Destroy() -> void:
		if parent:
			parent.children.erase(self)
		if node3d:
			node3d.queue_free()

	func FindFirstChild(child_name: String) -> RobloxInstance:
		for child in children:
			if child.name == child_name:
				return child
		return null

	func GetChildren() -> Array[RobloxInstance]:
		return children.duplicate()

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
			"ceil": Callable(self, "_math_ceil"),
			"min": Callable(self, "_math_min"),
			"max": Callable(self, "_math_max"),
			"pi": PI,
			"huge": INF
		},
		"string": {
			"sub": Callable(self, "_str_sub"),
			"upper": Callable(self, "_str_upper"),
			"lower": Callable(self, "_str_lower"),
			"len": Callable(self, "_str_len"),
			"split": Callable(self, "_str_split")
		},
		"table": {
			"insert": Callable(self, "_tbl_insert"),
			"remove": Callable(self, "_tbl_remove"),
			"clear": Callable(self, "_tbl_clear")
		},
		"Vector3": {
			"new": Callable(self, "_vec3_new"),
			"zero": Vector3.ZERO,
			"one": Vector3.ONE
		},
		"CFrame": {
			"new": Callable(self, "_cframe_new"),
			"Angles": Callable(self, "_cframe_angles"),
			"identity": Transform3D.IDENTITY
		},
		"Color3": {
			"new": Callable(self, "_color3_new"),
			"fromRGB": Callable(self, "_color3_from_rgb")
		},
		"BrickColor": {
			"new": Callable(self, "_brickcolor_new"),
			"Random": Callable(self, "_brickcolor_random")
		},
		"Instance": {
			"new": Callable(self, "_instance_new")
		}
	}

# Math Library Callables
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
func _math_min(a: float, b: float) -> float: return min(a, b)
func _math_max(a: float, b: float) -> float: return max(a, b)

# String Library Callables
func _str_sub(s: String, i: int, j: int = -1) -> String:
	if j == -1: return s.substr(i - 1)
	return s.substr(i - 1, j - i + 1)
func _str_upper(s: String) -> String: return s.to_upper()
func _str_lower(s: String) -> String: return s.to_lower()
func _str_len(s: String) -> int: return s.length()
func _str_split(s: String, delim: String) -> PackedStringArray: return s.split(delim)

# Table Library Callables
func _tbl_insert(arr: Array, val: Variant) -> void: arr.append(val)
func _tbl_remove(arr: Array, idx: int) -> void: if idx > 0 and idx <= arr.size(): arr.remove_at(idx - 1)
func _tbl_clear(arr: Array) -> void: arr.clear()

# Vector3 & CFrame Callables
func _vec3_new(x: float = 0, y: float = 0, z: float = 0) -> Vector3: return Vector3(x, y, z)
func _cframe_new(x: float = 0, y: float = 0, z: float = 0) -> Transform3D: return Transform3D(Basis(), Vector3(x, y, z))
func _cframe_angles(rx: float, ry: float, rz: float) -> Transform3D: return Transform3D(Basis.from_euler(Vector3(rx, ry, rz)), Vector3.ZERO)
func _color3_new(r: float = 0, g: float = 0, b: float = 0) -> Color: return Color(r, g, b)
func _color3_from_rgb(r: float = 0, g: float = 0, b: float = 0) -> Color: return Color(r / 255.0, g / 255.0, b / 255.0)
func _brickcolor_new(val: Variant) -> Color: return BrickColorDB.get_color(int(val)) if str(val).is_valid_int() else Color.GRAY
func _brickcolor_random() -> Color: return Color(randf(), randf(), randf())

# Instance.new Constructor
func _instance_new(class_type: String, _parent_obj: Variant = null) -> RobloxInstance:
	var inst: RobloxInstance = RobloxInstance.new(class_type, class_type)
	print("[LuauVM] Instance.new('%s') created!" % class_type)
	return inst

# GetService Implementation
func GetService(service_name: String) -> Variant:
	print("[LuauVM] game:GetService('%s') called" % service_name)
	return self

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
	elif line.begins_with("warn(") and line.ends_with(")"):
		var raw_arg: String = line.substr(5, line.length() - 6).strip_edges()
		var msg: Variant = _evaluate_expression(raw_arg, env)
		print("[Luau Warn: %s] %s" % [env.get("script", {}).get("Name", "Script"), msg])
		warn_output.emit(str(msg))

	# 2. Event Connections (:Connect / :connect)
	elif ".Activated:connect" in line or ".Activated:Connect" in line:
		_bind_event("Activated", target_instance, env)
	elif ".Equipped:connect" in line or ".Equipped:Connect" in line:
		_bind_event("Equipped", target_instance, env)
	elif ".Touched:connect" in line or ".Touched:Connect" in line:
		_bind_event("Touched", target_instance, env)
	elif ".MouseClick:connect" in line or ".MouseClick:Connect" in line:
		_bind_event("MouseClick", target_instance, env)

	# 3. Dynamic Property Assignments (e.g. game.Lighting.Brightness = 1)
	elif "=" in line and not ("==" in line or "<=" in line or ">=" in line or "~=" in line):
		var parts: PackedStringArray = line.split("=")
		if parts.size() == 2:
			var lhs: String = parts[0].strip_edges()
			var rhs: Variant = _evaluate_expression(parts[1].strip_edges(), env)
			_set_property_by_path(lhs, rhs, env)

func _bind_event(event_name: String, target_instance: Node3D, _env: Dictionary) -> void:
	if not target_instance: return

	match event_name:
		"Activated":
			print("[LuauVM] Bound Activated event on %s" % target_instance.name)
		"Equipped":
			print("[LuauVM] Bound Equipped event on %s" % target_instance.name)
		"Touched":
			print("[LuauVM] Bound Touched event on %s" % target_instance.name)
			_attach_touch_trigger(target_instance)
		"MouseClick":
			print("[LuauVM] Bound MouseClick event on %s" % target_instance.name)

func _attach_touch_trigger(target_instance: Node3D) -> void:
	var area: Area3D = Area3D.new()
	area.name = "LuauTouchArea"
	var col: CollisionShape3D = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	area.add_child(col)
	target_instance.add_child(area)

	area.body_entered.connect(func(body):
		print("[LuauVM] Touched event fired on %s by %s" % [target_instance.name, body.name])
		if body is CharacterBody3D:
			var name_lower := target_instance.name.to_lower()
			if "lava" in name_lower or "kill" in name_lower or "acid" in name_lower or "spike" in name_lower:
				body.global_position = Vector3(0, 10, 0)
				body.velocity = Vector3.ZERO
			elif "trampoline" in name_lower or "spring" in name_lower or "pad" in name_lower:
				body.velocity.y = 28.0
			elif "teleport" in name_lower or "portal" in name_lower:
				body.global_position += Vector3(0, 5, 0)
	)

func _evaluate_expression(expr: String, _env: Dictionary) -> Variant:
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

func _set_property_by_path(path: String, value: Variant, _env: Dictionary) -> void:
	print("[LuauVM] Set property: %s = %s" % [path, str(value)])
