class_name FirewallFilter
extends RefCounted

enum { CIRCLE, TRIANGLE, SQUARE }
enum { RED, GREEN, BLUE }

const DEMO: Array[Vector2i] = [
	Vector2i(CIRCLE, RED), Vector2i(TRIANGLE, GREEN), Vector2i(SQUARE, RED),
	Vector2i(TRIANGLE, RED), Vector2i(TRIANGLE, BLUE), Vector2i(CIRCLE, GREEN),
	Vector2i(TRIANGLE, GREEN), Vector2i(SQUARE, BLUE), Vector2i(CIRCLE, BLUE),
	Vector2i(TRIANGLE, GREEN),
]

static func is_allowed(shape: int, color: int, allowed_shape: int, blocked_color: int) -> bool:
	return shape == allowed_shape and color != blocked_color

static func generate_sequence(seed: int) -> Array[Dictionary]:
	var sequence: Array[Dictionary] = []
	for packet: Vector2i in DEMO:
		sequence.append({"shape": packet.x, "color": packet.y})
	if seed != 0:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = seed
		for index: int in range(sequence.size() - 1, 0, -1):
			var swap: int = rng.randi_range(0, index)
			var packet: Dictionary = sequence[index]
			sequence[index] = sequence[swap]
			sequence[swap] = packet
	return sequence
