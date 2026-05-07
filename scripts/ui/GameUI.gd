extends CanvasLayer

const MAX_MESSAGES: int = 5
const MESSAGE_LIFETIME: float = 4.5

var _health_bar: ProgressBar
var _hunger_bar: ProgressBar
var _day_label: Label
var _phase_label: Label
var _time_bar: ProgressBar

var _item_labels: Dictionary = {}
var _inv_panel: PanelContainer
var _craft_panel: PanelContainer
var _recipe_container: VBoxContainer
var _msg_container: VBoxContainer

var _inv_visible: bool = false
var _craft_visible: bool = false

var _player_stats: Node = null
var _inventory_manager: Node = null
var _crafting_manager: Node = null

var _msg_queue: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	GameEvents.message_requested.connect(_show_message)
	GameEvents.toggle_inventory_requested.connect(_toggle_inventory)
	GameEvents.toggle_crafting_requested.connect(_toggle_crafting)
	GameEvents.time_changed.connect(_on_time_changed)
	GameEvents.day_started.connect(_on_day_started)
	GameEvents.night_started.connect(_on_night_started)
	call_deferred("_connect_refs")

func _connect_refs() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		_player_stats = player.get_node_or_null("PlayerStats")
		if _player_stats:
			_player_stats.health_changed.connect(_on_health_changed)
			_player_stats.hunger_changed.connect(_on_hunger_changed)

	_inventory_manager = get_tree().get_first_node_in_group("inventory_manager")
	if _inventory_manager:
		_inventory_manager.inventory_changed.connect(_refresh_inventory_display)
		_refresh_inventory_display()

	_crafting_manager = get_tree().get_first_node_in_group("crafting_manager")
	_build_recipe_list()

# ──────────────────────────────────────────────────────────────────────────────
# UI Construction
# ──────────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_hud(root)
	_build_inventory_panel(root)
	_build_crafting_panel(root)
	_build_message_log(root)

func _build_hud(root: Control) -> void:
	var hud := PanelContainer.new()
	hud.set_anchor_and_offset(SIDE_LEFT, 0.0, 8.0)
	hud.set_anchor_and_offset(SIDE_TOP, 0.0, 8.0)
	hud.set_anchor_and_offset(SIDE_RIGHT, 0.0, 320.0)
	hud.set_anchor_and_offset(SIDE_BOTTOM, 0.0, 120.0)
	root.add_child(hud)

	var vbox := VBoxContainer.new()
	hud.add_child(vbox)

	# Day / phase row
	var row1 := HBoxContainer.new()
	vbox.add_child(row1)

	_day_label = Label.new()
	_day_label.text = "Day 1"
	_day_label.add_theme_font_size_override("font_size", 16)
	row1.add_child(_day_label)

	_phase_label = Label.new()
	_phase_label.text = "  [DAY]"
	_phase_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	row1.add_child(_phase_label)

	# Time bar
	_time_bar = ProgressBar.new()
	_time_bar.min_value = 0.0
	_time_bar.max_value = 1.0
	_time_bar.value = 0.0
	_time_bar.custom_minimum_size = Vector2(0.0, 10.0)
	vbox.add_child(_time_bar)

	# Health
	var h_row := HBoxContainer.new()
	vbox.add_child(h_row)
	var h_lbl := Label.new()
	h_lbl.text = "Health: "
	h_lbl.add_theme_font_size_override("font_size", 13)
	h_row.add_child(h_lbl)
	_health_bar = ProgressBar.new()
	_health_bar.min_value = 0.0
	_health_bar.max_value = 100.0
	_health_bar.value = 100.0
	_health_bar.custom_minimum_size = Vector2(140.0, 18.0)
	h_row.add_child(_health_bar)

	# Hunger
	var g_row := HBoxContainer.new()
	vbox.add_child(g_row)
	var g_lbl := Label.new()
	g_lbl.text = "Vitality:"
	g_lbl.add_theme_font_size_override("font_size", 13)
	g_row.add_child(g_lbl)
	_hunger_bar = ProgressBar.new()
	_hunger_bar.min_value = 0.0
	_hunger_bar.max_value = 100.0
	_hunger_bar.value = 100.0
	_hunger_bar.custom_minimum_size = Vector2(140.0, 18.0)
	g_row.add_child(_hunger_bar)

	# Small inventory row
	var inv_row := HBoxContainer.new()
	vbox.add_child(inv_row)
	var items := ["straw", "stick", "cloth", "stone", "seed", "berry"]
	for item_id: String in items:
		var lbl := Label.new()
		lbl.text = "%s:0" % item_id.substr(0, 2)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.custom_minimum_size = Vector2(38.0, 0.0)
		inv_row.add_child(lbl)
		_item_labels[item_id] = lbl

	# Controls hint
	var hint := Label.new()
	hint.text = "[I] Inventory  [C] Craft  [E] Interact"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(hint)

