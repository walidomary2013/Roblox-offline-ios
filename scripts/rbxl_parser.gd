class_name RBXLParser
extends RefCounted

## Offline 2017 Roblox .rbxl XML Map Parser for Godot 4
## Extracts Part, WedgePart, CornerWedgePart, SpawnLocation, meshes, materials, and spatial CFrames.

signal map_parsed(spawn_points: Array[Vector3], part_count: int)

var spawn_locations: Array[Vector3] = []
var part_count: int = 0

const FALLBACK_2017_MAP_XML: String = """<roblox version="4">
	<Item class="Workspace" referent="RBX0">
		<Item class="Part" referent="RBX1">
			<Properties>
				<string name="Name">Baseplate</string>
				<bool name="Anchored">true</bool>
				<bool name="CanCollide">true</bool>
				<int name="BrickColor">37</int>
				<CoordinateFrame name="CFrame">
					<X>0</X><Y>-1</Y><Z>0</Z>
					<R00>1</R00><R01>0</R01><R02>0</R02>
					<R10>0</R10><R11>1</R11><R12>0</R12>
					<R20>0</R20><R21>0</R21><R22>1</R22>
				</CoordinateFrame>
				<Vector3 name="size"><X>256</X><Y>2</Y><Z>256</Z></Vector3>
				<float name="Transparency">0</float>
				<token name="shape">1</token>
			</Properties>
		</Item>
		<Item class="SpawnLocation" referent="RBX2">
			<Properties>
				<string name="Name">SpawnLocation</string>
				<bool name="Anchored">true</bool>
				<bool name="CanCollide">true</bool>
				<int name="BrickColor">1001</int>
				<CoordinateFrame name="CFrame">
					<X>0</X><Y>0.5</Y><Z>0</Z>
					<R00>1</R00><R01>0</R01><R02>0</R02>
					<R10>0</R10><R11>1</R11><R12>0</R12>
					<R20>0</R20><R21>0</R21><R22>1</R22>
				</CoordinateFrame>
				<Vector3 name="size"><X>12</X><Y>1</Y><Z>12</Z></Vector3>
				<float name="Transparency">0</float>
				<token name="shape">1</token>
			</Properties>
		</Item>
		<Item class="Part" referent="RBX3">
			<Properties>
				<string name="Name">BluePillar</string>
				<bool name="Anchored">true</bool>
				<bool name="CanCollide">true</bool>
				<int name="BrickColor">23</int>
				<CoordinateFrame name="CFrame">
					<X>-20</X><Y>8</Y><Z>-20</Z>
					<R00>1</R00><R01>0</R01><R02>0</R02>
					<R10>0</R10><R11>1</R11><R12>0</R12>
					<R20>0</R20><R21>0</R21><R22>1</R22>
				</CoordinateFrame>
				<Vector3 name="size"><X>4</X><Y>16</Y><Z>4</Z></Vector3>
				<float name="Transparency">0</float>
				<token name="shape">1</token>
			</Properties>
		</Item>
		<Item class="WedgePart" referent="RBX4">
			<Properties>
				<string name="Name">RedRamp</string>
				<bool name="Anchored">true</bool>
				<bool name="CanCollide">true</bool>
				<int name="BrickColor">21</int>
				<CoordinateFrame name="CFrame">
					<X>15</X><Y>4</Y><Z>-10</Z>
					<R00>1</R00><R01>0</R01><R02>0</R02>
					<R10>0</R10><R11>1</R11><R12>0</R12>
					<R20>0</R20><R21>0</R21><R22>1</R22>
				</CoordinateFrame>
				<Vector3 name="size"><X>8</X><Y>8</Y><Z>16</Z></Vector3>
				<float name="Transparency">0</float>
				<token name="shape">1</token>
			</Properties>
		</Item>
		<Item class="Part" referent="RBX5">
			<Properties>
				<string name="Name">YellowPlatform</string>
				<bool name="Anchored">true</bool>
				<bool name="CanCollide">true</bool>
				<int name="BrickColor">24</int>
				<CoordinateFrame name="CFrame">
					<X>0</X><Y>3</Y><Z>-30</Z>
					<R00>1</R00><R01>0</R01><R02>0</R02>
					<R10>0</R10><R11>1</R11><R12>0</R12>
					<R20>0</R20><R21>0</R21><R22>1</R22>
				</CoordinateFrame>
				<Vector3 name="size"><X>16</X><Y>6</Y><Z>16</Z></Vector3>
				<float name="Transparency">0</float>
				<token name="shape">2</token>
			</Properties>
		</Item>
	</Item>
</roblox>"""

