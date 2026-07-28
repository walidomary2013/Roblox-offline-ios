class_name RobloxEnvironment
extends Node3D

## Roblox Dynamic Skybox, Lighting, Sun & Fog Manager for Godot 4
## Renders classic 2007-2017 Roblox skyboxes, Sun position, TimeOfDay, Ambient, Brightness, and Fog.

var world_environment: WorldEnvironment
var directional_light: DirectionalLight3D
var sky_material: ProceduralSkyMaterial
var environment: Environment

# Default 2017 Roblox Lighting parameters
var brightness: float = 2.0
var ambient_color: Color = Color(0.5, 0.5, 0.5)
var outdoor_ambient: Color = Color(0.5, 0.5, 0.5)
var clock_time: float = 14.0 # 2:00 PM Afternoon
var fog_color: Color = Color(0.75, 0.85, 0.95)
var fog_start: float = 0.0
var fog_end: float = 100000.0

func _ready() -> void:
	setup_roblox_environment()

func setup_roblox_environment() -> void:
	# 1. Create Directional Light (Roblox Sun)
	if not has_node("RobloxSun"):
		directional_light = DirectionalLight3D.new()
		directional_light.name = "RobloxSun"
		directional_light.shadow_enabled = true
		directional_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		add_child(directional_light)
	else:
		directional_light = get_node("RobloxSun")

	# 2. Create WorldEnvironment
	if not has_node("RobloxWorldEnv"):
		world_environment = WorldEnvironment.new()
		world_environment.name = "RobloxWorldEnv"
		add_child(world_environment)
	else:
		world_environment = get_node("RobloxWorldEnv")

	environment = Environment.new()
	world_environment.environment = environment

	# 3. Create Classic Roblox Procedural Skybox
	sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.35, 0.65, 0.98)     # Classic Roblox Sky Blue
	sky_material.sky_horizon_color = Color(0.70, 0.85, 0.98) # Warm Horizon Gradient
	sky_material.ground_bottom_color = Color(0.20, 0.25, 0.30)
	sky_material.ground_horizon_color = Color(0.70, 0.85, 0.98)
	sky_material.sun_angle_max = 5.0
	sky_material.sun_curve = 0.15

	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky

	# 4. Ambient & Tone Mapping
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = ambient_color
	environment.ambient_light_energy = 1.0

	update_lighting_from_properties({})

## Update Skybox & Sun orientation from parsed XML Lighting properties
func update_lighting_from_properties(props: Dictionary) -> void:
	brightness = props.get("Brightness", 2.0)
	ambient_color = props.get("Ambient", Color(0.5, 0.5, 0.5))
	outdoor_ambient = props.get("OutdoorAmbient", Color(0.5, 0.5, 0.5))
	
	if props.has("ClockTime"):
		clock_time = props.get("ClockTime", 14.0)
	elif props.has("TimeOfDay"):
		var time_str: String = props.get("TimeOfDay", "14:00:00")
		var parts := time_str.split(":")
		if parts.size() >= 2:
			clock_time = parts[0].to_float() + (parts[1].to_float() / 60.0)

	fog_color = props.get("FogColor", Color(0.75, 0.85, 0.95))
	fog_start = props.get("FogStart", 0.0)
	fog_end = props.get("FogEnd", 100000.0)

	# Apply Lighting & Sun Angle
	if directional_light:
		directional_light.light_energy = brightness
		directional_light.light_color = props.get("ColorShift_Top", Color.WHITE)
		
		# Rotate Sun based on Roblox ClockTime (0 = Midnight, 6 = Sunrise, 12 = Noon, 18 = Sunset)
		var sun_angle_rad := deg_to_rad((clock_time - 6.0) * 15.0)
		directional_light.rotation_degrees = Vector3(rad_to_deg(-sin(sun_angle_rad)), rad_to_deg(cos(sun_angle_rad)), 0)

	# Apply Ambient Color
	if environment:
		environment.ambient_light_color = ambient_color
		
		# Apply Fog if enabled
		if fog_end < 10000.0:
			environment.fog_enabled = true
			environment.fog_light_color = fog_color
			environment.fog_density = 1.0 / max(fog_end, 1.0)

	print("[RobloxEnvironment] Applied Roblox Skybox & Lighting: ClockTime=%.1f, Brightness=%.1f" % [clock_time, brightness])
