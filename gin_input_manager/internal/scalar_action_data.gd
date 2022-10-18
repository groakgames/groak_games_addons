extends "action_data.gd"

signal triggered(action, input, event)

func clear_cache()->void:
	_stack.clear()
	_prev_values.clear()
	_player.unhandled_signal_obj.emit_signal(name, 0.0, null)
	_player.handled_signal_obj.emit_signal(name, 0.0, null)


func get_inputs()->Array:
	return _inputs.duplicate()


func get_value()->float:
	return _stack.back()[1] if _stack else 0.0


func init(action:GinActionScalar, player, profile)->void:
	.init(action, player, profile)
	_inputs = action.inputs
	_inputs.sort()


func parse_input(event:InputEvent, is_unhandled_input:bool)->void:
	var prev_values: Dictionary
	var stack: Array
	if is_unhandled_input:
		prev_values = _uprev_values
		stack = _ustack
	else:
		prev_values = _prev_values
		stack = _stack
	var ie_int: int = Gin.input_event_int(event)
	if event is InputEventJoypadButton:
		if event.pressed:
			if prev_values.get(ie_int, 0.0) != 0.0:
				stack.erase([ie_int, prev_values[ie_int]])
			var value: float = event.pressure if event.pressure != 0.0 else 1.0
			stack.push_back([ie_int, value])
			prev_values[ie_int] = value
		elif prev_values.has(ie_int):
			stack.erase(prev_values[ie_int])
			prev_values[ie_int] = 0.0
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			stack.push_back([ie_int, 1.0])
		else:
			stack.erase([ie_int, 1.0])
	else:
		return

	if is_unhandled_input:
		_player.unhandled_signal_obj.emit_signal(name, get_value(), event)
	else:
		_player.handled_signal_obj.emit_signal(name, get_value(), event)

var _uprev_values: Dictionary
var _prev_values: Dictionary
var _stack: Array
var _ustack: Array
var _inputs: Array
