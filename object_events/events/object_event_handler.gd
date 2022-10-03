@tool
class_name ObjectEventHandler extends EventHandler


@export var method_name: StringName = &""
@export var object_finder: Resource

func handle_event(args:Array[Variant] = [])->int:
	assert(object_finder != null)
	var obj: Object = object_finder.find()
	if obj.has_method(method_name):
		print("precall")
		obj.call(method_name)
		print("postcall")
		return OK
	return ERR_DOES_NOT_EXIST
