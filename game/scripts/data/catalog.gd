class_name Catalog
extends RefCounted
## Acceso de solo lectura a las armas y mejoras definidas como Resources.

const WEAPONS: Array[WeaponData] = [
	preload("res://resources/weapons/packet.tres"),
	preload("res://resources/weapons/triple.tres"),
	preload("res://resources/weapons/ping.tres"),
]

## Mismo orden que la tabla de docs/03-mecanicas.md.
const UPGRADES: Array[UpgradeData] = [
	preload("res://resources/upgrades/more_health.tres"),
	preload("res://resources/upgrades/triple.tres"),
	preload("res://resources/upgrades/ping.tres"),
	preload("res://resources/upgrades/long_dash.tres"),
	preload("res://resources/upgrades/strong_firewall.tres"),
	preload("res://resources/upgrades/marker.tres"),
	preload("res://resources/upgrades/slowdown.tres"),
]

static func weapon(id: StringName) -> WeaponData:
	for item: WeaponData in WEAPONS:
		if item.id == id:
			return item
	return null

static func upgrade(id: StringName) -> UpgradeData:
	for item: UpgradeData in UPGRADES:
		if item.id == id:
			return item
	return null

static func upgrades() -> Array[UpgradeData]:
	return UPGRADES.duplicate()
