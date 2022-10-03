class_name ExpandContainer extends Container

@export var title: String
@export var expanded: bool

var first_control_child: Control


func _init()->void:
	theme = Theme.new()
	theme.copy_default_theme()
	print(theme)
	pass

func _ready()->void:
	update_first_child()
	queue_redraw()
	update_minimum_size()


func _enter_tree()->void:
	update_first_child()

func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.is_pressed():
		pass

func _get_minimum_size()->Vector2:
	var first_control_child: Control
	var font := get_theme_font("font", "Label")
	var min_size := font.get_string_size(title)


	if first_control_child:
		var fcc_size := first_control_child.get_minimum_size()
		min_size.x = max(min_size.x, fcc_size.x)
		if expanded:
			min_size.y += fcc_size.y

	if expanded:
		pass
	else:
		pass

	return min_size


func _notification(what:int)->void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			if first_control_child:
				pass
		NOTIFICATION_MOUSE_ENTER:
			pass
		NOTIFICATION_MOUSE_EXIT:
			pass
		NOTIFICATION_DRAW:
			var panel := get_theme_stylebox("panel", "Panel")
			var font := get_theme_font("font", "Label")
			var rid := get_canvas_item()
			var height := font.get_height()

			panel.draw(rid, Rect2(0,0,size.x,height+6))
			font.draw(rid, Vector2(0,height), title)

func update_first_child()->void:
	for child in get_children():
		if child is Control:
			first_control_child = child
			return
	first_control_child = null
