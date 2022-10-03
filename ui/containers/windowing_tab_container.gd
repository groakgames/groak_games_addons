class_name WindowingTabContainer extends TabContainer

@export var remove_when_empty: bool = false

@export var drag_to_popout_as_window: bool = false

@export var window_type: Script = SelfRemovingWindow

@export_group("TabBar Properties")

@export var max_tab_width: int = 0:
	get: return max_tab_width if Engine.is_editor_hint() or not _tab_bar else _tab_bar.max_tab_width
	set(value):
		if Engine.is_editor_hint(): max_tab_width = value
		_tab_bar.max_tab_width = value

@export var scroll_to_selected: bool = true:
	get: return scroll_to_selected if Engine.is_editor_hint() or not _tab_bar else _tab_bar.scroll_to_selected
	set(value):
		if Engine.is_editor_hint(): scroll_to_selected = value
		_tab_bar.scroll_to_selected = value

@export var scrolling_enabled: bool = true:
	get: return scrolling_enabled if Engine.is_editor_hint() or not _tab_bar else _tab_bar.scrolling_enabled
	set(value):
		if Engine.is_editor_hint(): scrolling_enabled = value
		_tab_bar.scrolling_enabled = value

@export var select_with_rmb: bool = false:
	get: return select_with_rmb if Engine.is_editor_hint() or not _tab_bar else _tab_bar.select_with_rmb
	set(value):
		if Engine.is_editor_hint(): select_with_rmb = value
		_tab_bar.select_with_rmb = value

@export var tab_close_display_policy: TabBar.CloseButtonDisplayPolicy = TabBar.CLOSE_BUTTON_SHOW_NEVER:
	get: return tab_close_display_policy if Engine.is_editor_hint() or not _tab_bar else _tab_bar.tab_close_display_policy
	set(value):
		if Engine.is_editor_hint(): tab_close_display_policy = value
		_tab_bar.tab_close_display_policy = value

@export_group("Popout Drag Modifiers")
@export_flags("Shift", "Ctrl/Cmd", "Alt", "Meta") var popout_drag_modifiers: int = 1

var tab_root: Control

#
# Signals
#

signal active_tab_rearranged(idx_to: int)

signal tab_clicked(tab: int)

signal tab_close_pressed(tab: int)

signal tab_hovered(tab: int)

signal tab_rmb_clicked(tab: int)

#
# Public Functions
#

func popout_tab_as_window(tab_idx:int, popup_position := Vector2i.ZERO, popup_size := Vector2i.ZERO)->TabTreeWindow:
	assert(tab_idx >= 0 and tab_idx < get_tab_count())
	var control: Control = get_tab_control(tab_idx)

	remove_child(control)

	var w: Window = window_type.new() as Window
	assert(w != null)
	w.mode = Window.MODE_WINDOWED
	#w.popup_window = false
	w.borderless = false
	#w.position = Vector2(200,200)
	#w.size = Vector2.ZERO
	if popup_size == Vector2i.ZERO:
		popup_size = DisplayServer.screen_get_size() / 2
	w.size = popup_size
	#w.always_on_top = true
	#w.set_flag(Window.FLAG_RESIZE_DISABLED, true)
	w.transient = false
	w.position = popup_position
	#w.transient = true

	var tce := WindowingTabContainer.new()
	tce.remove_when_empty = true
	tce.drag_to_popout_as_window = true
	tce.popout_drag_modifiers = popout_drag_modifiers
	tce.tab_close_display_policy = tab_close_display_policy

	tce.tab_root = tab_root

	tce.tab_alignment = tab_alignment
	tce.clip_tabs = clip_tabs
	tce.tabs_visible = tabs_visible
	tce.all_tabs_in_front = all_tabs_in_front
	tce.drag_to_rearrange_enabled = drag_to_rearrange_enabled
	tce.tabs_rearrange_group = tabs_rearrange_group
	tce.use_hidden_tabs_for_min_size = use_hidden_tabs_for_min_size


	tce.anchor_right = 1
	tce.anchor_bottom = 1

	tce.add_child(control)
	w.add_child(tce)
	tab_root.add_child(w)
	return w


#
# Private properties
#

var _tab_bar: TabBar


func _init()->void:
	_tab_bar = get_child(0, true) as TabBar
	# setup pass through signals
	_tab_bar.active_tab_rearranged.connect(_on_active_tab_rearranged)
	_tab_bar.tab_clicked.connect(_on_tab_clicked)
	_tab_bar.tab_close_pressed.connect(_on_tab_close_pressed)
	_tab_bar.tab_hovered.connect(_on_tab_hovered)
	_tab_bar.tab_rmb_clicked.connect(_on_tab_rmb_clicked)

func _on_active_tab_rearranged(idx_to:int)->void: active_tab_rearranged.emit(idx_to)
func _on_tab_clicked(tab:int)->void: tab_clicked.emit(tab)
func _on_tab_close_pressed(tab:int)->void: tab_close_pressed.emit(tab)
func _on_tab_hovered(tab:int)->void: tab_hovered.emit(tab)
func _on_tab_rmb_clicked(tab:int)->void: tab_rmb_clicked.emit(tab)

func _ready()->void:
	if not tab_root:
		tab_root = self

func _on_child_exiting_tree(node:Node)->void:
	if node is Control and get_tab_count() == 1:
		_deferred_remove_when_empty.call_deferred()


