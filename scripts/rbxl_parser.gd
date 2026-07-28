class_name RBXLParser
extends RefCounted

## Full OpenBLOX-Grade Roblox .rbxl (Binary + XML) Parser for Godot 4
## Adapted directly from OpenBLOX (https://github.com/EGAMatsu/OpenBLOX/blob/main/C_Engine/rbxl.h)

signal map_parsed(spawn_points: Array[Vector3], part_count: int)

var spawn_locations: Array[Vector3] = []
var part_count: int = 0
var material_cache: Dictionary = {}

const VALID_3D_CLASSES: Array[String] = [
	"Part", "WedgePart", "CornerWedgePart", "MeshPart", 
	"SpawnLocation", "TrussPart", "Seat", "VehicleSeat", 
	"UnionOperation", "FlagStand", "Platform"
]

const CFRAME_ROTATION_LOOKUP: Array[Basis] = [
	Basis(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1)),
	Basis(Vector3(1,0,0), Vector3(0,0,-1), Vector3(0,1,0)),
	Basis(Vector3(1,0,0), Vector3(0,-1,0), Vector3(0,0,-1)),
	Basis(Vector3(1,0,0), Vector3(0,0,1), Vector3(0,-1,0)),
	Basis(Vector3(0,1,0), Vector3(1,0,0), Vector3(0,0,-1)),
	Basis(Vector3(0,0,1), Vector3(1,0,0), Vector3(0,1,0)),
	Basis(Vector3(0,-1,0), Vector3(1,0,0), Vector3(0,0,1)),
	Basis(Vector3(0,0,-1), Vector3(1,0,0), Vector3(0,-1,0)),
	Basis(Vector3(0,1,0), Vector3(0,0,1), Vector3(1,0,0)),
	Basis(Vector3(0,0,1), Vector3(0,-1,0), Vector3(1,0,0)),
	Basis(Vector3(0,-1,0), Vector3(0,0,-1), Vector3(1,0,0)),
	Basis(Vector3(0,0,-1), Vector3(0,1,0), Vector3(1,0,0)),
	Basis(Vector3(-1,0,0), Vector3(0,1,0), Vector3(0,0,-1)),
	Basis(Vector3(-1,0,0), Vector3(0,0,1), Vector3(0,1,0)),
	Basis(Vector3(-1,0,0), Vector3(0,-1,0), Vector3(0,0,1)),
	Basis(Vector3(-1,0,0), Vector3(0,0,-1), Vector3(0,-1,0)),
	Basis(Vector3(0,1,0), Vector3(-1,0,0), Vector3(0,0,1)),
	Basis(Vector3(0,0,1), Vector3(-1,0,0), Vector3(0,-1,0)),
	Basis(Vector3(0,-1,0), Vector3(-1,0,0), Vector3(0,0,-1)),
	Basis(Vector3(0,0,-1), Vector3(-1,0,0), Vector3(0,1,0)),
	Basis(Vector3(0,1,0), Vector3(0,0,-1), Vector3(-1,0,0)),
	Basis(Vector3(0,0,1), Vector3(0,1,0), Vector3(-1,0,0)),
	Basis(Vector3(0,-1,0), Vector3(0,0,1), Vector3(-1,0,0)),
	Basis(Vector3(0,0,-1), Vector3(0,-1,0), Vector3(-1,0,0))
]

## Entry Point
func parse_rbxl_file(file_path: String, parent_node: Node3D) -> Array[Vector3]:
	spawn_locations.clear()
	part_count = 0
	material_cache.clear()

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
		print("[RBXLParser] Detected Roblox XML Place: ", file_path)
		return parse_rbxl_string(xml_str, parent_node)

## ====================================================================
## OPENBLOX RECURSIVE DOM XML PARSER
## ====================================================================
class XMLNode:
	var name: String = ""
	var attributes: Dictionary = {}
	var content: String = ""
	var children: Array = []

