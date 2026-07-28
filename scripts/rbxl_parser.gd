class_name RBXLParser
extends RefCounted

## OpenBLOX High-Performance Streaming Roblox .rbxl/.rbxlx Parser for Godot 4
## Uses fast streaming XMLParser SAX parsing & post-instantiation script execution for 60 FPS performance.

signal map_parsed(spawn_points: Array[Vector3], part_count: int)

const RobloxEnvScript = preload("res://scripts/roblox_environment.gd")

var spawn_locations: Array[Vector3] = []
var part_count: int = 0
var material_cache: Dictionary = {}
var pending_scripts: Array[Dictionary] = []

const VALID_3D_CLASSES: Array[String] = [
	"Part", "WedgePart", "CornerWedgePart", "MeshPart", 
	"SpawnLocation", "TrussPart", "Seat", "VehicleSeat", 
	"UnionOperation", "FlagStand", "Platform"
]

const IGNORED_STORAGE_SERVICES: Array[String] = [
	"ServerStorage", "ReplicatedStorage", "StarterPack", 
	"StarterGui", "Lighting", "ServerScriptService", 
	"SoundService", "JointsService", "TestService"
]

## Entry Point
func parse_rbxl_file(file_path: String, parent_node: Node3D) -> Array[Vector3]:
	spawn_locations.clear()
	part_count = 0
	material_cache.clear()
	pending_scripts.clear()

	if not FileAccess.file_exists(file_path):
		printerr("[RBXLParser] File does not exist: ", file_path)
		return spawn_locations

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		printerr("[RBXLParser] Unable to open file: ", file_path)
		return spawn_locations

	var length := file.get_length()
	if length < 8:
		printerr("[RBXLParser] File too small: ", file_path)
		file.close()
		return spawn_locations

	var buffer := file.get_buffer(length)
	file.close()

	if buffer.size() >= 8 and buffer[0] == 0x3C and buffer[1] == 0x72 and buffer[2] == 0x6F and buffer[3] == 0x62 and buffer[4] == 0x6C and buffer[5] == 0x6F and buffer[6] == 0x78 and buffer[7] == 0x21:
		print("[RBXLParser] Detected Roblox Binary Place: ", file_path)
		return parse_rbxl_binary_buffer(buffer, parent_node)
	elif buffer.size() > 0 and buffer[0] == 0x89:
		print("[RBXLParser] Detected Compressed Binary Stream: ", file_path)
		return parse_rbxl_binary_buffer(buffer, parent_node)
	else:
		var xml_str := buffer.get_string_from_utf8()
		if xml_str == "":
			xml_str = buffer.get_string_from_ascii()
		print("[RBXLParser] Parsing Roblox XML Place: ", file_path)
		return parse_rbxl_string(xml_str, parent_node)

## High-Performance Streaming XML Parser
func parse_rbxl_string(xml_content: String, parent_node: Node3D) -> Array[Vector3]:
	spawn_locations.clear()
	part_count = 0
	material_cache.clear()
	pending_scripts.clear()

	var parser := XMLParser.new()
	var err := parser.open_buffer(xml_content.to_utf8_buffer())
	if err != OK:
		printerr("[RBXLParser] XML Parser failed to open buffer.")
		return spawn_locations

	var item_stack: Array[Dictionary] = []
	var current_prop_name := ""
	var current_text := ""

	while parser.read() == OK:
		var ntype := parser.get_node_type()
		if ntype == XMLParser.NODE_ELEMENT:
			var nname := parser.get_node_name()
			current_text = ""

			if nname == "Item":
				var iclass: String = parser.get_named_attribute_value_safe("class")
				if iclass == "": iclass = "Part"

				var new_item := {
					"class": iclass,
					"Name": iclass,
					"Position": Vector3.ZERO,
					"Size": Vector3(4, 1.2, 2),
					"CFrame": Transform3D.IDENTITY,
					"BrickColor": 194,
					"Color3": Color(0.64, 0.64, 0.64),
					"HasColor3": false,
					"Transparency": 0.0,
					"CanCollide": true,
					"Shape": 1,
					"Source": ""
				}
				item_stack.append(new_item)
			elif item_stack.size() > 0:
				current_prop_name = parser.get_named_attribute_value_safe("name")

		elif ntype == XMLParser.NODE_TEXT:
			current_text += parser.get_node_data()

		elif ntype == XMLParser.NODE_ELEMENT_END:
			var end_name := parser.get_node_name()
			var txt := current_text.strip_edges()

			if item_stack.size() > 0:
				var current_item: Dictionary = item_stack[-1]

				if end_name in ["string", "ProtectedString", "ScriptText"]:
					if current_prop_name in ["Source", "ProtectedString", "ScriptText", "SourceCode"]:
						current_item["Source"] = txt
				elif end_name in ["int", "int64", "token"]:
					if current_prop_name == "BrickColor": current_item["BrickColor"] = txt.to_int()
					elif current_prop_name in ["shape", "Shape"]: current_item["Shape"] = txt.to_int()
				elif end_name in ["float", "double"]:
					if current_prop_name in ["Transparency", "transparency"]: current_item["Transparency"] = txt.to_float()
				elif end_name in ["bool"]:
					if current_prop_name in ["CanCollide", "canCollide"]: current_item["CanCollide"] = (txt.to_lower() == "true")
				elif end_name == "Color3uint8":
					current_item["Color3"] = BrickColorDB.parse_color3_uint8(txt.to_int())
					current_item["HasColor3"] = true

				if end_name == "Item":
					var finished_item: Dictionary = item_stack.pop_back()
					var iclass: String = finished_item.get("class", "Part")

					if not (iclass in IGNORED_STORAGE_SERVICES):
						if iclass in VALID_3D_CLASSES:
							_instantiate_part_node(finished_item, parent_node)
						elif iclass == "Lighting":
							var env_node = RobloxEnvScript.new()
							env_node.name = "RobloxEnvironment"
							parent_node.add_child(env_node)
							env_node.update_lighting_from_properties(finished_item)
						elif iclass in ["Script", "LocalScript"]:
							var src: String = finished_item.get("Source", "")
							if src != "":
								src = src.replace("&apos;", "'").replace("&quot;", '"').replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")
								pending_scripts.append({
									"name": finished_item.get("Name", iclass),
									"source": src,
									"target": parent_node
								})

	# Post-Instantiation Script Execution (Execute scripts AFTER 3D world is built)
	if pending_scripts.size() > 0:
		print("[RBXLParser] Executing %d place Luau scripts on complete 3D scene..." % pending_scripts.size())
		var vm := LuauVM.new(parent_node)
		for script_data in pending_scripts:
			vm.run_script(script_data["name"], script_data["source"], script_data["target"])

	print("[RBXLParser] OpenBLOX Fast Streaming Engine loaded %d parts and %d spawns." % [part_count, spawn_locations.size()])
	map_parsed.emit(spawn_locations, part_count)
	return spawn_locations

