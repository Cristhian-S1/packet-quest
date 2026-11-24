class_name StageStats
extends RefCounted

const LEVEL_CORES: Array[Array] = [["w1_hidden_a"], ["w2_core_a", "w2_core_b"],
	["w3_core_a", "w3_core_b"], ["w4_core_a", "w4_core_b"], ["w5_core_a", "w5_core_b"]]
const LEGACY_BOSS_DEATHS: Array[Array] = [["router_boss", "router_boss_A", "router_boss_B", "router_boss_C"],
	["reina_wifi"], ["firewall_corrupto"], ["troyano_real"], ["malwarex"]]

static func id(world: int, boss: bool) -> String:
	return "w%d_boss" % world if boss else "w%d_l1" % world

static func entry(data: Dictionary, world: int, boss: bool) -> Dictionary:
	return data["stats"].get("levels", {}).get(id(world, boss), {})

static func core_count(data: Dictionary, world: int) -> int:
	var count: int = 0
	for core: String in LEVEL_CORES[world - 1]:
		if core in data["collected_cores"]:
			count += 1
	return count

static func format_time(seconds: Variant) -> String:
	if seconds == null:
		return "—"
	var centiseconds: int = floori(float(seconds) * 100.0)
	@warning_ignore("integer_division")
	var minutes: int = centiseconds / 6000
	@warning_ignore("integer_division")
	var whole_seconds: int = (centiseconds % 6000) / 100
	return "%02d:%02d.%02d" % [minutes, whole_seconds, centiseconds % 100]

static func summary(data: Dictionary, world: int, boss: bool, record: bool = false) -> String:
	var stats: Dictionary = entry(data, world, boss)
	var text: String = "%s   ·   Mejor %s   ·   Muertes %d   ·   Completado %d" % [
		"Jefe" if boss else "Nivel %d-1" % world, format_time(stats.get("best_time_s")),
		int(stats.get("deaths", 0)), int(stats.get("completions", 0))]
	if not boss:
		text += "   ·   Núcleos %d/%d" % [stats.get("cores_collected", 0), LEVEL_CORES[world - 1].size()]
	if record:
		text += "   ·   Nuevo récord"
	return text
