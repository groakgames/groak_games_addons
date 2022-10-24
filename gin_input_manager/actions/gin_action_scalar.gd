class_name GinActionScalar extends GinAction

var inputs: Array

func add_input_event(input_event:InputEvent, no_mods:bool=false)->bool:
	var input_int: int = Gin.input_event_int(input_event, no_mods)
	if input_int in inputs:
		return false
	inputs.append(input_int)
	return true


func _get_property_list():
	return [{
		"name": "inputs",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_NO_EDITOR
	}]
