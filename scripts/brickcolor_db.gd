class_name BrickColorDB
extends RefCounted

## BrickColor ID to RGB Color DB and Color3uint8 Decoder

const BRICK_COLORS: Dictionary = {
	1: Color(0.95, 0.95, 0.95),   # White
	2: Color(0.63, 0.63, 0.63),   # Grey
	3: Color(0.85, 0.70, 0.50),   # Light yellow
	5: Color(0.84, 0.38, 0.38),   # Brick red
	9: Color(0.90, 0.30, 0.30),   # Light red
	11: Color(0.50, 0.70, 0.90),  # Pastel Blue
	21: Color(0.75, 0.38, 0.20),  # Bright red
	23: Color(0.05, 0.40, 0.80),  # Deep blue
	24: Color(0.95, 0.95, 0.20),  # Yellow
	26: Color(0.15, 0.15, 0.15),  # Black
	27: Color(0.40, 0.40, 0.40),  # Dark grey
	28: Color(0.18, 0.48, 0.18),  # Dark green
	37: Color(0.20, 0.75, 0.20),  # Bright green
	38: Color(0.60, 0.20, 0.80),  # Violet
	101: Color(0.85, 0.55, 0.35), # Medium orange
	102: Color(0.35, 0.60, 0.85), # Medium blue
	106: Color(0.85, 0.65, 0.45), # Pastel orange
	119: Color(0.60, 0.75, 0.60), # Light green
	194: Color(0.64, 0.64, 0.64), # Medium stone grey
	199: Color(0.38, 0.38, 0.15), # Dark yellow
	1001: Color(0.95, 0.95, 0.95),# Institutional white
	1002: Color(0.80, 0.80, 0.80),# Mid gray
	1003: Color(0.10, 0.10, 0.10),# Really black
	1004: Color(0.90, 0.10, 0.10),# Really red
	1010: Color(0.00, 0.50, 1.00),# Really blue
	1020: Color(0.00, 0.80, 0.30) # Bright green
}

static func get_color(brick_color_id: int) -> Color:
	if BRICK_COLORS.has(brick_color_id):
		return BRICK_COLORS[brick_color_id]
	return Color(0.64, 0.64, 0.64)

static func parse_color3_uint(val: int) -> Color:
	var r = ((val >> 16) & 0xFF) / 255.0
	var g = ((val >> 8) & 0xFF) / 255.0
	var b = (val & 0xFF) / 255.0
	return Color(r, g, b, 1.0)

static func parse_color3_uint8(val: int) -> Color:
	var r = ((val >> 16) & 0xFF) / 255.0
	var g = ((val >> 8) & 0xFF) / 255.0
	var b = (val & 0xFF) / 255.0
	return Color(r, g, b, 1.0)