## Parse an XML .rbxl file from a given path (e.g. "res://maps/sample_2017_place.rbxl")
func parse_rbxl_file(file_path: String, parent_node: Node3D) -> Array[Vector3]:
	if FileAccess.file_exists(file_path):
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file:
			var xml_content := file.get_as_text()
			file.close()
			if xml_content.strip_edges() != "":
				print("[RBXLParser] Loading .rbxl file from disk: ", file_path)
				return parse_rbxl_string(xml_content, parent_node)

	print("[RBXLParser] File not found or unreadable in PCK (%s), loading embedded 2017 fallback map..." % file_path)
	return parse_rbxl_string(FALLBACK_2017_MAP_XML, parent_node)

## Parse an XML .rbxl string buffer
func parse_rbxl_string(xml_content: String, parent_node: Node3D) -> Array[Vector3]:
	spawn_locations.clear()
	part_count = 0
	
	var parser := XMLParser.new()
	var err := parser.open_buffer(xml_content.to_utf8_buffer())
	if err != OK:
		printerr("[RBXLParser] Failed to open XML string buffer: ", err)
		return spawn_locations

	var item_stack: Array[Dictionary] = []
	var in_properties := false
	var active_prop_name := ""
	var active_prop_type := ""
	var current_sub_tag := ""
	var sub_values := {}

	while parser.read() == OK:
		var node_type := parser.get_node_type()
		var node_name := parser.get_node_name()

		if node_type == XMLParser.NODE_ELEMENT:
			if node_name == "Item":
				var item_class := parser.get_named_attribute_value_safe("class")
				var new_item := {
					"class": item_class,
					"Name": item_class,
					"Position": Vector3.ZERO,
					"Size": Vector3(4, 1.2, 2),
					"CFrame": Transform3D.IDENTITY,
					"BrickColor": 194,
					"Color3": Color(0.64, 0.64, 0.64),
					"HasColor3": false,
					"Transparency": 0.0,
					"Reflectance": 0.0,
					"CanCollide": true,
					"Shape": 1
				}
				item_stack.append(new_item)
			elif node_name == "Properties":
				in_properties = true
			elif in_properties and item_stack.size() > 0:
				var name_attr := parser.get_named_attribute_value_safe("name")
				if name_attr != "":
					active_prop_name = name_attr
					active_prop_type = node_name
					sub_values.clear()
				else:
					current_sub_tag = node_name

		elif node_type == XMLParser.NODE_TEXT and in_properties and item_stack.size() > 0:
			var text_val := parser.get_node_data().strip_edges()
			if text_val != "":
				var current_item: Dictionary = item_stack[-1]
				if current_sub_tag != "" and current_sub_tag in ["X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"]:
					sub_values[current_sub_tag] = text_val.to_float()
				else:
					match active_prop_type:
						"string":
							current_item[active_prop_name] = text_val
						"int", "int64":
							current_item[active_prop_name] = text_val.to_int()
						"float", "double":
							current_item[active_prop_name] = text_val.to_float()
						"bool":
							current_item[active_prop_name] = (text_val.to_lower() == "true")
						"Color3uint":
							var col_int = text_val.to_int()
							current_item["Color3"] = BrickColorDB.parse_color3_uint(col_int)
							current_item["HasColor3"] = true
						"token":
							current_item[active_prop_name] = text_val.to_int()

		elif node_type == XMLParser.NODE_ELEMENT_END:
			if node_name == "Properties":
				in_properties = false
			elif in_properties and item_stack.size() > 0:
				var current_item: Dictionary = item_stack[-1]
				if node_name in ["Vector3", "Vector3int16"]:
					if active_prop_name in ["size", "Size"]:
						current_item["Size"] = Vector3(
							sub_values.get("X", 4.0),
							sub_values.get("Y", 1.2),
							sub_values.get("Z", 2.0)
						)
					elif active_prop_name in ["Position", "position"]:
						current_item["Position"] = Vector3(
							sub_values.get("X", 0.0),
							sub_values.get("Y", 0.0),
							sub_values.get("Z", 0.0)
						)
				elif node_name == "CoordinateFrame":
					if sub_values.has("X") and sub_values.has("Y") and sub_values.has("Z"):
						var pos = Vector3(sub_values["X"], sub_values["Y"], sub_values["Z"])
						var r00 = sub_values.get("R00", 1.0)
						var r01 = sub_values.get("R01", 0.0)
						var r02 = sub_values.get("R02", 0.0)
						var r10 = sub_values.get("R10", 0.0)
						var r11 = sub_values.get("R11", 1.0)
						var r12 = sub_values.get("R12", 0.0)
						var r20 = sub_values.get("R20", 0.0)
						var r21 = sub_values.get("R21", 0.0)
						var r22 = sub_values.get("R22", 1.0)
						
						current_item["CFrame"] = CFrameHelper.create_transform(
							pos.x, pos.y, pos.z,
							r00, r01, r02,
							r10, r11, r12,
							r20, r21, r22
						)
				current_sub_tag = ""

			elif node_name == "Item" and item_stack.size() > 0:
				var item_to_instantiate: Dictionary = item_stack.pop_back()
				var item_class: String = item_to_instantiate.get("class", "")
				if item_class in ["Part", "WedgePart", "CornerWedgePart", "SpawnLocation", "TrussPart"]:
					_instantiate_part_node(item_to_instantiate, parent_node)

	print("[RBXLParser] Parsed successfully. Total Parts: ", part_count, ", Spawns found: ", spawn_locations.size())
	map_parsed.emit(spawn_locations, part_count)
	return spawn_locations

