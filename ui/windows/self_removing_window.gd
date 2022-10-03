class_name SelfRemovingWindow extends Window

@export var remove_when_empty := true


func _init()->void:
	close_requested.connect(_on_close_requested)
	child_exiting_tree.connect(_on_child_exiting_tree)

func _on_child_exiting_tree(node:Node)->void:
	if get_child_count() == 1:
		_deferred_remove_when_empty.call_deferred()

func _deferred_remove_when_empty()->void:
	if is_inside_tree() and remove_when_empty and get_child_count() == 0:
		if get_parent() != null:
			get_parent().remove_child(self)
		queue_free()

func _on_close_requested()->void:
	get_parent().remove_child(self)
	queue_free()
