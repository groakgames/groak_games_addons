@tool
class_name Finder extends Resource

enum EnforceTypeMode {
	DONT_ENFORCE,
	BUILT_IN,
	SCRIPT
}

@export var enforce_type_mode: EnforceTypeMode:
	get: return enforce_type_mode
	set(value):
		if Engine.is_editor_hint() and value != enforce_type_mode:
			obj_type = "" if value == EnforceTypeMode.BUILT_IN else null
			notify_property_list_changed()
		enforce_type_mode = value

var obj_type: Variant

func find()->Object: return null

func _check_type(obj:Object)->bool:
	if obj_type is String:
		return obj.is_class(obj_type)
	elif obj_type is Script:
		return obj_type.instance_has(obj)
	return false

func _get_property_list()->Array[Dictionary]:
	if enforce_type_mode == EnforceTypeMode.BUILT_IN:
		return [{
			"name": "obj_type",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_NONE
		}]
	elif enforce_type_mode == EnforceTypeMode.SCRIPT:
		return [{
			"name": "obj_type",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Script"
		}]
	return []
