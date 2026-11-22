class_name BossPhaseData
extends Resource

@export var name: String = "Señal estable"
@export var health_threshold: float = 1.0
@export var attack_sequence: Array[StringName] = [&"A", &"B"]
@export var recovery_multiplier: float = 1.0
