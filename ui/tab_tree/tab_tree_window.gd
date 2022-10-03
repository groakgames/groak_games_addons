class_name TabTreeWindow extends SelfRemovingWindow

var grabbed := false

func _input(event:InputEvent)->void:
	if event is InputEventMouseMotion and grabbed:
		position = DisplayServer.mouse_get_position()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		grabbed = false

