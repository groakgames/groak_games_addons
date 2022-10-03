extends Control
class_name Toolbar

enum ToolBarButtonType {
	BUTTON_NORMAL,
	BUTTON_CHECK,
	BUTTON_RADIO,
}

# Root node for toolbar buttons
@export var _button_root:Node

var _popup_menus := {}

# mapping of path to object
var _handlers := {}

# {PopupMenu, String}
var _popup_menu_paths := {}
var _button_types := {}


func add_menu_bar_button(path:String, target:Object, method:String, binds:Array)->void:
	var split_path := path.split('\\')
	if split_path.size():
		var main_button := _button_root.get_node(split_path[0]) as MenuButton
		if main_button:
			var popup := main_button.get_popup()
			popup

func add_tool_bar_item(item:ToolbarItem)->void:
	add_menu_button(item.path.split("\\"), item.handler, item.button_type, item.icon, item.shortcut)

# path: path to button in menu bar.
# target: object to handle button press
# method:
# binds:
# ERR_ALREADY_IN_USE - if path is already in used
func add_menu_button(path:PackedStringArray, handler:EventHandler, button_type:int=ToolBarButtonType.BUTTON_NORMAL, icon:Texture2D = null, shortcut:Shortcut=null)->int:
	if path.size() <= 0:
		return ERR_BUG

	if handler:
		pass

	var path_string := "\\".join(path)

	var cur_name := path[0]
	if path.size() == 1:
		# just a button on toolbar
		if not _popup_menus.has(cur_name):
			var b: Button
			match button_type:
				ToolBarButtonType.BUTTON_NORMAL:
					b = Button.new()
				ToolBarButtonType.BUTTON_CHECK, ToolBarButtonType.BUTTON_RADIO:
					b = CheckBox.new()
			b.text = cur_name
			_button_root.add_child(b)
			_popup_menus[cur_name] = b
		else:
			return ERR_ALREADY_EXISTS
	else:
		var cur_popup_menu: PopupMenu = _popup_menus.get(cur_name)
		# New top level button
		if not cur_popup_menu:
			var menu_button :=  MenuButton.new()
			menu_button.text = cur_name
			cur_popup_menu = menu_button.get_popup()
			_button_root.add_child(menu_button)
			_popup_menus[cur_name] = cur_popup_menu
			cur_popup_menu.index_pressed.connect(_on_pressed_handler.bind(cur_popup_menu, "\\".join(path.slice(0,path.size()))))

		# dive into submenus and create if not existing
		for i in range(1, path.size() - 1):
			cur_name = path[i]
			var temp_popup_menu: PopupMenu = cur_popup_menu.get_node_or_null(cur_name)
			if not temp_popup_menu:
				temp_popup_menu = PopupMenu.new()
				temp_popup_menu.index_pressed.connect(_on_pressed_handler.bind(cur_popup_menu, "\\".join(path.slice(0,path.size()))))
				temp_popup_menu.name = cur_name
				cur_popup_menu.add_child(temp_popup_menu)
				cur_popup_menu.add_submenu_item(cur_name, temp_popup_menu.name)
			cur_popup_menu = temp_popup_menu

		var button_name := path[path.size()-1]
		for i in cur_popup_menu.get_item_count():
			if button_name == cur_popup_menu.get_item_text(i):
				return ERR_ALREADY_EXISTS

		if icon:
			if shortcut:
				match button_type:
					ToolBarButtonType.BUTTON_NORMAL:
						cur_popup_menu.add_icon_shortcut(icon, shortcut)
					ToolBarButtonType.BUTTON_CHECK:
						cur_popup_menu.add_icon_check_shortcut(icon, shortcut)
					ToolBarButtonType.BUTTON_RADIO:
						cur_popup_menu.add_icon_radio_check_shortcut(icon, shortcut)
			else:
				match button_type:
					ToolBarButtonType.BUTTON_NORMAL:
						cur_popup_menu.add_icon_item(icon, button_name)
					ToolBarButtonType.BUTTON_CHECK:
						cur_popup_menu.add_icon_check_item(icon, button_name)
					ToolBarButtonType.BUTTON_RADIO:
						cur_popup_menu.add_icon_radio_check_item(icon, button_name)
		elif shortcut:
			match button_type:
				ToolBarButtonType.BUTTON_NORMAL:
					cur_popup_menu.add_shortcut(shortcut)
				ToolBarButtonType.BUTTON_CHECK:
					cur_popup_menu.add_check_shortcut(shortcut)
				ToolBarButtonType.BUTTON_RADIO:
					cur_popup_menu.add_radio_check_shortcut(shortcut)
		else:
			match button_type:
				ToolBarButtonType.BUTTON_NORMAL:
					cur_popup_menu.add_item(button_name)
				ToolBarButtonType.BUTTON_CHECK:
					cur_popup_menu.add_check_item(button_name)
				ToolBarButtonType.BUTTON_RADIO:
					cur_popup_menu.add_radio_check_item(button_name)

		_button_types[path_string] = button_type
		_popup_menu_paths[cur_popup_menu] = cur_name

		if handler:
			_handlers[StringName(path_string)] = handler
	return OK

func _on_pressed_handler(idx:int, popup_menu:PopupMenu, submenu_prefix:String)->void:
	var path := StringName(_popup_menu_paths[popup_menu] + "\\" + popup_menu.get_item_text(idx))
	var handler: EventHandler = _handlers.get(path)
	assert(handler)
	#match _button_types[path]:
#		popup_menu.set_item_checked(idx, )

	# sanity check that the handler has the method we want
	handler.handle_event([idx, popup_menu, path])# .on_toolbar_item_pressed(idx, popup_menu, path)


func _ready()->void:
	pass


func _on_menu_button_pressed(idx:int, popup_menu:PopupMenu, path:String)->void:
	pass
