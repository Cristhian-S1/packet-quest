class_name Progression
extends RefCounted
## Reglas puras de progresión sobre el Dictionary de save.json.
## No escriben a disco: quien llama decide cuándo guardar (GameState.save()).

const DEFAULT_WEAPON: StringName = &"packet"
const MAX_WEAPONS: int = 2

static func owns(data: Dictionary, id: StringName) -> bool:
	if id == DEFAULT_WEAPON:
		return true
	return String(id) in (data.get("owned_upgrades", []) as Array)

static func can_buy(data: Dictionary, id: StringName) -> bool:
	var item: UpgradeData = Catalog.upgrade(id)
	return item != null and not owns(data, id) and int(data.get("data_cores", 0)) >= item.cost

static func buy(data: Dictionary, id: StringName) -> bool:
	if not can_buy(data, id):
		return false
	var item: UpgradeData = Catalog.upgrade(id)
	data["data_cores"] = int(data["data_cores"]) - item.cost
	(data["owned_upgrades"] as Array).append(String(id))
	if item.kind == UpgradeData.Kind.WEAPON and equipped_weapons(data).size() < MAX_WEAPONS:
		_set_weapons(data, equipped_weapons(data) + [id])
	elif item.kind == UpgradeData.Kind.PASSIVE and str(data.get("equipped", {}).get("passive", "")) == "":
		set_passive(data, id)
	return true

static func equipped_weapons(data: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	var equipment: Dictionary = data.get("equipped", {})
	for raw: Variant in equipment.get("weapons", []):
		var id: StringName = StringName(str(raw))
		if Catalog.weapon(id) != null and owns(data, id) and id not in result and result.size() < MAX_WEAPONS:
			result.append(id)
	if result.is_empty():
		result.append(DEFAULT_WEAPON)
	return result

static func toggle_weapon(data: Dictionary, id: StringName) -> bool:
	var current: Array[StringName] = equipped_weapons(data)
	if id in current:
		if current.size() <= 1:
			return false
		current.erase(id)
	else:
		if Catalog.weapon(id) == null or not owns(data, id) or current.size() >= MAX_WEAPONS:
			return false
		current.append(id)
	_set_weapons(data, current)
	return true

static func set_passive(data: Dictionary, id: StringName) -> bool:
	if id != &"":
		var item: UpgradeData = Catalog.upgrade(id)
		if item == null or item.kind != UpgradeData.Kind.PASSIVE or not owns(data, id):
			return false
	(data["equipped"] as Dictionary)["passive"] = String(id)
	return true

static func has_effect(data: Dictionary, id: StringName) -> bool:
	var item: UpgradeData = Catalog.upgrade(id)
	if item == null or not owns(data, id):
		return false
	if item.kind == UpgradeData.Kind.PASSIVE:
		return str(data.get("equipped", {}).get("passive", "")) == String(id)
	return true

static func _set_weapons(data: Dictionary, ids: Array) -> void:
	var stored: Array = []
	for id: Variant in ids:
		stored.append(str(id))
	(data["equipped"] as Dictionary)["weapons"] = stored
