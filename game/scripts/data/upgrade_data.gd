class_name UpgradeData
extends Resource

enum Kind { WEAPON, PASSIVE, PERMANENT }
@export var id: StringName
@export var display_name: String
@export var description: String
@export var cost: int = 1
@export var kind: Kind = Kind.PASSIVE
