class_name GameHUD
extends CanvasLayer

var clock_label: Label
var date_label: Label
var weather_label: Label
var region_label: Label
var tool_label: Label
var vitals_label: Label
var stamina_bar: ProgressBar
var prompt_label: Label
var toast_label: Label
var region_banner_label: Label
var dialogue_panel: PanelContainer
var speaker_label: Label
var dialogue_label: Label
var menu_panel: PanelContainer
var menu_text: RichTextLabel
var menu_hint: Label
var inventory_panel: PanelContainer
var inventory_label: Label
var help_label: Label
var toast_timer := 0.0
var dialogue_timer := 0.0
var region_timer := 0.0
var journal_open := false
var active_panel := ""

func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.name = "Interface"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_create_top_bar(root)
	_create_tool_panel(root)
	_create_prompt(root)
	_create_dialogue(root)
	_create_menu(root)
	_create_inventory(root)
	_create_help(root)

func _panel_style(color: Color, border := Color("d3af69"), width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _make_label(text: String, size: int = 12, color := Color("f7e8c4")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _create_top_bar(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(8, 7)
	panel.size = Vector2(300, 63)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("df223038")))
	root.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	panel.add_child(rows)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	rows.add_child(row)
	clock_label = _make_label("7:00 AM", 16, Color("ffde88"))
	clock_label.custom_minimum_size.x = 82
	row.add_child(clock_label)
	date_label = _make_label("Moonday · Bloomtide 1", 11)
	date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(date_label)
	var row2 := HBoxContainer.new()
	rows.add_child(row2)
	weather_label = _make_label("☀ Clear", 10, Color("a9d8d0"))
	weather_label.custom_minimum_size.x = 90
	row2.add_child(weather_label)
	region_label = _make_label("Everdawn Village", 10, Color("c6d9b3"))
	region_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(region_label)
	vitals_label = _make_label("❤ 100  ◈ 180", 9, Color("e8b78d"))
	rows.add_child(vitals_label)

func _create_tool_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(8, -57)
	panel.size = Vector2(210, 49)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("e5223038")))
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)
	tool_label = _make_label("HOE  ·  Q cycle", 12, Color("ffdb7d"))
	box.add_child(tool_label)
	var stamina_row := HBoxContainer.new()
	box.add_child(stamina_row)
	stamina_row.add_child(_make_label("STAMINA ", 8, Color("a8c6af")))
	stamina_bar = ProgressBar.new()
	stamina_bar.custom_minimum_size = Vector2(118, 7)
	stamina_bar.max_value = 100
	stamina_bar.value = 100
	stamina_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("263a3b")
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("7fc16a")
	stamina_bar.add_theme_stylebox_override("background", bg)
	stamina_bar.add_theme_stylebox_override("fill", fill)
	stamina_row.add_child(stamina_bar)

func _create_prompt(root: Control) -> void:
	prompt_label = _make_label("", 10, Color("fff0b5"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-190, -59)
	prompt_label.size = Vector2(380, 22)
	root.add_child(prompt_label)
	toast_label = _make_label("Welcome to Everdawn Valley", 11, Color("fff2c9"))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.position = Vector2(-220, 72)
	toast_label.size = Vector2(440, 22)
	root.add_child(toast_label)
	region_banner_label = _make_label("", 20, Color("ffdc85"))
	region_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_banner_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	region_banner_label.position = Vector2(-250, 108)
	region_banner_label.size = Vector2(500, 32)
	region_banner_label.modulate.a = 0.0
	root.add_child(region_banner_label)
	toast_timer = 4.0

func _create_dialogue(root: Control) -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.position = Vector2(-240, -108)
	dialogue_panel.size = Vector2(480, 76)
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style(Color("f019252b"), Color("e2bf78"), 2))
	dialogue_panel.visible = false
	root.add_child(dialogue_panel)
	var box := VBoxContainer.new()
	dialogue_panel.add_child(box)
	speaker_label = _make_label("Mara", 13, Color("ffd873"))
	box.add_child(speaker_label)
	dialogue_label = _make_label("", 11)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(dialogue_label)

func _create_menu(root: Control) -> void:
	menu_panel = PanelContainer.new()
	menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	menu_panel.position = Vector2(-240, -155)
	menu_panel.size = Vector2(480, 310)
	menu_panel.add_theme_stylebox_override("panel", _panel_style(Color("f51c292e"), Color("d6ad64"), 2))
	menu_panel.visible = false
	root.add_child(menu_panel)
	var box := VBoxContainer.new()
	menu_panel.add_child(box)
	menu_text = RichTextLabel.new()
	menu_text.bbcode_enabled = true
	menu_text.fit_content = false
	menu_text.scroll_active = true
	menu_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_text.add_theme_font_size_override("normal_font_size", 11)
	box.add_child(menu_text)
	menu_hint = _make_label("", 9, Color("8ea6a0"))
	menu_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(menu_hint)

func _create_inventory(root: Control) -> void:
	inventory_panel = PanelContainer.new()
	inventory_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	inventory_panel.position = Vector2(-202, 7)
	inventory_panel.size = Vector2(194, 92)
	inventory_panel.add_theme_stylebox_override("panel", _panel_style(Color("df223038")))
	root.add_child(inventory_panel)
	inventory_label = _make_label("PACK\nSeeds × 12   Wood × 8", 9, Color("d8e3c1"))
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_panel.add_child(inventory_label)

