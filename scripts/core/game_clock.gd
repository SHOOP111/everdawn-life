class_name GameClock
extends RefCounted

const SEASONS := ["Bloomtide", "Suncrest", "Amberfall", "Frostwane"]
const WEEKDAYS := ["Moonday", "Tidesday", "Woodsday", "Thundersday", "Freeday", "Starsday", "Sunsday"]
const WEATHER_BY_SEASON := {
	0: ["Clear", "Clear", "Drizzle", "Rain", "Mist"],
	1: ["Clear", "Clear", "Clear", "Sunshower", "Storm"],
	2: ["Clear", "Windy", "Rain", "Mist", "Storm"],
	3: ["Clear", "Snow", "Snow", "Windy", "Mist"],
}

var minute: float = 7.0 * 60.0
var day: int = 1
var year: int = 1
var weather: String = "Clear"
var weather_minutes_left: float = 360.0
var time_scale: float = 5.0
var paused: bool = false
var _weather_roll: int = 193

func advance(delta: float) -> Dictionary:
	var result := {"new_day": false, "weather_changed": false, "season_changed": false}
	if paused:
		return result
	var old_season := season_index()
	var passed := delta * time_scale
	minute += passed
	weather_minutes_left -= passed
	while minute >= 1440.0:
		minute -= 1440.0
		day += 1
		result.new_day = true
		if day > 112:
			day = 1
			year += 1
	if season_index() != old_season:
		result.season_changed = true
	if weather_minutes_left <= 0.0:
		_roll_weather()
		result.weather_changed = true
	return result

func _roll_weather() -> void:
	_weather_roll = int((_weather_roll * 1103515245 + day * 97 + year * 31) & 0x7fffffff)
	var choices: Array = WEATHER_BY_SEASON[season_index()]
	weather = choices[_weather_roll % choices.size()]
	weather_minutes_left = 180.0 + float(_weather_roll % 480)

func season_index() -> int:
	return mini((day - 1) / 28, 3)

func season_name() -> String:
	return SEASONS[season_index()]

func weekday_name() -> String:
	return WEEKDAYS[(day - 1) % 7]

func day_of_season() -> int:
	return ((day - 1) % 28) + 1

func hour() -> int:
	return int(minute) / 60

func time_string() -> String:
	var h := hour()
	var suffix := "AM" if h < 12 else "PM"
	var shown := h % 12
	if shown == 0:
		shown = 12
	return "%d:%02d %s" % [shown, int(minute) % 60, suffix]

func sun_strength() -> float:
	var h := minute / 60.0
	if h < 5.0 or h > 21.0:
		return 0.08
	if h < 7.0:
		return lerpf(0.08, 1.0, (h - 5.0) / 2.0)
	if h > 18.5:
		return lerpf(1.0, 0.08, (h - 18.5) / 2.5)
	return 1.0

func to_dict() -> Dictionary:
	return {"minute": minute, "day": day, "year": year, "weather": weather,
		"weather_left": weather_minutes_left, "roll": _weather_roll}

func from_dict(data: Dictionary) -> void:
	minute = float(data.get("minute", minute))
	day = int(data.get("day", day))
	year = int(data.get("year", year))
	weather = str(data.get("weather", weather))
	weather_minutes_left = float(data.get("weather_left", weather_minutes_left))
	_weather_roll = int(data.get("roll", _weather_roll))
