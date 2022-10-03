@tool
extends EditorPlugin

func _enter_tree()->void:
	# Containers
	add_custom_type("ExpandContainer", "Container", preload("containers/expand_container.gd"), null)
	add_custom_type("MultiSplitContainer", "SplitContainer", preload("containers/multi_split_container.gd"), null)
	add_custom_type("WindowingTabContainer", "TabContainer", preload("containers/windowing_tab_container.gd"), null)

	# Windows
	add_custom_type("SelfRemovingWindow", "Window", preload("windows/self_removing_window.gd"), null)

	# Tab Tree
	add_custom_type("SplittingTabContainer", "Container", preload("tab_tree/splitting_tab_container.gd"), null)
	add_custom_type("TabTreeBranch", "SplitContainer", preload("tab_tree/tab_tree_branch.gd"), null)
	add_custom_type("TabTreeRoot", "MarginContainer", preload("tab_tree/tab_tree_root.gd"), null)
	add_custom_type("TabTreeWindow", "Window", preload("tab_tree/tab_tree_window.gd"), null)

	# tool bar
	add_custom_type("ToolBarItem", "Resource", preload("toolbar/toolbar_item.gd"), null)
	add_custom_type("ToolBar", "Control", preload("toolbar/toolbar.gd"), null)

func _exit_tree()->void:
	remove_custom_type("ExpandContainer")
	remove_custom_type("MultiSplitContainer")
	remove_custom_type("WindowingTabContainer")

	remove_custom_type("SelfRemovingWindow")

	remove_custom_type("SplittingTabContainer")
	remove_custom_type("TabTreeBranch")
	remove_custom_type("TabTreeRoot")
	remove_custom_type("TabTreeWindow")

	remove_custom_type("ToolBarItem")
	remove_custom_type("ToolBar")



func add_custom_type(type:String, base:String, script:Script, icon:Texture2D)->void:
	if type_exists(type):
		printerr("Could not add type ", type)
	super.add_custom_type(type, base, script, icon)
