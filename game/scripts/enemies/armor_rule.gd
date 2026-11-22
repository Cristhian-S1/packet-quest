class_name ArmorRule
extends RefCounted

static func blocks(shooter: Vector2, body: Vector2, facing: Vector2) -> bool:
	return (shooter - body).dot(facing) > 0.0