## High-Performance Material & World-Space Spatial Instantiator
func _instantiate_part_node(props: Dictionary, parent: Node3D) -> Node3D:
	var item_class: String = props.get("class", "Part")
	var size: Vector3 = props.get("Size", Vector3(4, 1.2, 2))
	var xform: Transform3D = props.get("CFrame", Transform3D.IDENTITY)
	var can_collide: bool = props.get("CanCollide", true)
	var transparency: float = props.get("Transparency", 0.0)

	if transparency >= 1.0 and not can_collide:
		return null

	var color: Color
	if props.get("HasColor3", false):
		color = props.get("Color3", Color.GRAY)
	else:
		var brick_color_id: int = props.get("BrickColor", 194)
		color = BrickColorDB.get_color(brick_color_id)

	var mat_key := "%d_%d_%d_%.2f" % [int(color.r * 255), int(color.g * 255), int(color.b * 255), transparency]
	var material: StandardMaterial3D
	if material_cache.has(mat_key):
		material = material_cache[mat_key]
	else:
		material = StandardMaterial3D.new()
		material.albedo_color = Color(color.r, color.g, color.b, 1.0 - transparency)
		material.roughness = 0.5
		material.cull_mode = BaseMaterial3D.CULL_BACK
		if transparency > 0.0:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material_cache[mat_key] = material

	var mesh: Mesh = null
	var shape: Shape3D = null
	var shape_type: int = props.get("Shape", 1)

	if item_class == "WedgePart":
		var prism := PrismMesh.new()
		prism.size = size
		prism.left_to_right = 0.0
		mesh = prism
		if can_collide:
			var box_shape := BoxShape3D.new()
			box_shape.size = size
			shape = box_shape
	elif item_class == "SpawnLocation":
		var box_mesh := BoxMesh.new()
		box_mesh.size = size
		mesh = box_mesh
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape = box_shape
		var spawn_pos = xform.origin + Vector3(0, size.y * 0.5 + 2.0, 0)
		spawn_locations.append(spawn_pos)
	else:
		match shape_type:
			0:
				var sphere_mesh := SphereMesh.new()
				var radius = min(size.x, min(size.y, size.z)) * 0.5
				sphere_mesh.radius = radius
				sphere_mesh.height = radius * 2.0
				mesh = sphere_mesh
				if can_collide:
					var sphere_shape := SphereShape3D.new()
					sphere_shape.radius = radius
					shape = sphere_shape
			2:
				var cyl_mesh := CylinderMesh.new()
				cyl_mesh.top_radius = size.y * 0.5
				cyl_mesh.bottom_radius = size.y * 0.5
				cyl_mesh.height = size.x
				mesh = cyl_mesh
				if can_collide:
					var cyl_shape := CylinderShape3D.new()
					cyl_shape.radius = size.y * 0.5
					cyl_shape.height = size.x
					shape = cyl_shape
			_:
				var box_mesh := BoxMesh.new()
				box_mesh.size = size
				mesh = box_mesh
				if can_collide:
					var box_shape := BoxShape3D.new()
					box_shape.size = size
					shape = box_shape

	var target_parent_node: Node3D = parent
	var instantiated_node: Node3D = null

	if can_collide and shape != null:
		var static_body := StaticBody3D.new()
		static_body.name = str(props.get("Name", item_class)) + "_" + str(part_count)
		static_body.transform = xform
		var col_shape := CollisionShape3D.new()
		col_shape.shape = shape
		static_body.add_child(col_shape)
		target_parent_node = static_body
		instantiated_node = static_body
		parent.add_child(static_body)
	else:
		var mesh_node := Node3D.new()
		mesh_node.name = str(props.get("Name", item_class)) + "_" + str(part_count)
		mesh_node.transform = xform
		target_parent_node = mesh_node
		instantiated_node = mesh_node
		parent.add_child(mesh_node)

	if transparency < 1.0 and mesh != null:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh
		mesh_instance.material_override = material
		target_parent_node.add_child(mesh_instance)

	part_count += 1
	return instantiated_node

## Binary Parser Stub
func parse_rbxl_binary_buffer(_buffer: PackedByteArray, _parent_node: Node3D) -> Array[Vector3]:
	spawn_locations.clear()
	part_count = 0
	material_cache.clear()
	return spawn_locations

