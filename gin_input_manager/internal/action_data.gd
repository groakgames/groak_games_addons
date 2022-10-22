var name: String
var deadzone: float

func init(action, player, profile)->void:
	name = action.resource_name
	deadzone = action.deadzone
	_player = player


func clear_cache()->void:
	assert(false, "Unimplemented clear_cache")

func get_inputs()->Array:
	assert(false, "Unimplemented get_inputs")
	return []

func parse_input(event_id:int, event:InputEvent, is_unhandled_input:bool)->void:
	assert(false, "Unimplemented parse_input")

var _player
