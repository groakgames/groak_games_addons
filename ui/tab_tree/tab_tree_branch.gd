#@tool
class_name TabTreeBranch extends MultiSplitContainer

var tab_root: Node

func _on_child_exiting_tree(node:Node)->void:
	if node is Control and not node in _grabbers:
		node.visibility_changed.disconnect(_node_visibility_connections[node])
		_node_visibility_connections.erase(node)
		var idx: int = _controls.find(node)
		if idx >= 0:
			var is_last: int = _controls.size() == 1
			_control_removed_helper(node, idx)
			if is_last:
				_flip_flop(node)


func _flip_flop(node:Node)->void:
	if tab_root.tab_container_type.instance_has(node) or get_script().instance_has(node):
		var parent := get_parent()
		parent.remove_child(self)
		parent.add_child(node)


#func _ready()->void:
#	super._ready()
#	if get_child_count() == 0:
#		var stc = SplittingTabContainer.new()
#		stc.remove_when_empty = true
#		stc.tab_align = tab_align
#		stc.tab_close_display_policy = tab_close_display_policy
#		stc.scrolling_enabled = scrolling_enabled
#		stc.drag_to_rearrange_enabled = drag_to_rearrange_enabled
#		stc.tabs_rearrange_group = tabs_rearrange_group
#		add_child(stc)
#	pass
