class_name QuestSystem
extends RefCounted

var quests: Array[Dictionary] = [
	{"title": "Roots in New Soil", "description": "Till and plant your first garden plot.", "type": "plant", "target": 1, "progress": 0, "reward": "The valley remembers care.", "done": false},
	{"title": "Names Become Neighbors", "description": "Speak with three townsfolk.", "type": "talk", "target": 3, "progress": 0, "reward": "+15 community renown", "done": false},
	{"title": "A Small Abundance", "description": "Harvest five crops.", "type": "harvest", "target": 5, "progress": 0, "reward": "A new seed variety", "done": false},
]
var renown: int = 0
var event_log: Array[String] = ["You arrived in Everdawn Valley."]

func record(kind: String, amount: int = 1, detail: String = "") -> void:
	for quest in quests:
		if not bool(quest.done) and str(quest.type) == kind:
			quest.progress = mini(int(quest.progress) + amount, int(quest.target))
			if int(quest.progress) >= int(quest.target):
				quest.done = true
				renown += 15
				log_event("Completed: %s" % quest.title)
	if not detail.is_empty():
		log_event(detail)

func log_event(text: String) -> void:
	event_log.push_front(text)
	if event_log.size() > 12:
		event_log.pop_back()

func journal_text() -> String:
	var lines := ["[font_size=22][color=#f5d98b]EVERDAWN JOURNAL[/color][/font_size]", "[color=#a6cfd1]Community renown: %d[/color]" % renown, ""]
	for quest in quests:
		var mark := "✓" if bool(quest.done) else "◇"
		lines.append("[color=#f4e5bd]%s %s[/color]" % [mark, quest.title])
		lines.append("  %s" % quest.description)
		lines.append("  [color=#8fc59b]%d / %d[/color]  %s" % [quest.progress, quest.target, quest.reward])
		lines.append("")
	lines.append("[color=#f5d98b]Recent memories[/color]")
	for event in event_log.slice(0, 5):
		lines.append("• %s" % event)
	return "\n".join(lines)

func to_dict() -> Dictionary:
	return {"quests": quests, "renown": renown, "event_log": event_log}

func from_dict(data: Dictionary) -> void:
	quests = data.get("quests", quests)
	renown = int(data.get("renown", renown))
	event_log.clear()
	for event in data.get("event_log", []):
		event_log.append(str(event))
