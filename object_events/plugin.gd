@tool
extends EditorPlugin

func _enter_tree()->void:
	# events
	add_custom_type("EventHandler", "Resource", preload("events/event_handler.gd"), null)
	add_custom_type("ExpressionEventHandler", "Resource", preload("events/expression_event_handler.gd"), null)
	add_custom_type("ObjectEventHandler", "Resource", preload("events/object_event_handler.gd"), null)

	# object finders
	add_custom_type("Finder", "Resource", preload("object_finders/finder.gd"), null)
	add_custom_type("NodeFinder", "Resource", preload("object_finders/node_finder.gd"), null)
	add_custom_type("ResourceFinder", "Resource", preload("object_finders/resource_finder.gd"), null)

func _exit_tree()->void:
	remove_custom_type("EventHandler")
	remove_custom_type("ExpressionEventHandler")
	remove_custom_type("ObjectEventHandler")

	remove_custom_type("Finder")
	remove_custom_type("NodeFinder")



func add_custom_type(type:String, base:String, script:Script, icon:Texture2D)->void:
	if type_exists(type):
		printerr("Could not add type ", type)
	super.add_custom_type(type, base, script, icon)
