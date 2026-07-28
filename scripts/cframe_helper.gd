class_name CFrameHelper
extends RefCounted

## Converts Roblox 2017 XML CFrame parameters into a Godot Transform3D
static func create_transform(
	pos_x: float, pos_y: float, pos_z: float,
	r00: float, r01: float, r02: float,
	r10: float, r11: float, r12: float,
	r20: float, r21: float, r22: float
) -> Transform3D:
	var origin = Vector3(pos_x, pos_y, pos_z)
	
	# Construct basis vectors from Roblox CFrame rotation matrix columns
	var basis_x = Vector3(r00, r10, r20)
	var basis_y = Vector3(r01, r11, r21)
	var basis_z = Vector3(r02, r12, r22)
	
	# Ensure orthogonality and normalize to prevent floating-point skewing
	var basis = Basis(basis_x, basis_y, basis_z)
	basis = basis.orthonormalized()
	
	return Transform3D(basis, origin)

static func default_transform(position: Vector3) -> Transform3D:
	return Transform3D(Basis(), position)
