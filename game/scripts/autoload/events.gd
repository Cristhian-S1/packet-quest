extends Node

signal player_died
signal boss_defeated(id: StringName)
signal puzzle_solved(id: StringName)
signal checkpoint_reached(pos: Vector2)
signal core_collected(id: StringName)
signal impact(duration: float, shake: float)
