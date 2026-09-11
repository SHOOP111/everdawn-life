class_name SkillSystem
extends RefCounted

const SKILL_NAMES := ["Farming", "Foraging", "Fishing", "Crafting", "Social", "Exploration"]
const TITLES := ["Novice", "Apprentice", "Adept", "Expert", "Master", "Valley Sage"]

var skills: Dictionary = {}
var total_levels: int = 6

func _init() -> void:
	for skill_name in SKILL_NAMES:
		skills[skill_name] = {"level": 1, "xp": 0.0}

func xp_needed(level: int) -> float:
	return 70.0 + pow(float(level), 1.65) * 42.0

func add_xp(skill_name: String, amount: float) -> Array[String]:
	var messages: Array[String] = []
	if not skills.has(skill_name) or amount <= 0.0:
		return messages
	var data: Dictionary = skills[skill_name]
	data.xp = float(data.xp) + amount
	while int(data.level) < 30 and float(data.xp) >= xp_needed(int(data.level)):
		data.xp = float(data.xp) - xp_needed(int(data.level))
		data.level = int(data.level) + 1
		total_levels += 1
		messages.append("%s reached level %d — %s" % [skill_name, data.level, title_for_level(int(data.level))])
	skills[skill_name] = data
	return messages

func level(skill_name: String) -> int:
	if not skills.has(skill_name):
		return 1
	return int(skills[skill_name].level)

func progress(skill_name: String) -> float:
	if not skills.has(skill_name):
		return 0.0
	var data: Dictionary = skills[skill_name]
	return clampf(float(data.xp) / xp_needed(int(data.level)), 0.0, 1.0)

func title_for_level(skill_level: int) -> String:
	return TITLES[mini((skill_level - 1) / 5, TITLES.size() - 1)]

func yield_bonus(skill_name: String) -> float:
	return 1.0 + float(level(skill_name) - 1) * 0.055

func stamina_discount(skill_name: String) -> float:
	return clampf(1.0 - float(level(skill_name) - 1) * 0.018, 0.62, 1.0)

func journal_text() -> String:
	var lines: Array[String] = ["[font_size=20][color=#f5d98b]SKILLS[/color][/font_size]"]
	for skill_name in SKILL_NAMES:
		var data: Dictionary = skills[skill_name]
		var filled := int(progress(skill_name) * 12.0)
		var bar := "■".repeat(filled) + "□".repeat(12 - filled)
		lines.append("[color=#f1ddb1]%s %d[/color]  [color=#81b995]%s[/color]" % [skill_name, data.level, bar])
	return "\n".join(lines)

func to_dict() -> Dictionary:
	return {"skills": skills, "total_levels": total_levels}

func from_dict(data: Dictionary) -> void:
	var loaded: Dictionary = data.get("skills", {})
	for skill_name in SKILL_NAMES:
		if loaded.has(skill_name):
			skills[skill_name] = loaded[skill_name]
	total_levels = int(data.get("total_levels", total_levels))