func _build_inventory_panel(root: Control) -> void:
	_inv_panel = PanelContainer.new()
	_inv_panel.set_anchor_and_offset(SIDE_LEFT, 1.0, -280.0)
	_inv_panel.set_anchor_and_offset(SIDE_TOP, 0.0, 8.0)
	_inv_panel.set_anchor_and_offset(SIDE_RIGHT, 1.0, -8.0)
	_inv_panel.set_anchor_and_offset(SIDE_BOTTOM, 0.0, 300.0)
	_inv_panel.visible = false
	root.add_child(_inv_panel)

	var vbox := VBoxContainer.new()
	_inv_panel.add_child(vbox)

	var title := Label.new()
	title.text = "─ INVENTORY ─"
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)

	var items := ["straw", "stick", "cloth", "stone", "seed", "berry"]
	var names := ["Straw", "Stick", "Cloth", "Stone", "Seed", "Berry"]
	for i: int in range(items.size()):
		var row := HBoxContainer.new()
		vbox.add_child(row)
		var name_lbl := Label.new()
		name_lbl.text = names[i] + ":"
		name_lbl.custom_minimum_size = Vector2(70.0, 0.0)
		row.add_child(name_lbl)
		var count_lbl := Label.new()
		count_lbl.text = "0"
		count_lbl.name = "inv_" + items[i]
		row.add_child(count_lbl)

	var close_btn := Button.new()
	close_btn.text = "Close [I]"
	close_btn.pressed.connect(_toggle_inventory)
	vbox.add_child(close_btn)

func _build_crafting_panel(root: Control) -> void:
	_craft_panel = PanelContainer.new()
	_craft_panel.set_anchor_and_offset(SIDE_LEFT, 0.5, -180.0)
	_craft_panel.set_anchor_and_offset(SIDE_TOP, 0.0, 8.0)
	_craft_panel.set_anchor_and_offset(SIDE_RIGHT, 0.5, 180.0)
	_craft_panel.set_anchor_and_offset(SIDE_BOTTOM, 0.0, 440.0)
	_craft_panel.visible = false
	root.add_child(_craft_panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360.0, 400.0)
	_craft_panel.add_child(scroll)

	_recipe_container = VBoxContainer.new()
	scroll.add_child(_recipe_container)

	var title := Label.new()
	title.text = "─ CRAFTING ─"
	title.add_theme_font_size_override("font_size", 15)
	_recipe_container.add_child(title)

func _build_recipe_list() -> void:
	if _crafting_manager == null:
		return
	for child: Node in _recipe_container.get_children():
		if child is Button or child.get_class() == "PanelContainer":
			child.queue_free()

	for recipe: Dictionary in _crafting_manager.recipes:
		var row := HBoxContainer.new()
		_recipe_container.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var name_lbl := Label.new()
		name_lbl.text = recipe["display_name"]
		name_lbl.add_theme_font_size_override("font_size", 13)
		info.add_child(name_lbl)

		var cost_str := ""
		for item: String in recipe["cost"]:
			cost_str += "%s:%d  " % [item, recipe["cost"][item]]
		var cost_lbl := Label.new()
		cost_lbl.text = cost_str.strip_edges()
		cost_lbl.add_theme_font_size_override("font_size", 11)
		cost_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
		info.add_child(cost_lbl)

		var btn := Button.new()
		btn.text = "Craft"
		btn.custom_minimum_size = Vector2(60.0, 0.0)
		btn.pressed.connect(_on_craft_pressed.bind(recipe["id"]))
		btn.name = "craft_btn_" + recipe["id"]
		row.add_child(btn)

	var close_btn := Button.new()
	close_btn.text = "Close [C]"
	close_btn.pressed.connect(_toggle_crafting)
	_recipe_container.add_child(close_btn)

