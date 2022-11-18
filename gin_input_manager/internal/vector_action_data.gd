extends "action_data.gd"

signal triggered(action, input, absolute, event)


func init(action:GinActionVector, player, profile)->void:
	super.init(action, player, profile)
	for i in action.forward_inputs:
		_input_direction_map[i] = GinAction.VECTOR_INPUT_TYPE.UP
	for i in action.back_inputs:
		_input_direction_map[i] = GinAction.VECTOR_INPUT_TYPE.DOWN
	for i in action.left_inputs:
		_input_direction_map[i] = GinAction.VECTOR_INPUT_TYPE.LEFT
	for i in action.right_inputs:
		_input_direction_map[i] = GinAction.VECTOR_INPUT_TYPE.RIGHT
	for i in action.native_inputs:
		if i & Gin.MASK_IS_ABSOLUTE:
			_input_direction_map[i] = GinAction.VECTOR_INPUT_TYPE.ABSOLUTE
		else:
			_input_direction_map[i] = GinAction.VECTOR_INPUT_TYPE.RELATIVE


func get_inputs()->Array:
	return _input_direction_map.keys()


func clear_cache()->void:
	_xs.clear()
	_uxs.clear()
	_ys.clear()
	_uys.clear()
	_prev_values.clear()
	_uprev_values.clear()
	_player.handled_signal_obj.emit_signal(name, Vector2.ZERO, null, false)
	_player.unhandled_signal_obj.emit_signal(name, Vector2.ZERO, null, false)


func parse_input(event_id:int, event:InputEvent, is_unhandled_input:bool)->void:
	var direction = _input_direction_map.get(event_id)
	if direction == null: return

	var direction_stack:Array
	var prev_values:Dictionary
	if is_unhandled_input:
		direction_stack = _uys if direction == GinAction.VECTOR_INPUT_TYPE.UP or direction == GinAction.VECTOR_INPUT_TYPE.DOWN else _uxs
		prev_values = _uprev_values
	else:
		direction_stack = _ys if direction == GinAction.VECTOR_INPUT_TYPE.UP or direction == GinAction.VECTOR_INPUT_TYPE.DOWN else _xs
		prev_values = _prev_values

	var dir_coef: int = int(direction == GinAction.VECTOR_INPUT_TYPE.RIGHT or direction == GinAction.VECTOR_INPUT_TYPE.DOWN)*2-1

	if event.is_echo(): return

	if direction < GinAction.VECTOR_INPUT_TYPE.NATIVE_INPUT_START:
		if event is InputEventJoypadMotion:
			if abs(event.axis_value) > _deadzone:
				if prev_values.get(event_id, 0.0) != 0.0:
					direction_stack.erase([event_id, prev_values[event_id]])
				var value: float = event.axis_value*dir_coef
				direction_stack.push_back([event_id, value])
				prev_values[event_id] = value
			elif prev_values.has(event_id):
				direction_stack.erase([event_id, prev_values[event_id]])
				prev_values[event_id] = 0.0
		elif event is InputEventJoypadButton:
			if event.pressed:
				if prev_values.get(event_id, 0.0) != 0.0:
					direction_stack.erase([event_id, prev_values[event_id]])
				var value: float = event.pressure if event.pressure != 0.0 else 1.0
				direction_stack.push_back([event_id, value])
				prev_values[event_id] = value
			elif prev_values.has(event_id):
				direction_stack.erase(prev_values[event_id])
				prev_values[event_id] = 0.0
		elif event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:

			if event.pressed:
				direction_stack.push_back([event_id, dir_coef])
			else:
				direction_stack.erase([event_id, dir_coef])
		else:
			return
		if is_unhandled_input:
			_player.unhandled_signal_obj.emit_signal(name, get_value(), event, false)
		else:
			_player.handled_signal_obj.emit_signal(name, get_value(), event, false)

	else:
		var is_absolute: bool = direction == GinAction.VECTOR_INPUT_TYPE.ABSOLUTE
		var value: Vector2
		if event is InputEventMouseMotion:
			value = event.position if is_absolute else event.relative
		else:
			return

		if is_unhandled_input:
			_player.unhandled_signal_obj.emit_signal(name, value, event, is_absolute)
		else:
			_player.handled_signal_obj.emit_signal(name, value, event, is_absolute)


func get_value()->Vector2:
	return Vector2(_xs.back()[1] if _xs else 0.0, _ys.back()[1] if _ys else 0.0).limit_length(1.0)


var _input_direction_map: Dictionary
var _prev_values := {}
var _uprev_values := {}
var _xs: Array
var _ys: Array
var _uxs: Array
var _uys: Array
var _deadzone: float = 0.01
