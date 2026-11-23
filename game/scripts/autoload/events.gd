extends Node

# Este autoload declara las señales que se emiten y escuchan en otras escenas.
@warning_ignore_start("unused_signal")
signal player_died
signal boss_defeated(id: StringName)
signal puzzle_solved(id: StringName)
signal checkpoint_reached(pos: Vector2)
signal core_collected(id: StringName)
signal impact(duration: float, shake: float)
@warning_ignore_restore("unused_signal")
