class_name GameHUD
extends CanvasLayer

var clock_label: Label
var date_label: Label
var weather_label: Label
var tool_label: Label
var stamina_bar: ProgressBar
var prompt_label: Label
var toast_label: Label
var dialogue_panel: PanelContainer
var speaker_label: Label
var dialogue_label: Label
var journal_panel: PanelContainer
var journal_text: RichTextLabel
var inventory_panel: PanelContainer
var inventory_label: Label
var help_label: Label
var toast_timer: float = 0.0
var dialogue_timer: float = 0.0
var journal_open: bool = false

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
	_create_journal(root)
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
	panel.size = Vector2(260, 49)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("d9223038")))
	root.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	panel.add_child(rows)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
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
	weather_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(weather_label)
	var save_hint := _make_label("F5 save · F9 load", 9, Color("9aab9b"))
	row2.add_child(save_hint)

func _create_tool_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(8, -54)
	panel.size = Vector2(195, 46)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("df223038")))
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)
	tool_label = _make_label("HOE  ·  Q to cycle", 12, Color("ffdb7d"))
	box.add_child(tool_label)
	var stamina_row := HBoxContainer.new()
	box.add_child(stamina_row)
	stamina_row.add_child(_make_label("STAMINA ", 8, Color("a8c6af")))
	stamina_bar = ProgressBar.new()
	stamina_bar.custom_minimum_size = Vector2(105, 7)
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
	prompt_label.position = Vector2(-170, -59)
	prompt_label.size = Vector2(340, 22)
	root.add_child(prompt_label)
	toast_label = _make_label("Welcome to Everdawn Valley", 11, Color("fff2c9"))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.position = Vector2(-180, 65)
	toast_label.size = Vector2(360, 22)
	root.add_child(toast_label)
	toast_timer = 4.0

func _create_dialogue(root: Control) -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.position = Vector2(-230, -104)
	dialogue_panel.size = Vector2(460, 72)
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

func _create_journal(root: Control) -> void:
	journal_panel = PanelContainer.new()
	journal_panel.set_anchors_preset(Control.PRESET_CENTER)
	journal_panel.position = Vector2(-220, -145)
	journal_panel.size = Vector2(440, 290)
	journal_panel.add_theme_stylebox_override("panel", _panel_style(Color("f51c292e"), Color("d6ad64"), 2))
	journal_panel.visible = false
	root.add_child(journal_panel)
	var box := VBoxContainer.new()
	journal_panel.add_child(box)
	journal_text = RichTextLabel.new()
	journal_text.bbcode_enabled = true
	journal_text.fit_content = false
	journal_text.scroll_active = true
	journal_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_text.add_theme_font_size_override("normal_font_size", 11)
	box.add_child(journal_text)
	var close := _make_label("J / TAB — close journal", 9, Color("8ea6a0"))
	close.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(close)

func _create_inventory(root: Control) -> void:
	inventory_panel = PanelContainer.new()
	inventory_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	inventory_panel.position = Vector2(-180, 7)
	inventory_panel.size = Vector2(172, 79)
	inventory_panel.add_theme_stylebox_override("panel", _panel_style(Color("d9223038")))
	root.add_child(inventory_panel)
	inventory_label = _make_label("PACK\nSeeds × 12   Wood × 8", 9, Color("d8e3c1"))
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_panel.add_child(inventory_label)

func _create_help(root: Control) -> void:
	help_label = _make_label("WASD move  ·  SHIFT sprint  ·  SPACE use tool  ·  E talk  ·  J journal", 8, Color("9db0a9"))
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	help_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	help_label.position = Vector2(-420, -19)
	help_label.size = Vector2(412, 12)
	root.add_child(help_label)

func update_hud(clock: GameClock, player: PlayerController, farm: FarmSystem, prompt: String) -> void:
	clock_label.text = clock.time_string()
	date_label.text = "%s · %s %d · Year %d" % [clock.weekday_name(), clock.season_name(), clock.day_of_season(), clock.year]
	var icon := {"Clear": "☀", "Rain": "☂", "Drizzle": "☂", "Storm": "ϟ", "Snow": "✦", "Mist": "≋", "Windy": "≈", "Sunshower": "☀"}.get(clock.weather, "·")
	weather_label.text = "%s  %s" % [icon, clock.weather]
	tool_label.text = "%s  ·  Q to cycle" % player.current_tool().to_upper()
	stamina_bar.value = player.stamina
	prompt_label.text = prompt
	var items: Array[String] = []
	for key in farm.inventory:
		var amount := int(farm.inventory[key])
		if amount > 0:
			items.append("%s × %d" % [str(key).replace(" Seeds", " seed"), amount])
	inventory_label.text = "PACK\n" + "   ".join(items.slice(0, 5))

func tick(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		toast_label.modulate.a = clampf(toast_timer * 2.0, 0.0, 1.0)
	if dialogue_timer > 0.0:
		dialogue_timer -= delta
		if dialogue_timer <= 0.0:
			dialogue_panel.visible = false

func toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	toast_timer = 3.2

func dialogue(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	dialogue_label.text = text
	dialogue_panel.visible = true
	dialogue_timer = 6.0

func toggle_journal(quests: QuestSystem) -> bool:
	journal_open = not journal_open
	journal_panel.visible = journal_open
	journal_text.text = quests.journal_text()
	dialogue_panel.visible = false
	return journal_open