func _build_message_log(root: Control) -> void:
	_msg_container = VBoxContainer.new()
	_msg_container.set_anchor_and_offset(SIDE_LEFT, 0.0, 8.0)
	_msg_container.set_anchor_and_offset(SIDE_TOP, 1.0, -180.0)
	_msg_container.set_anchor_and_offset(SIDE_RIGHT, 0.6, 0.0)
	_msg_container.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -8.0)
	_msg_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_msg_container)

# ──────────────────────────────────────────────────────────────────────────────
# Callbacks
# ──────────────────────────────────────────────────────────────────────────────

func _on_health_changed(new_health: float, max_health: float) -> void:
	if _health_bar:
		_health_bar.max_value = max_health
		_health_bar.value = new_health

func _on_hunger_changed(new_hunger: float, max_hunger: float) -> void:
	if _hunger_bar:
		_hunger_bar.max_value = max_hunger
		_hunger_bar.value = new_hunger

func _refresh_inventory_display() -> void:
	if _inventory_manager == null:
		return
	for item_id: String in _item_labels:
		var count: int = _inventory_manager.get_item_count(item_id)
		(_item_labels[item_id] as Label).text = "%s:%d" % [item_id.substr(0, 2), count]

	if _inv_visible:
		_update_full_inventory()

	_update_craft_buttons()

func _update_full_inventory() -> void:
	if _inv_panel == null or _inventory_manager == null:
		return
	var items := ["straw", "stick", "cloth", "stone", "seed", "berry"]
	for item_id: String in items:
		var lbl := _inv_panel.find_child("inv_" + item_id, true, false) as Label
		if lbl:
			lbl.text = str(_inventory_manager.get_item_count(item_id))

func _update_craft_buttons() -> void:
	if _crafting_manager == null or not _craft_visible:
		return
	for recipe: Dictionary in _crafting_manager.recipes:
		var btn := _recipe_container.find_child("craft_btn_" + recipe["id"], true, false) as Button
		if btn:
			btn.disabled = not _crafting_manager.can_craft(recipe["id"])

func _on_time_changed(normalized: float) -> void:
	if _time_bar:
		_time_bar.value = normalized

func _on_day_started(day_count: int) -> void:
	if _day_label:
		_day_label.text = "Day %d" % day_count
	if _phase_label:
		_phase_label.text = "  [DAY]"
		_phase_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

func _on_night_started(day_count: int) -> void:
	if _day_label:
		_day_label.text = "Night %d" % day_count
	if _phase_label:
		_phase_label.text = "  [NIGHT]"
		_phase_label.add_theme_color_override("font_color", Color(0.4, 0.5, 1.0))

func _toggle_inventory() -> void:
	_inv_visible = not _inv_visible
	if _inv_panel:
		_inv_panel.visible = _inv_visible
	if _inv_visible:
		_update_full_inventory()

func _toggle_crafting() -> void:
	_craft_visible = not _craft_visible
	if _craft_panel:
		_craft_panel.visible = _craft_visible
	if _craft_visible:
		_update_craft_buttons()

func _on_craft_pressed(recipe_id: String) -> void:
	if _crafting_manager:
		_crafting_manager.craft(recipe_id)
		_update_craft_buttons()

func _show_message(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_msg_container.add_child(lbl)

	while _msg_container.get_child_count() > MAX_MESSAGES:
		_msg_container.get_child(0).queue_free()

	var timer := get_tree().create_timer(MESSAGE_LIFETIME)
	timer.timeout.connect(lbl.queue_free)
