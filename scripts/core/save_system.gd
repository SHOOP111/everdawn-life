class_name SaveSystem
extends RefCounted

const SAVE_PATH := "user://everdawn_save.json"
const SAVE_VERSION := 1

static func save_game(payload: Dictionary) -> bool:
	payload["version"] = SAVE_VERSION
	payload["saved_at_unix"] = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true

static func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("Save file is not a dictionary")
		return {}
	var data: Dictionary = parsed
	if int(data.get("version", -1)) != SAVE_VERSION:
		push_warning("Unsupported save version")
		return {}
	return data
