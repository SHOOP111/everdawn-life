class_name EconomySystem
extends RefCounted

const BASE_PRICES := {
	"Turnip": 18, "Moonbean": 32, "Sunroot": 48, "Bluebell": 25,
	"Wild Herb": 12, "Berry": 9, "Mushroom": 16, "Fish": 28,
	"Wood": 7, "Stone": 8, "Crystal": 85, "Field Snack": 44,
	"Herbal Tonic": 92, "Bee House": 210, "Preserves Jar": 260, "Moon Lantern": 420,
}

var coins: int = 180
var prosperity: float = 42.0
var demand: Dictionary = {}
var market_day: int = 0
var lifetime_earned: int = 0
var lifetime_spent: int = 0
var selected_market_item: int = 0
var market_items: Array[String] = ["Turnip", "Moonbean", "Sunroot", "Bluebell", "Wild Herb", "Berry", "Mushroom", "Fish", "Wood", "Stone", "Crystal", "Field Snack", "Herbal Tonic"]

func _init() -> void:
	for item_name in BASE_PRICES:
		demand[item_name] = 1.0

func advance_day(day: int, season: int) -> void:
	market_day = day
	var prosperity_pull := (prosperity - 50.0) * 0.002
	for item_name in BASE_PRICES:
		var hash := _hash_text(str(item_name), day * 17 + season * 101)
		var old_value := float(demand.get(item_name, 1.0))
		var target := 0.72 + hash * 0.66 + prosperity_pull
		demand[item_name] = clampf(lerpf(old_value, target, 0.38), 0.62, 1.58)
	prosperity = clampf(prosperity - 0.08, 0.0, 100.0)

func price(item_name: String) -> int:
	if not BASE_PRICES.has(item_name):
		return 1
	return maxi(1, roundi(float(BASE_PRICES[item_name]) * float(demand.get(item_name, 1.0))))

func sell_one(item_name: String, inventory: Dictionary) -> String:
	if int(inventory.get(item_name, 0)) <= 0:
		return "You have no %s to sell." % item_name
	inventory[item_name] = int(inventory[item_name]) - 1
	var value := price(item_name)
	coins += value
	lifetime_earned += value
	prosperity = minf(100.0, prosperity + 0.12)
	demand[item_name] = maxf(0.62, float(demand.get(item_name, 1.0)) - 0.025)
	return "Sold %s for %d petals." % [item_name, value]

func buy_seeds(seed_name: String, inventory: Dictionary) -> String:
	var crop_name := seed_name.replace(" Seeds", "")
	var cost := maxi(5, int(float(price(crop_name)) * 0.55))
	if coins < cost:
		return "You need %d petals." % cost
	coins -= cost
	lifetime_spent += cost
	inventory[seed_name] = int(inventory.get(seed_name, 0)) + 3
	prosperity = minf(100.0, prosperity + 0.05)
	return "Bought 3 %s for %d petals." % [seed_name, cost]

func cycle_market(direction: int) -> String:
	selected_market_item = posmod(selected_market_item + direction, market_items.size())
	return market_items[selected_market_item]

func selected_item() -> String:
	return market_items[selected_market_item]

func market_text(inventory: Dictionary = {}) -> String:
	var lines: Array[String] = ["[font_size=20][color=#f5d98b]VALLEY MARKET[/color][/font_size]", "Petals: %d   Prosperity: %d%%" % [coins, roundi(prosperity)], ""]
	for item_name in market_items:
		var marker := "[color=#ffdc85]▶[/color]" if item_name == selected_item() else " "
		var held := int(inventory.get(item_name, 0))
		var trend := "▲" if float(demand.get(item_name, 1.0)) > 1.05 else ("▼" if float(demand.get(item_name, 1.0)) < 0.95 else "—")
		lines.append("%s %s  %-14s  %3d petals   held %d" % [marker, trend, item_name, price(item_name), held])
	return "\n".join(lines)

func _hash_text(text: String, salt: int) -> float:
	var value := salt
	for character in text:
		value = int((value * 31 + character.unicode_at(0)) & 0x7fffffff)
	return float(value % 10000) / 9999.0

func to_dict() -> Dictionary:
	return {"coins": coins, "prosperity": prosperity, "demand": demand, "market_day": market_day,
		"earned": lifetime_earned, "spent": lifetime_spent, "selected_market_item": selected_market_item}

func from_dict(data: Dictionary) -> void:
	coins = int(data.get("coins", coins))
	prosperity = float(data.get("prosperity", prosperity))
	var loaded_demand: Dictionary = data.get("demand", {})
	for item_name in loaded_demand:
		demand[item_name] = float(loaded_demand[item_name])
	market_day = int(data.get("market_day", market_day))
	lifetime_earned = int(data.get("earned", 0))
	lifetime_spent = int(data.get("spent", 0))
	selected_market_item = clampi(int(data.get("selected_market_item", 0)), 0, market_items.size() - 1)