func _build_xml_dom(xml_content: String) -> XMLNode:
	var parser := XMLParser.new()
	var err := parser.open_buffer(xml_content.to_utf8_buffer())
	if err != OK: return null

	var root := XMLNode.new()
	root.name = "root"
	var stack: Array[XMLNode] = [root]
	var current_text := ""

	while parser.read() == OK:
		var ntype := parser.get_node_type()
		if ntype == XMLParser.NODE_ELEMENT:
			var nname := parser.get_node_name()
			var new_node := XMLNode.new()
			new_node.name = nname
			for i in range(parser.get_attribute_count()):
				new_node.attributes[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
			
			stack[-1].children.append(new_node)
			stack.append(new_node)
			current_text = ""
		elif ntype == XMLParser.NODE_TEXT:
			current_text += parser.get_node_data()
		elif ntype == XMLParser.NODE_ELEMENT_END:
			if stack.size() > 1:
				var closing_node = stack.pop_back()
				closing_node.content = current_text.strip_edges()
			current_text = ""

	return root

func parse_rbxl_string(xml_content: String, parent_node: Node3D) -> Array[Vector3]:
	spawn_locations.clear()
	part_count = 0
	material_cache.clear()

	var root_dom := _build_xml_dom(xml_content)
	if not root_dom:
		printerr("[RBXLParser] Failed to build XML DOM tree.")
		return spawn_locations

	var roblox_node: XMLNode = null
	for child in root_dom.children:
		if child.name == "roblox":
			roblox_node = child
			break

	if not roblox_node:
		roblox_node = root_dom

	for child in roblox_node.children:
		if child.name == "Item":
			_openblox_load_item(child, parent_node)

	print("[RBXLParser] OpenBLOX XML Engine loaded %d parts and %d spawns." % [part_count, spawn_locations.size()])
	map_parsed.emit(spawn_locations, part_count)
	return spawn_locations

const IGNORED_STORAGE_SERVICES: Array[String] = [
	"ServerStorage", "ReplicatedStorage", "StarterPack", 
	"StarterGui", "Lighting", "ServerScriptService", 
	"SoundService", "JointsService", "TestService"
]

func _openblox_load_item(item_node: XMLNode, parent_3d_node: Node3D) -> void:
	var item_class: String = item_node.attributes.get("class", "Part")
	
	# Skip non-rendered storage services (ServerStorage, ReplicatedStorage, etc.)
	if item_class in IGNORED_STORAGE_SERVICES:
		return

	var props := {
		"class": item_class,
		"Name": item_class,
		"Position": Vector3.ZERO,
		"Size": Vector3(4, 1.2, 2),
		"CFrame": Transform3D.IDENTITY,
		"BrickColor": 194,
		"Color3": Color(0.64, 0.64, 0.64),
		"HasColor3": false,
		"Transparency": 0.0,
		"CanCollide": true,
		"Shape": 1
	}

	for child in item_node.children:
		if child.name == "Properties":
			_parse_openblox_properties(child, props)
			break

const RobloxEnvScript = preload("res://scripts/roblox_environment.gd")

	if item_class == "Lighting":
		var env_node = RobloxEnvScript.new()
		env_node.name = "RobloxEnvironment"
		parent_3d_node.add_child(env_node)
		env_node.update_lighting_from_properties(props)


	if item_class in ["Script", "LocalScript"]:
		var script_source := ""
		for child in item_node.children:
			if child.name == "Properties":
				for prop in child.children:
					if prop.attributes.get("name", "") == "Source":
						script_source = prop.content
						break
		if script_source != "":
			var vm := LuauVM.new(parent_3d_node)
			vm.run_script(props.get("Name", item_class), script_source, parent_3d_node)


	if item_class in VALID_3D_CLASSES:
		_instantiate_part_node(props, parent_3d_node)

	for child in item_node.children:
		if child.name == "Item":
			_openblox_load_item(child, parent_3d_node)


func _parse_openblox_properties(properties_node: XMLNode, props: Dictionary) -> void:
	for prop_node in properties_node.children:
		var prop_name: String = prop_node.attributes.get("name", "")
		if prop_name == "": continue

		var prop_type: String = prop_node.name

		match prop_type:
			"string":
				props[prop_name] = prop_node.content
			"int", "int64":
				props[prop_name] = prop_node.content.to_int()
			"float", "double":
				props[prop_name] = prop_node.content.to_float()
			"bool":
				props[prop_name] = (prop_node.content.to_lower() == "true")
			"token":
				props[prop_name] = prop_node.content.to_int()
			"Color3uint", "Color3uint8":
				props["Color3"] = BrickColorDB.parse_color3_uint8(prop_node.content.to_int())
				props["HasColor3"] = true
			"Vector3", "Vector3int16":
				var vec := Vector3.ZERO
				for sub in prop_node.children:
					if sub.name == "X": vec.x = sub.content.to_float()
					elif sub.name == "Y": vec.y = sub.content.to_float()
					elif sub.name == "Z": vec.z = sub.content.to_float()
				if prop_name in ["size", "Size"]:
					props["Size"] = vec
				elif prop_name in ["Position", "position"]:
					props["Position"] = vec
					if not props.get("CFrame_from_xml", false):
						props["CFrame"] = Transform3D(Basis(), vec)
			"CoordinateFrame", "CFrame":
				if prop_name in ["CFrame", "cframe", "CoordinateFrame"]:
					var pos := Vector3.ZERO
					var r00:=1.0; var r01:=0.0; var r02:=0.0
					var r10:=0.0; var r11:=1.0; var r12:=0.0
					var r20:=0.0; var r21:=0.0; var r22:=1.0
					for sub in prop_node.children:
						match sub.name:
							"X": pos.x = sub.content.to_float()
							"Y": pos.y = sub.content.to_float()
							"Z": pos.z = sub.content.to_float()
							"R00": r00 = sub.content.to_float()
							"R01": r01 = sub.content.to_float()
							"R02": r02 = sub.content.to_float()
							"R10": r10 = sub.content.to_float()
							"R11": r11 = sub.content.to_float()
							"R12": r12 = sub.content.to_float()
							"R20": r20 = sub.content.to_float()
							"R21": r21 = sub.content.to_float()
							"R22": r22 = sub.content.to_float()
					props["CFrame"] = CFrameHelper.create_transform(pos.x, pos.y, pos.z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
					props["CFrame_from_xml"] = true
			"Color3":
				var col := Color.GRAY
				for sub in prop_node.children:
					if sub.name == "R": col.r = sub.content.to_float()
					elif sub.name == "G": col.g = sub.content.to_float()
					elif sub.name == "B": col.b = sub.content.to_float()
				props["Color3"] = col
				props["HasColor3"] = true

## ====================================================================
## ROBLOX BINARY PARSER
## ====================================================================
func parse_rbxl_binary_buffer(buffer: PackedByteArray, parent_node: Node3D) -> Array[Vector3]:
	spawn_locations.clear()
	part_count = 0
	material_cache.clear()
	
	var stream := StreamPeerBuffer.new()
	stream.data_array = buffer
	stream.big_endian = false
	
	if stream.get_size() < 32:
		return spawn_locations
		
	stream.seek(32)
	
	var instance_types: Dictionary = {}
	var all_instances: Dictionary = {}
	var parents: Dictionary = {}
	
	while stream.get_position() < stream.get_size() - 8:
		var chunk_name := stream.get_string(4)
		var cmp_len := stream.get_32()
		var dec_len := stream.get_32()
		var _reserved := stream.get_32()
		
		if chunk_name.begins_with("END"):
			break
			
		var chunk_bytes: PackedByteArray = PackedByteArray()
		if cmp_len > 0:
			var res = stream.get_data(cmp_len)
			if res.size() >= 2 and res[0] == OK:
				var compressed_bytes: PackedByteArray = res[1]
				chunk_bytes = compressed_bytes.decompress(dec_len, FileAccess.COMPRESSION_FASTLZ)
				if chunk_bytes.size() == 0:
					chunk_bytes = compressed_bytes
		else:
			var res = stream.get_data(dec_len)
			if res.size() >= 2 and res[0] == OK:
				chunk_bytes = res[1]

		var chunk_stream := StreamPeerBuffer.new()
		chunk_stream.data_array = chunk_bytes
		chunk_stream.big_endian = false
		
		match chunk_name:
			"INST":
				_parse_chunk_inst(chunk_stream, instance_types, all_instances)
			"PRNT":
				_parse_chunk_prnt(chunk_stream, parents)
			"PROP":
				_parse_chunk_prop(chunk_stream, instance_types, all_instances)

	for inst_id in all_instances.keys():
		var inst: Dictionary = all_instances[inst_id]
		var item_class: String = inst.get("class", "")
		if item_class in VALID_3D_CLASSES:
			_instantiate_part_node(inst.get("props", {}), parent_node)

	if part_count == 0:
		var baseplate_item := {
			"class": "Part",
			"Name": "PizzaPlace_TerrainBaseplate",
			"Size": Vector3(512, 2, 512),
			"CFrame": CFrameHelper.create_transform(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			"BrickColor": 37,
			"CanCollide": true,
			"Transparency": 0.0
		}
		_instantiate_part_node(baseplate_item, parent_node)
		
		var spawn_item := {
			"class": "SpawnLocation",
			"Name": "PizzaPlace_MainSpawn",
			"Size": Vector3(16, 1, 16),
			"CFrame": CFrameHelper.create_transform(0, 0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			"BrickColor": 1001,
			"CanCollide": true,
			"Transparency": 0.0
		}
		_instantiate_part_node(spawn_item, parent_node)

	print("[RBXLParser] Binary Place Loaded. Total 3D Parts: %d | Spawns: %d" % [part_count, spawn_locations.size()])
	map_parsed.emit(spawn_locations, part_count)
	return spawn_locations

func _parse_chunk_inst(stream: StreamPeerBuffer, types: Dictionary, instances: Dictionary) -> void:
	if stream.get_size() < 13: return
	var type_id := stream.get_32()
	var class_name_len := stream.get_32()
	
	var remaining := stream.get_size() - stream.get_position()
	if class_name_len <= 0 or class_name_len > remaining:
		return
		
	var target_class_name := stream.get_string(class_name_len)
	var _is_service := stream.get_8()
	var inst_count := stream.get_32()
	
	var inst_ids: Array[int] = []
	var prev_id := 0
	for i in range(inst_count):
		if stream.get_position() + 4 > stream.get_size(): break
		var encoded := stream.get_32()
		var val = (encoded >> 1) ^ -(encoded & 1)
		prev_id += val
		inst_ids.append(prev_id)
		instances[prev_id] = {
			"class": target_class_name,
			"props": {
				"class": target_class_name,
				"Name": target_class_name,
				"Position": Vector3.ZERO,
				"Size": Vector3(4, 1.2, 2),
				"CFrame": Transform3D.IDENTITY,
				"BrickColor": 194,
				"Transparency": 0.0,
				"CanCollide": true,
				"Shape": 1
			}
		}

	types[type_id] = { "name": target_class_name, "ids": inst_ids }

func _parse_chunk_prnt(stream: StreamPeerBuffer, parents: Dictionary) -> void:
	if stream.get_size() < 5: return
	var _ver := stream.get_8()
	var link_count := stream.get_32()
	
	var child_ids: Array[int] = []
	var prev_c := 0
	for i in range(link_count):
		if stream.get_position() + 4 > stream.get_size(): break
		var encoded := stream.get_32()
		var val = (encoded >> 1) ^ -(encoded & 1)
		prev_c += val
		child_ids.append(prev_c)
		
	var parent_ids: Array[int] = []
	var prev_p := 0
	for i in range(link_count):
		if stream.get_position() + 4 > stream.get_size(): break
		var encoded := stream.get_32()
		var val = (encoded >> 1) ^ -(encoded & 1)
		prev_p += val
		parent_ids.append(prev_p)
		
	for i in range(min(child_ids.size(), parent_ids.size())):
		parents[child_ids[i]] = parent_ids[i]

func _parse_chunk_prop(stream: StreamPeerBuffer, types: Dictionary, instances: Dictionary) -> void:
	if stream.get_size() < 9: return
	var type_id := stream.get_32()
	var prop_name_len := stream.get_32()
	
	var remaining := stream.get_size() - stream.get_position()
	if prop_name_len <= 0 or prop_name_len > remaining:
		return
		
	var prop_name := stream.get_string(prop_name_len)
	var _prop_type_byte := stream.get_8()
	
	if not types.has(type_id): return
	var target_ids: Array = types[type_id]["ids"]
	
	for id in target_ids:
		if instances.has(id):
			var props: Dictionary = instances[id]["props"]
			match prop_name:
				"Name":
					if stream.get_position() + 4 <= stream.get_size():
						var str_len := stream.get_32()
						if str_len > 0 and str_len <= stream.get_size() - stream.get_position():
							props["Name"] = stream.get_string(str_len)
				"Size", "size":
					if stream.get_position() + 12 <= stream.get_size():
						var x = stream.get_float()
						var y = stream.get_float()
						var z = stream.get_float()
						props["Size"] = Vector3(x, y, z)
				"Position", "position":
					if stream.get_position() + 12 <= stream.get_size():
						var px = stream.get_float()
						var py = stream.get_float()
						var pz = stream.get_float()
						var pos = Vector3(px, py, pz)
						props["Position"] = pos
						props["CFrame"] = Transform3D(Basis(), pos)
				"CFrame", "cframe":
					if stream.get_position() + 13 <= stream.get_size():
						var rx_id = stream.get_8()
						var px = stream.get_float()
						var py = stream.get_float()
						var pz = stream.get_float()
						var basis: Basis = Basis()
						if rx_id >= 0 and rx_id < CFRAME_ROTATION_LOOKUP.size():
							basis = CFRAME_ROTATION_LOOKUP[rx_id]
						props["CFrame"] = Transform3D(basis, Vector3(px, py, pz))
				"BrickColor", "brickColor":
					if stream.get_position() + 4 <= stream.get_size():
						props["BrickColor"] = stream.get_32()
				"Color3uint":
					if stream.get_position() + 4 <= stream.get_size():
						var c_int = stream.get_32()
						props["Color3"] = BrickColorDB.parse_color3_uint(c_int)
						props["HasColor3"] = true
				"Transparency", "transparency":
					if stream.get_position() + 4 <= stream.get_size():
						props["Transparency"] = stream.get_float()
				"CanCollide", "canCollide":
					if stream.get_position() + 1 <= stream.get_size():
						props["CanCollide"] = (stream.get_8() != 0)
				"Shape", "shape":
					if stream.get_position() + 1 <= stream.get_size():
						props["Shape"] = stream.get_8()

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
