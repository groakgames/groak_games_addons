#@tool
class_name TabTreeRoot extends MarginContainer


@export_group("Leaf Parameters")
@export var _tabs_rearrange_group: int = 0
@export var _tab_alignment: TabBar.AlignmentMode = TabBar.AlignmentMode.ALIGNMENT_LEFT
@export var _tab_close_display_policy: TabBar.CloseButtonDisplayPolicy = TabBar.CloseButtonDisplayPolicy.CLOSE_BUTTON_SHOW_NEVER
@export var _scrolling_enabled: bool = true
@export var _drag_to_popout_as_window: bool = true

@export_group("Tree Node Types")
@export var tab_container_type: Script = load(TabTreeRoot.resource_path.get_base_dir() + "/splitting_tab_container.gd")
@export var tab_tree_branch_type: Script = load(TabTreeRoot.resource_path.get_base_dir() + "/tab_tree_branch.gd")
@export var window_type: Script = TabTreeWindow


#
# Private
#

func _ready()->void:
	# Dive into children and assign self as tree root
	var child_queue: Array[Node]
	for c in get_children():
		if tab_tree_branch_type.instance_has(c):
			child_queue.append_array(c.get_children())
			c.tab_root = self
		elif c is TabTreeWindow:
			child_queue.append_array(c.get_children())
		elif tab_container_type.instance_has(c): # leaf
			c.tab_root = self
			copy_props(c)
	while child_queue:
		var c: Node = child_queue.pop_back()
		if tab_tree_branch_type.instance_has(c):
			child_queue.append_array(c.get_children())
			c.tab_root = self
		elif tab_container_type.instance_has(c): # leaf
			c.tab_root = self
			copy_props(c)


func copy_props(node:Control)->void:
	node.tabs_rearrange_group = _tabs_rearrange_group
	node.tab_alignment = _tab_alignment
	node.tab_close_display_policy = _tab_close_display_policy
	node.scrolling_enabled = _scrolling_enabled
	node.drag_to_popout_as_window = _drag_to_popout_as_window
	node.drag_to_rearrange_enabled = true
	node.remove_when_empty = true
	node.anchor_bottom = 1
	node.anchor_right = 1
	node.size_flags_horizontal = SIZE_EXPAND_FILL
	node.tab_root = self
	node.window_type = window_type