func _instantiate_part_node(props: Dictionary, parent: Node3D) -> void:
	var item_class: String = props.get("class", "Part")
	var size: Vector3 = props.get("Size", Vector3(4, 1.2, 2))
	var xform: Transform3D = props.get("CFrame", Transform3D.IDENTITY)
	var can_collide: bool = props.get("CanCollide", true)
	var transparency: float = props.get("Transparency", 0.0)

	var color: Color
	if props.get("HasColor3", false):
		color = props.get("Color3", Color.GRAY)
	else:
		var brick_color_id: int = props.get("BrickColor", 194)
		color = BrickColorDB.get_color(brick_color_id)
		
	if transparency >= 1.0 and not can_collide:
		return

	var static_body := StaticBody3D.new()
	static_body.name = str(props.get("Name", item_class)) + "_" + str(part_count)
	static_body.transform = xform

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 1.0 - transparency)
	material.roughness = 0.5
	material.cull_mode = BaseMaterial3D.CULL_BACK
	if transparency > 0.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mesh: Mesh = null
	var shape: Shape3D = null
	var shape_type: int = props.get("Shape", 1)

	if item_class == "WedgePart":
		var prism := PrismMesh.new()
		prism.size = size
		prism.left_to_right = 0.0
		mesh = prism
		
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
		
		material.emission_enabled = true
		material.emission = color * 0.3
	else:
		match shape_type:
			0:
				var sphere_mesh := SphereMesh.new()
				var radius = min(size.x, min(size.y, size.z)) * 0.5
				sphere_mesh.radius = radius
				sphere_mesh.height = radius * 2.0
				mesh = sphere_mesh
				
				var sphere_shape := SphereShape3D.new()
				sphere_shape.radius = radius
				shape = sphere_shape
			2:
				var cyl_mesh := CylinderMesh.new()
				cyl_mesh.top_radius = size.y * 0.5
				cyl_mesh.bottom_radius = size.y * 0.5
				cyl_mesh.height = size.x
				mesh = cyl_mesh
				
				var cyl_shape := CylinderShape3D.new()
				cyl_shape.radius = size.y * 0.5
				cyl_shape.height = size.x
				shape = cyl_shape
			_:
				var box_mesh := BoxMesh.new()
				box_mesh.size = size
				mesh = box_mesh
				
				var box_shape := BoxShape3D.new()
				box_shape.size = size
				shape = box_shape

	if transparency < 1.0 and mesh != null:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh
		mesh_instance.material_override = material
		static_body.add_child(mesh_instance)

	if can_collide and shape != null:
		var col_shape := CollisionShape3D.new()
		col_shape.shape = shape
		static_body.add_child(col_shape)

	parent.add_child(static_body)
	part_count += 1