func _deferred_remove_when_empty()->void:
	if is_inside_tree() and remove_when_empty and get_tab_count() == 0:
		get_parent().remove_child(self)
		queue_free()

func _get_drag_data_fw(point:Vector2, from_control:Control)->Variant:
	print("_get_drag_data_fw")
	if not drag_to_rearrange_enabled: return null

	var tab_over: int = get_tab_idx_at_point(point);
	if tab_over < 0:
		return null

	if drag_to_popout_as_window and get_tab_count() > 1 and _check_drag_modifiers():
		get_viewport().set_input_as_handled() # handle this here or will cause error later!
		var ttw :TabTreeWindow = popout_tab_as_window(tab_over, get_screen_position() + get_local_mouse_position())
		ttw.grabbed = true
		return null

#	var drag_preview: HBoxContainer = HBoxContainer.new()
#	var icon: Texture2D = get_tab_icon(tab_over)
#	if icon:
#		var tf: TextureRect = TextureRect.new()
#		tf.texture = icon
#		drag_preview.add_child(tf)
#
#	var label: Label = Label.new()
#	label.text = get_tab_title(tab_over)
#	set_drag_preview(drag_preview)
#	drag_preview.add_child(label)
	return {
		"type": "tabc_element",
		"tabc_element": tab_over,
		"from_path": get_path()
	}




func _can_drop_data_fw(point:Vector2, data:Variant, from_control:Control)->bool:
	if not (drag_to_rearrange_enabled and data is Dictionary): return false

	var d: Dictionary = data
	if not d.has("type"): return false

	if String(d["type"]) == "tabc_element":
		var from_path: NodePath = d["from_path"]
		var to_path: NodePath = get_path()
		if from_path == to_path:
			return true
		elif (get_tabs_rearrange_group() != -1):
			# Drag and drop between other TabContainers.
			var from_node: Node = get_node(from_path)
			var from_tabc: TabContainer = from_node as TabContainer
			if from_tabc and from_tabc.get_tabs_rearrange_group() == get_tabs_rearrange_group():
				return true
	return false

func _drop_data_fw(point:Vector2, data:Variant, from_control:Control)->void:
	if not (drag_to_rearrange_enabled and data is Dictionary): return

	var d: Dictionary = data
	if not d.has("type"): return

	if String(d["type"]) == "tabc_element":
		var tab_from_id: int = d["tabc_element"]
		var hover_now: int = get_tab_idx_at_point(point)
		var from_path: NodePath = d["from_path"]
		var to_path: NodePath = get_path()

		if from_path == to_path:
			if tab_from_id == hover_now: return

			# Drop the new tab to the left or right depending on where the target tab is being hovered.
			if hover_now != -1:
				var tab_rect: Rect2 = _tab_bar.get_tab_rect(hover_now)
				if int(is_layout_rtl()) ^ int(point.x <= tab_rect.position.x + tab_rect.size.x / 2):
					if hover_now > tab_from_id:
						hover_now -= 1
				elif tab_from_id > hover_now:
					hover_now += 1
			else:
				hover_now = 0 if int(is_layout_rtl()) ^ int(point.x < _tab_bar.get_tab_rect(0).position.x) else get_tab_count() - 1


			move_child(get_tab_control(tab_from_id), get_tab_control(hover_now).get_index(false))
			if not is_tab_disabled(hover_now):
				set_current_tab(hover_now)

		elif get_tabs_rearrange_group() != -1:
			# Drag and drop between TabContainers.

			var from_node: Node = get_node(from_path)
			var from_tabc: TabContainer = from_node as TabContainer

			if from_tabc and from_tabc.get_tabs_rearrange_group() == get_tabs_rearrange_group():
				# Get the tab properties before they get erased by the child removal.
				var tab_title: String = from_tabc.get_tab_title(tab_from_id)
				var tab_disabled: bool = from_tabc.is_tab_disabled(tab_from_id)

				# Drop the new tab to the left or right depending on where the target tab is being hovered.
				if hover_now != -1:
					var tab_rect: Rect2 = _tab_bar.get_tab_rect(hover_now)
					if int(is_layout_rtl()) ^ int(point.x > tab_rect.position.x + tab_rect.size.x / 2):
						hover_now += 1
				else:
					hover_now = 0 if int(is_layout_rtl()) ^ int(point.x < _tab_bar.get_tab_rect(0).position.x) else get_tab_count()

				var moving_tabc: Control = from_tabc.get_tab_control(tab_from_id)
				from_tabc.remove_child(moving_tabc)
				add_child(moving_tabc, true)

				set_tab_title(get_tab_count() - 1, tab_title);
				set_tab_disabled(get_tab_count() - 1, tab_disabled);

				move_child(moving_tabc, get_tab_control(hover_now).get_index(false))
				if not is_tab_disabled(hover_now):
					set_current_tab(hover_now)

				# grab focus after drop if dragging from a different window
				var vp: Window = get_viewport() as Window
				if vp and from_tabc.get_viewport() != vp:
					vp.grab_focus()


#
# Helpers
#

func _check_drag_modifiers()->bool: return popout_drag_modifiers == 0 or\
	bool(popout_drag_modifiers & 1) == Input.is_key_pressed(KEY_SHIFT) and\
	bool(popout_drag_modifiers & 2) == Input.is_key_pressed(KEY_CTRL) and\
	bool(popout_drag_modifiers & 4) == Input.is_key_pressed(KEY_ALT)  and\
	bool(popout_drag_modifiers & 8) == Input.is_key_pressed(KEY_META)
