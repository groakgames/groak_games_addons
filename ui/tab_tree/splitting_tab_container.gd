class_name SplittingTabContainer extends WindowingTabContainer

enum DropZones {
	LEFT,
	TOP,
	CENTER,
	BOTTOM,
	RIGHT,
	TOTAL,
}


func set_display_split_area(val:bool)->void:
	if val:
		if not _display_split_areas:
			_display_split_areas = true
			_arrange_drop_selectors()
			_selector_root.visible = true
	elif _display_split_areas:
		_display_split_areas = false
		_selector_root.visible = false


#
# Private Properties
#


var _dragging := false
var _display_split_areas := false
var _selector_root: Control
var _drop_selectors: Array[Control] = []

#
# Private methods
#

func _init()->void:
	super()
	_selector_root = Control.new()
	for i in DropZones.TOTAL:
		var rr := SplittingTabDropZone.new()
		_drop_selectors.append(rr)
		_selector_root.add_child(rr)
		rr.drop_zone_idx = i
		rr.dropped.connect(_on_dropped_into_zone)
	_tab_bar.add_child(_selector_root)
	_selector_root.top_level = true
	window_type = TabTreeWindow # set new default


func _input(event:InputEvent)->void:
	if event is InputEventMouseMotion:
		if _dragging and get_global_rect().has_point(event.global_position):
			set_display_split_area(true)
		elif _display_split_areas:
			set_display_split_area(false)


func _notification(what:int)->void:
	if what == NOTIFICATION_DRAG_BEGIN:
		_dragging = true
	elif what == NOTIFICATION_DRAG_END:
		_dragging = false
		set_display_split_area(false)


func _on_dropped_into_zone(zone_idx:DropZones, pos:Vector2, data:Variant)->void:
	if not (data is Dictionary and data.get("type") == "tabc_element"): return
	var dropped_tab_control_root :=  get_node(data.from_path) as Control
	var dropped_tab_idx: int = data.get(data.type)
	var dropped_tab_icon: Texture = dropped_tab_control_root.get_tab_icon(dropped_tab_idx)
	var dropped_tab_title: String = dropped_tab_control_root.get_tab_title(dropped_tab_idx)
	var dropped_tab_control: Control = dropped_tab_control_root.get_tab_control(dropped_tab_idx)

	if zone_idx == DropZones.CENTER:
		if dropped_tab_control.get_parent() != self:
			dropped_tab_control_root.remove_child(dropped_tab_control)
			add_child(dropped_tab_control)
			current_tab = get_tab_count() - 1
	else:
		var is_vertical: bool = zone_idx == DropZones.TOP or zone_idx == DropZones.BOTTOM
		var parent: Node = get_parent()
		var this_child_idx: int = get_index()
		var new_tab_container: Node = tab_root.tab_container_type.new()
		tab_root.copy_props(new_tab_container)
		if parent is MultiSplitContainer and parent.vertical == is_vertical:
			parent.add_child(new_tab_container)
			dropped_tab_control_root.remove_child(dropped_tab_control)
			new_tab_container.add_child(dropped_tab_control)
			parent.move_child(new_tab_container, this_child_idx+int(zone_idx > DropZones.CENTER))
		else:
			var branch: Node = tab_root.tab_tree_branch_type.new()
			branch.vertical = is_vertical
			branch.anchor_right = 1
			branch.anchor_bottom = 1
			branch.tab_root = tab_root
			remove_when_empty = true

			# need to disconnect here or this error will occur:
			# Signal 'size_changed' is already connected to given callable 'Control::_size_changed' in that object.
			for con in get_viewport().size_changed.get_connections():
				if con.callable.get_object() == _selector_root:
					get_viewport().size_changed.disconnect(con.callable)
					break

			dropped_tab_control_root.remove_child(dropped_tab_control)
			parent.remove_child(self)
			new_tab_container.add_child(dropped_tab_control)
			if zone_idx < DropZones.CENTER:
				# dropping to the left/top
				branch.add_child(new_tab_container)
				branch.add_child(self)
			else:
				# dropping to the bottom/right
				branch.add_child(self)
				branch.add_child(new_tab_container)
			#_selector_root.top_level = false

			parent.add_child(branch)
			parent.move_child(branch, this_child_idx)



#
# Helpers
#


func _arrange_drop_selectors()->void:
	var panel_stylebox := get_theme_stylebox("panel")
	var tab_bg_stylebox := get_theme_stylebox("tab_bg")
	var tab_disabled_stylebox := get_theme_stylebox("tab_disabled")
	var tab_fg_stylebox := get_theme_stylebox("tab_fg")
	var font := get_theme_font("font")

	var top: int = [
		tab_bg_stylebox.content_margin_top + tab_bg_stylebox.content_margin_top,
		tab_disabled_stylebox.content_margin_top + tab_disabled_stylebox.content_margin_top,
		tab_fg_stylebox.content_margin_top + tab_fg_stylebox.content_margin_top
	].max() + font.get_height() + panel_stylebox.content_margin_top

	var r := Rect2(
		0, _tab_bar.size.y,
		size.x, size.y - _tab_bar.size.y
	)

	var tall := r.size.y > r.size.x
	if tall:
		var a := r.size.x/3
		_drop_selectors[0].size = Vector2(a, r.size.y)
		_drop_selectors[0].global_position = global_position + r.position

		_drop_selectors[1].size = Vector2(a, a)
		_drop_selectors[1].global_position = global_position + r.position + Vector2(a, 0)

		_drop_selectors[2].size = Vector2(a, r.size.y - (2*a))
		_drop_selectors[2].global_position = global_position + r.position + Vector2(a, a)

		_drop_selectors[3].size = Vector2(a, a)
		_drop_selectors[3].global_position = global_position + r.position + Vector2(a, r.size.y - a)

		_drop_selectors[4].size = Vector2(a, r.size.y)
		_drop_selectors[4].global_position = global_position + r.position + Vector2(r.size.x - a, 0)
	else:
		var a := r.size.y/3
		_drop_selectors[0].size = Vector2(a, r.size.y)
		_drop_selectors[0].global_position = global_position + r.position

		_drop_selectors[1].size = Vector2(r.size.x - (2*a), a)
		_drop_selectors[1].global_position = global_position + r.position + Vector2(a, 0)

		_drop_selectors[2].size = Vector2(r.size.x - (2*a), a)
		_drop_selectors[2].global_position = global_position + r.position + Vector2(a, a)

		_drop_selectors[3].size = Vector2(r.size.x - (2*a), a)
		_drop_selectors[3].global_position = global_position + r.position + Vector2(a, 2*a)

		_drop_selectors[4].size = Vector2(a, r.size.y)
		_drop_selectors[4].global_position = global_position + r.position + Vector2(r.size.x - a, 0)


class SplittingTabDropZone:
	extends Control
	var drop_zone_idx: int = -1
	signal dropped(drop_zone_idx:DropZones, at_position:Vector2, data:Variant)

	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO, size), Color.RED, false)

	func _can_drop_data(at_position:Vector2, data:Variant)->bool:
		if not(data is Dictionary and data.get("type") == "tabc_element"): return false
		var n: Node = get_node(data.from_path)
		var tab_root: Node = get_parent().get_parent().get_parent().tab_root
		return tab_root.tab_container_type.instance_has(n) and n.tab_root == tab_root

	func _drop_data(at_position:Vector2, data:Variant)->void:
		dropped.emit(drop_zone_idx, at_position, data)
