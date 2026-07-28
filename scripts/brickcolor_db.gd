class_name BrickColorDB
extends RefCounted

## Roblox BrickColor ID mapping to Godot Color
const COLOR_MAP: Dictionary = {
	1: Color(0.95, 0.95, 0.95),    # White
	2: Color(0.64, 0.64, 0.64),    # Grey
	5: Color(0.85, 0.52, 0.52),    # Brick red
	9: Color(0.91, 0.77, 0.77),    # Light reddish violet
	11: Color(0.50, 0.60, 0.80),   # Pastel Blue
	21: Color(0.77, 0.15, 0.15),   # Bright red
	22: Color(0.89, 0.60, 0.32),   # Medium reddish violet
	23: Color(0.05, 0.41, 0.85),   # Bright blue
	24: Color(0.96, 0.80, 0.19),   # Bright yellow
	26: Color(0.11, 0.11, 0.11),   # Black
	27: Color(0.43, 0.54, 0.39),   # Dark grey
	28: Color(0.16, 0.50, 0.22),   # Dark green
	37: Color(0.30, 0.76, 0.23),   # Bright green
	38: Color(0.62, 0.34, 0.76),   # Dark orange
	101: Color(0.86, 0.86, 0.86),  # Light grey
	102: Color(0.43, 0.63, 0.43),  # Medium green
	104: Color(0.47, 0.41, 0.29),  # Bright violet
	106: Color(0.64, 0.64, 0.64),  # Medium stone grey
	119: Color(0.64, 0.74, 0.84),  # Br. yellowish green
	141: Color(0.15, 0.28, 0.51),  # Earth green
	194: Color(0.64, 0.64, 0.64),  # Medium stone grey
	199: Color(0.38, 0.43, 0.43),  # Dark stone grey
	208: Color(0.89, 0.89, 0.89),  # Light stone grey
	217: Color(0.48, 0.48, 0.48),  # Brown
	226: Color(0.98, 0.98, 0.98),  # Cool yellow
	312: Color(0.32, 0.28, 0.28),  # Sand red
	1001: Color(0.97, 0.97, 0.97), # Institutional white
	1002: Color(0.80, 0.80, 0.80), # Mid gray
	1003: Color(0.10, 0.10, 0.10), # Really black
	1004: Color(0.86, 0.12, 0.12), # Really red
	1010: Color(0.00, 0.00, 0.00), # Topaz
	1020: Color(0.00, 0.70, 0.70), # Rust
	1030: Color(0.70, 0.50, 0.30), # Pastel brown
}

static func get_color(brick_color_id: int) -> Color:
	if COLOR_MAP.has(brick_color_id):
		return COLOR_MAP[brick_color_id]
	return Color(0.64, 0.64, 0.64) # Default medium stone grey

static func parse_color3_uint(val: int) -> Color:
	# Roblox Color3uint stores 0x00RRGGBB or 0xAARRGGBB integer
	var r = float((val >> 16) & 0xFF) / 255.0
	var g = float((val >> 8) & 0xFF) / 255.0
	var b = float(val & 0xFF) / 255.0
	return Color(r, g, b)
