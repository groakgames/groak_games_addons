class_name GinActionVector extends GinAction

enum {
	TYPE_FORWARD
	TYPE_BACK
	TYPE_LEFT
	TYPE_RIGHT
	TYPE_NATIVE
}

var forward_inputs: Array
var back_inputs: Array
var left_inputs: Array
var right_inputs: Array
var native_inputs: Array


func add_input_event(input_event:InputEvent, type:int)->bool:
	var input_int: int = Gin.input_event_int(input_event)
	if (input_int in forward_inputs) or (input_int in back_inputs) or (input_int in left_inputs) or (input_int in right_inputs) or (input_int in native_inputs):
		return false
	match type:
		TYPE_FORWARD:
			forward_inputs.append(input_int)
		TYPE_BACK:
			back_inputs.append(input_int)
		TYPE_LEFT:
			left_inputs.append(input_int)
		TYPE_RIGHT:
			right_inputs.append(input_int)
		TYPE_NATIVE:
			native_inputs.append(input_int)
		_:
			return false
	return true


func _get_property_list():
	return [{
		"name": "forward_inputs",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_NOEDITOR
	},{
		"name": "back_inputs",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_NOEDITOR
	},{
		"name": "left_inputs",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_NOEDITOR
	},{
		"name": "right_inputs",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_NOEDITOR
	},{
		"name": "native_inputs",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_NOEDITOR
	}]