func _create_help(root: Control) -> void:
	help_label = _make_label("WASD move · SHIFT run · SPACE use · E interact · J journal · C craft · M market", 8, Color("9db0a9"))
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	help_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	help_label.position = Vector2(-500, -19)
	help_label.size = Vector2(492, 12)
	root.add_child(help_label)

func update_hud(clock: GameClock, player: PlayerController, farm: FarmSystem, economy: EconomySystem,
		skills: SkillSystem, region: String, crafting: CraftingSystem, festivals: FestivalSystem, prompt: String) -> void:
	clock_label.text = clock.time_string()
	date_label.text = "%s · %s %d · Y%d" % [clock.weekday_name(), clock.season_name(), clock.day_of_season(), clock.year]
	var icon: String = str({"Clear": "☀", "Rain": "☂", "Drizzle": "☂", "Storm": "ϟ", "Snow": "✦", "Mist": "≋", "Windy": "≈", "Sunshower": "☀"}.get(clock.weather, "·"))
	weather_label.text = "%s  %s" % [icon, clock.weather]
	region_label.text = region
	vitals_label.text = "❤ %d  ❄ %d  ◈ %d petals  ✦ %d skill" % [roundi(player.health), roundi(player.warmth), economy.coins, skills.total_levels]
	tool_label.text = "%s  ·  Q cycle" % player.current_tool().to_upper()
	if player.current_tool() == "Seeds":
		tool_label.text += "  ·  R %s" % FarmSystem.CROP_NAMES[farm.selected_seed]
	stamina_bar.value = player.stamina
	prompt_label.text = prompt
	var items: Array[String] = []
	for key in farm.inventory:
		var amount := int(farm.inventory[key])
		if amount > 0:
			items.append("%s × %d" % [str(key).replace(" Seeds", " seed"), amount])
	inventory_label.text = "PACK  ·  %d kinds\n%s" % [items.size(), "   ".join(items.slice(0, 7))]

func tick(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		toast_label.modulate.a = clampf(toast_timer * 2.0, 0.0, 1.0)
	if dialogue_timer > 0.0:
		dialogue_timer -= delta
		if dialogue_timer <= 0.0:
			dialogue_panel.visible = false
	if region_timer > 0.0:
		region_timer -= delta
		region_banner_label.modulate.a = clampf(minf(region_timer, 2.0 - region_timer) * 1.5, 0.0, 1.0)

func toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	toast_timer = 3.2

func region_banner(region: String) -> void:
	region_banner_label.text = "◇  %s  ◇" % region
	region_banner_label.modulate.a = 1.0
	region_timer = 3.5

func dialogue(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	dialogue_label.text = text
	dialogue_panel.visible = true
	dialogue_timer = 6.0

func _toggle_panel(panel_name: String) -> bool:
	if active_panel == panel_name and menu_panel.visible:
		active_panel = ""
		journal_open = false
		menu_panel.visible = false
		return false
	active_panel = panel_name
	journal_open = true
	menu_panel.visible = true
	dialogue_panel.visible = false
	return true

func toggle_journal(quests: QuestSystem, skills: SkillSystem, economy: EconomySystem, festivals: FestivalSystem) -> bool:
	var opened := _toggle_panel("journal")
	if opened:
		menu_text.text = quests.journal_text() + "\n\n" + skills.journal_text() + "\n\n[color=#f5d98b]CALENDAR[/color]\n" + festivals.upcoming(maxi(1, economy.market_day)) + "\nValley prosperity: %d%%" % roundi(economy.prosperity)
		menu_hint.text = "J / TAB — close"
	return opened

func toggle_crafting(crafting: CraftingSystem, skills: SkillSystem, inventory: Dictionary) -> bool:
	var opened := _toggle_panel("crafting")
	if opened:
		refresh_crafting(crafting, skills, inventory)
	return opened

func refresh_crafting(crafting: CraftingSystem, skills: SkillSystem, inventory: Dictionary) -> void:
	if active_panel != "crafting":
		return
	menu_text.text = "[font_size=22][color=#f5d98b]WORKSHOP[/color][/font_size]\n[color=#a6cfd1]Crafting level %d[/color]\n\n%s\n\n[color=#8fc59b]Objects made: %d[/color]" % [skills.level("Crafting"), crafting.recipe_text(skills.level("Crafting"), inventory), crafting.crafted_total]
	menu_hint.text = "← → recipe  ·  ENTER craft  ·  C close"

func toggle_market(economy: EconomySystem, inventory: Dictionary = {}) -> bool:
	var opened := _toggle_panel("market")
	if opened:
		refresh_market(economy, inventory)
	return opened

func refresh_market(economy: EconomySystem, inventory: Dictionary) -> void:
	if active_panel != "market":
		return
	menu_text.text = economy.market_text(inventory) + "\n\n[color=#8ea6a0]Prices move daily with supply, demand, and valley prosperity.[/color]"
	menu_hint.text = "← → select  ·  ENTER sell one  ·  M close"
