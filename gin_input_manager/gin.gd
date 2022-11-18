extends Node

# Autoload Gin


var GinActionScalar:Script
var GinActionVector:Script
var ScalarActionData:Script
var VectorActionData:Script

const MIDI_ENABLED_PLATFORMS: PackedStringArray = ["X11", "OSX", "Windows"]

const SCALAR_SIGNAL_ARGS = [
	{name="value", type=TYPE_FLOAT},
	{name="event", type=TYPE_OBJECT}
]

const VECTOR_SIGNAL_ARGS =[
	{name="value", type=TYPE_VECTOR2},
	{name="event", type=TYPE_OBJECT},
	{name="is_absolute",type=TYPE_BOOL}
]

enum {
	DEVICE_INVALID = -5,
	DEVICE_MIDI = -4,
	DEVICE_KEYBOARD = -3,
	DEVICE_MOUSE = -2,
	DEVICE_TOUCH = -1, # Any touch input, gestures, emulated mouse, input from touch screen
	DEVICE_JOYPAD_START = 0,

	IE_INT_TYPE_START = 56,

	IE_INT_MODIFIER_BIT_START = 48,
	BIT_MOD_FORCE = IE_INT_MODIFIER_BIT_START,
	BIT_MOD_CMD,
	BIT_MOD_META,
	BIT_MOD_SHIFT,
	BIT_MOD_ALT,


	IE_INT_NATIVE_BIT_START = 48,
	BIT_IS_ABSOLUTE = IE_INT_NATIVE_BIT_START,
}

# enums only support 32bit integers D:
const MASK_TYPE = 0x0f << IE_INT_TYPE_START
const MASK_DATA = (1<<32)-1
const MASK_MOD_FORCE = 1 << BIT_MOD_FORCE
const MASK_MOD_CMD   = 1 << BIT_MOD_CMD
const MASK_MOD_META  = 1 << BIT_MOD_META
const MASK_MOD_SHIFT = 1 << BIT_MOD_SHIFT
const MASK_MOD_ALT   = 1 << BIT_MOD_ALT
const MASK_MOD_ALL   = MASK_MOD_CMD | MASK_MOD_META | MASK_MOD_SHIFT | MASK_MOD_ALT | MASK_MOD_FORCE
const MASK_MOD_ALL_BUT_FORCE = MASK_MOD_ALL & ~MASK_MOD_FORCE
const MASK_IS_ABSOLUTE = 1 << BIT_IS_ABSOLUTE

const NON_JOYPAD_DEVICE_NAMES := {
	DEVICE_MIDI: "midi",
	DEVICE_KEYBOARD: "keyboard",
	DEVICE_MOUSE: "mouse",
	DEVICE_TOUCH: "touch"
}

const INPUT_EVENT_ID = {
	"_MODIFIERS_START":         0,
	"InputEventKey":            0,
	"_NATIVE_START":            1 << IE_INT_TYPE_START,
	"InputEventMagnifyGesture": 1 << IE_INT_TYPE_START,
	"InputEventPanGesture":     2 << IE_INT_TYPE_START,
	"InputEventMouseButton":    3 << IE_INT_TYPE_START,
	"InputEventMouseMotion":    4 << IE_INT_TYPE_START,
	"_MODIFIERS_END":           4 << IE_INT_TYPE_START,
	"InputEventScreenDrag":     5 << IE_INT_TYPE_START,
	"InputEventScreenTouch":    6 << IE_INT_TYPE_START,
	"_NATIVE_END":              6 << IE_INT_TYPE_START,
	"InputEventJoypadButton":   7 << IE_INT_TYPE_START,
	"InputEventJoypadMotion":   8 << IE_INT_TYPE_START,
	"InputEventMIDI":           9 << IE_INT_TYPE_START,
}

const INPUT_EVENT_ID_STRING: PackedStringArray = [
	"Key",
	"Magnify",
	"Pan",
	"MouseButton",
	"MouseMotion",
	"Drag",
	"Touch",
	"JoypadButton",
	"JoypadMotion",
	"MIDI",
]

const INPUT_EVENT_ID_STRING_CAPS: PackedStringArray = [
	"KEY",
	"MAGNIFY",
	"PAN",
	"MOUSEBUTTON",
	"MOUSEMOTION",
	"DRAG",
	"TOUCH",
	"JOYPADBUTTON",
	"JOYPADMOTION",
	"MIDI",
]

const MOUSE_BUTTON_STRING: PackedStringArray = [
	"",
	"left",
	"right",
	"middle",
	"xbutton1",
	"xbutton2",
	"wheelup",
	"wheeldown",
	"wheelleft",
	"wheelright"
]

const JoyButtonNameMap := {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "BACK",
	JOY_BUTTON_GUIDE: "GUIDE",
	JOY_BUTTON_START: "START",
	JOY_BUTTON_LEFT_STICK: "LEFT_STICK",
	JOY_BUTTON_RIGHT_STICK: "RIGHT_STICK",
	JOY_BUTTON_LEFT_SHOULDER: "LEFT_SHOULDER",
	JOY_BUTTON_RIGHT_SHOULDER: "RIGHT_SHOULDER",
	JOY_BUTTON_DPAD_UP: "DPAD_UP",
	JOY_BUTTON_DPAD_DOWN: "DPAD_DOWN",
	JOY_BUTTON_DPAD_LEFT: "DPAD_LEFT",
	JOY_BUTTON_DPAD_RIGHT: "DPAD_RIGHT",
	JOY_BUTTON_MISC1: "MISC1",
	JOY_BUTTON_PADDLE1: "PADDLE1",
	JOY_BUTTON_PADDLE2: "PADDLE2",
	JOY_BUTTON_PADDLE3: "PADDLE3",
	JOY_BUTTON_PADDLE4: "PADDLE4",
	JOY_BUTTON_TOUCHPAD: "TOUCHPAD",
}

const JoyAxisNameMap := {
	JOY_AXIS_LEFT_X: "LEFT_X",
	JOY_AXIS_LEFT_Y: "LEFT_Y",
	JOY_AXIS_RIGHT_X: "RIGHT_X",
	JOY_AXIS_RIGHT_Y: "RIGHT_Y",
	JOY_AXIS_TRIGGER_LEFT: "TRIGGER_LEFT",
	JOY_AXIS_TRIGGER_RIGHT: "TRIGGER_RIGHT",
}


var default_profile: GinProfile

signal device_connection_changed(gin_device_id, connected)
signal profile_loaded(profile)
signal profile_unloaded(profile)


func create_player(player_id, devices:=PackedInt32Array(), profile:GinProfile=null)->bool:
	if _players.has(player_id):
		return false
	var player := PlayerData.new()
	player.id = player_id
	_players[player_id] = player
	if devices.size() > 0:
		for d in devices:
			claim_device(player_id, d)

	if profile:
		set_profile(player_id, profile)
	elif default_profile:
		set_profile(player_id, default_profile)

	return true


func delete_player(player_id)->void:
	var player: PlayerData = _players.get(player_id)
	if player:
		for d in player.claimed_devices:
			unclaim_device(player_id, d)
		#warning-ignore:return_value_discarded
		_players.erase(player_id)


func claim_device(player_id, gin_device_id:int)->bool:
	var player_data: PlayerData = _players.get(player_id)
	if player_data and not gin_device_id in player_data.claimed_devices:
		var ps = _device_player_map.get(gin_device_id)
		if ps != null:
			ps.append(player_data)
		else:
			_device_player_map[gin_device_id] = [player_data]
		var devices: PackedInt32Array = player_data.claimed_devices
		devices.append(gin_device_id)
		player_data.claimed_devices = devices
		return true
	return false


func connect_input(player_id, action: String, callable: Callable, flags: int = 0)->int:
	var player_data: PlayerData = _players.get(player_id)
	if player_data:
		return player_data.handled_signal_obj.connect(action, callable, flags)
	return ERR_DOES_NOT_EXIST


func connect_input_unhandled(player_id, action: String, callable: Callable, flags: int = 0)->int:
	var player_data: PlayerData = _players.get(player_id)
	if player_data and player_data.unhandled_signal_obj.has_user_signal(action):
		return player_data.unhandled_signal_obj.connect(action, callable, flags)
	return ERR_DOES_NOT_EXIST


func disconnect_input(player_id, action:String, callable:Callable)->void:
	var player_data: PlayerData = _players.get(player_id)
	if player_data:
		player_data.handled_signal_obj.disconnect(action, callable)


func disconnect_input_unhandled(player_id, action:String, callable:Callable)->void:
	var player_data: PlayerData = _players.get(player_id)
	if player_data:
		player_data.unhandled_signal_obj.disconnect(action, callable)


## Returns gg_device_ids for all connected/enabled devices
func get_device_ids()->PackedInt32Array:
	var rv := PackedInt32Array([DEVICE_MOUSE, DEVICE_KEYBOARD])
	if DisplayServer.has_feature(DisplayServer.FEATURE_TOUCHSCREEN):
		rv.append(DEVICE_TOUCH)
	if _midi_enabled:
		rv.append(DEVICE_MIDI)
	rv.append_array(Input.get_connected_joypads())
	return rv


static func get_device_name(gg_device_id:int)->String:
	if gg_device_id >= DEVICE_JOYPAD_START:
		return "joypad %d %s" % [gg_device_id, Input.get_joy_name(gg_device_id)]
	else:
		return NON_JOYPAD_DEVICE_NAMES[gg_device_id]


func get_player_devices(player_id)->PackedInt32Array:
	var player: PlayerData = _players.get(player_id)
	if player:
		return  player.claimed_devices
	return PackedInt32Array()


func get_profile(name:String)->GinProfile:
	return _profiles.get(name)


func get_profiles()->Array:
	return _profiles.values()


func load_profile(profile:GinProfile)->int:
	if profile == null:
		return ERR_DOES_NOT_EXIST
	if _profiles.has(profile.resource_name):
		return ERR_ALREADY_EXISTS
	_profiles[profile.resource_name] = profile
	emit_signal("profile_loaded", profile)
	return OK


func set_midi_enabled(enabled:bool)->void:
	if _midi_enabled != enabled and OS.get_name() in MIDI_ENABLED_PLATFORMS:
		_midi_enabled = enabled
		if enabled:
			OS.open_midi_inputs()
		else:
			OS.close_midi_inputs()
		emit_signal("device_connection_changed", DEVICE_MIDI, enabled)


func set_profile(player_id, profile:GinProfile)->void:
	var player: PlayerData = _players.get(player_id)
	if not player: return
	# Erase previous actions
	player.action_links.clear()
	player.handled_signal_obj = RefCounted.new()
	player.unhandled_signal_obj = RefCounted.new()
	player.profile = profile
	for action in profile.actions:
		var action_data
		if action is GinActionScalar:
			action_data = ScalarActionData.new()
			player.handled_signal_obj.add_user_signal(action.resource_name, SCALAR_SIGNAL_ARGS)
			player.unhandled_signal_obj.add_user_signal(action.resource_name, SCALAR_SIGNAL_ARGS)
		elif action is GinActionVector:
			action_data = VectorActionData.new()
			player.handled_signal_obj.add_user_signal(action.resource_name, VECTOR_SIGNAL_ARGS)
			player.unhandled_signal_obj.add_user_signal(action.resource_name, VECTOR_SIGNAL_ARGS)
		else:
			push_error("Unknown action (%s) in profile (%s)!" % [action.to_string(), profile.resource_path])
			continue
		action_data.init(action, player, profile)
		player.actions.append(action_data)
		for ieint in action_data.get_inputs():
			player.add_action_link(ieint, action_data)


func unload_profile(name:String)->void:
	var profile: GinProfile =_profiles.get(name)
	if profile:
		#warning-ignore:return_value_discarded
		_profiles.erase(name)
		emit_signal("profile_unloaded", profile)


func unclaim_device(player_id, gin_device_id:int)->void:
	var player_data: PlayerData = _players.get(player_id)
	if player_data:
		var ps: Array = _device_player_map.get(gin_device_id)
		if ps != null:
			ps.erase(player_data)
			var devices := player_data.claimed_devices
			devices.remove_at(player_data.claimed_devices.find(gin_device_id))
			player_data.claimed_devices = devices
			for action in player_data.actions:
				action.clear_cache()


static func input_event_int(ie:InputEvent, force_mods:= false)->int:
	if ie is InputEventWithModifiers:
		var mods: int = (int(ie.alt_pressed) << BIT_MOD_ALT) | (int(ie.shift_pressed) << BIT_MOD_SHIFT)
		if OS.get_name() == "macOS":
			mods |= (int(ie.meta_pressed) << BIT_MOD_CMD) | (int(ie.ctrl_pressed) << BIT_MOD_META)
		else:
			mods |= (int(ie.meta_pressed) << BIT_MOD_META) | (int(ie.ctrl_pressed) << BIT_MOD_CMD)
		mods |= int(force_mods or mods) << BIT_MOD_FORCE
		if ie is InputEventKey:
			return INPUT_EVENT_ID.InputEventKey | mods | ie.keycode
		elif ie is InputEventMouseButton:
			return INPUT_EVENT_ID.InputEventMouseButton | mods | ie.button_index
		elif ie is InputEventMouseMotion:
			return INPUT_EVENT_ID.InputEventMouseMotion | mods
		elif ie is InputEventMagnifyGesture:
			return INPUT_EVENT_ID.InputEventMagnifyGesture | mods
		elif ie is InputEventPanGesture:
			return INPUT_EVENT_ID.InputEventPanGesture | mods
		else:
			return 0
	elif ie is InputEventJoypadButton:
		return INPUT_EVENT_ID.InputEventJoypadButton | ie.button_index
	elif ie is InputEventJoypadMotion:
		return INPUT_EVENT_ID.InputEventJoypadMotion | ie.axis
	else:
		return INPUT_EVENT_ID.get(ie.get_class(), 0)


static func input_int_to_dict(ie:int)->Dictionary:
	var type: int = ie & MASK_TYPE
	var rv := {type=INPUT_EVENT_ID_STRING[min(type >> IE_INT_TYPE_START, 9)]}
	# ie with modifiers
	if type >= INPUT_EVENT_ID._MODIFIERS_START and type <= INPUT_EVENT_ID._MODIFIERS_END:
		if ie & MASK_MOD_ALT:
			rv.alt = true
		if ie & MASK_MOD_SHIFT:
			rv.shift = true
		if ie & MASK_MOD_META:
			rv.meta = true
		if ie & MASK_MOD_CMD:
			rv.cmd = true
		if not (ie & MASK_MOD_ALL_BUT_FORCE) and (ie & MASK_MOD_FORCE):
			rv.no_mods = true

	if type >= INPUT_EVENT_ID._NATIVE_START and type <= INPUT_EVENT_ID._NATIVE_END:
		rv.is_absolute = bool(ie & MASK_IS_ABSOLUTE)

	if type == INPUT_EVENT_ID.InputEventKey:
		rv.key = OS.get_keycode_string(ie & MASK_DATA)
	elif type == INPUT_EVENT_ID.InputEventJoypadButton:
		rv.button = JoyButtonNameMap.get(ie & MASK_DATA, "INVALID")
	elif type == INPUT_EVENT_ID.InputEventJoypadMotion:
		rv.axis = JoyAxisNameMap.get(ie & MASK_DATA, "INVALID")
	elif type == INPUT_EVENT_ID.InputEventMouseButton:
		rv.button = MOUSE_BUTTON_STRING[min(ie & MASK_DATA, 8)]
	return rv


static func dict_to_input_int(ie:Dictionary)->int:
	var rv := 0
	var raw_type = ie.get("type")
	if typeof(raw_type) != TYPE_STRING:
		return 0
	var type: int = INPUT_EVENT_ID_STRING_CAPS.find(raw_type.to_upper())
	if raw_type.to_upper() == "MOUSEMOTION":
		pass
	if type == -1:
		return 0
	type <<= IE_INT_TYPE_START
	rv |= type

	if type >= INPUT_EVENT_ID._MODIFIERS_START and type <= INPUT_EVENT_ID._MODIFIERS_END:
		var alt   = ie.get("alt",   false)
		var shift = ie.get("shift", false)
		var ctrl  = ie.get("ctrl",  false)
		var meta  = ie.get("meta",  false)
		var cmd   = ie.get("cmd",   false)
		var no_mods = ie.get("no_mods", false)
		if not (typeof(alt) == TYPE_BOOL and typeof(shift) == TYPE_BOOL and typeof(ctrl) == TYPE_BOOL and typeof(meta) == TYPE_BOOL and typeof(cmd) == TYPE_BOOL and typeof(no_mods) == TYPE_BOOL):
			return 0
		var mods: int = (int(alt) << BIT_MOD_ALT) | (int(shift) << BIT_MOD_SHIFT) | (int(meta) << BIT_MOD_META) | (int(cmd or ctrl) << BIT_MOD_CMD)
		rv |= mods | (int(no_mods or mods) << BIT_MOD_FORCE)

	if type >= INPUT_EVENT_ID._NATIVE_START and type <= INPUT_EVENT_ID._NATIVE_END:
		var is_absolute = ie.get("is_absolute", false)
		if not typeof(is_absolute) == TYPE_BOOL:
			return 0
		elif is_absolute:
			rv |= MASK_IS_ABSOLUTE

	if type == INPUT_EVENT_ID.InputEventKey:
		var key = ie.get("key")
		if typeof(key) == TYPE_STRING:
			rv |= OS.find_keycode_from_string(key)
		elif typeof(key) == TYPE_INT:
			rv |= key
		else:
			return 0
	elif type == INPUT_EVENT_ID.InputEventJoypadButton:
		var button = ie.get("button")
		if typeof(button) == TYPE_STRING:
			var joy_button_id = JoyButtonNameMap.find_key(button)
			if joy_button_id != null:
				rv |= joy_button_id
		elif typeof(button) == TYPE_INT:
			rv |= button
		else:
			return 0
	elif type == INPUT_EVENT_ID.InputEventJoypadMotion:
		var axis = ie.get("axis")
		if typeof(axis) == TYPE_STRING:
			var joy_axis_id = JoyAxisNameMap.find_key(axis)
			if joy_axis_id != null:
				rv |= joy_axis_id
		elif typeof(axis) == TYPE_INT:
			rv |= axis
		else:
			return 0
	elif type == INPUT_EVENT_ID.InputEventMouseButton:
		var raw_button = ie.get("button")
		if typeof(raw_button) == TYPE_STRING:
			raw_button = raw_button.to_lower()
			var button := MOUSE_BUTTON_STRING.find(raw_button)
			if button >= 0:
				rv |= button
			else:
				return 0
		elif typeof(raw_button) == TYPE_INT:
			rv |= raw_button
		else:
			return 0

	return rv


static func set_modifiers(ie_int:int, flags:int)->int:
	return ie_int & (((flags&0x1f) << IE_INT_MODIFIER_BIT_START) | ~(0x1f << IE_INT_MODIFIER_BIT_START))


var _players:Dictionary # Dictionary<Variant,PlayerData>
var _profiles:Dictionary # (String, Profile)
var _midi_enabled: bool
# mapping of event_int -> array of actions
var _device_player_map:Dictionary # (int, Array[PlayerData])

var _cmd_is_meta: bool

func _init()->void:
	var base_path: String = get_script().resource_path.get_base_dir()
	GinActionScalar = load(base_path + "/actions/gin_action_scalar.gd")
	GinActionVector = load(base_path + "/actions/gin_action_vector.gd")
	ScalarActionData = load(base_path + "/internal/scalar_action_data.gd")
	VectorActionData = load(base_path + "/internal/vector_action_data.gd")

func _input(event:InputEvent)->void:
	_input_helper(event, false)


func _unhandled_input(event:InputEvent)->void:
	_input_helper(event, true)


func _input_helper(event:InputEvent, is_unhandled:bool)->void:
	var ie_int: int = input_event_int(event)
	var dev_id: int = _device_id_from_event(event)
	for player_data in _device_player_map.get(dev_id, []):
		for act in player_data.action_links.get(ie_int, []):
			act.parse_input(ie_int, event, is_unhandled)

	if event is InputEventWithModifiers:
		if not(ie_int & MASK_MOD_ALL_BUT_FORCE) or not event.is_pressed():
			var i: int = (ie_int & ~MASK_MOD_ALL) | MASK_MOD_FORCE
			for player_data in _device_player_map.get(dev_id, []):
				for act in player_data.action_links.get(i, []):
					act.parse_input(i, event, is_unhandled)

		if ie_int & MASK_MOD_ALL_BUT_FORCE:
			ie_int &= ~MASK_MOD_ALL
			for player_data in _device_player_map.get(dev_id, []):
				for act in player_data.action_links.get(ie_int, []):
					act.parse_input(ie_int, event, is_unhandled)



func _on_joy_connection_changed(gg_device_id:int, connected:bool)->void:
	emit_signal("device_connection_changed", gg_device_id, connected)


func _notification(what:int)->void:
	if what == NOTIFICATION_WM_MOUSE_EXIT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		for player in _players.values():
			for action in player.actions:
				action.clear_cache()


static func _device_id_from_event(event:InputEvent)->int:
	if event is InputEventKey:
		return DEVICE_KEYBOARD
	elif event is InputEventMouse:
		return DEVICE_TOUCH if event.device == DEVICE_TOUCH else DEVICE_MOUSE
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device
	elif event is InputEventMIDI:
		return DEVICE_MIDI
	elif event is InputEventGesture or event is InputEventScreenDrag or event is InputEventScreenTouch:
		return DEVICE_TOUCH
	return DEVICE_INVALID


class PlayerData:
	extends RefCounted
	var id
	var claimed_devices: PackedInt32Array
	var profile: GinProfile
	var actions: Array
	var action_links: Dictionary # (int, Array[Action])
	var handled_signal_obj := RefCounted.new()
	var unhandled_signal_obj := RefCounted.new()

	func connect_input(is_unhandled:bool, action:String, callable:Callable, flags:int = 0)->int:
		if is_unhandled:
			return unhandled_signal_obj.connect(action, callable, flags)
		else:
			return handled_signal_obj.connect(action, callable, flags)

	func disconnect_input(is_unhandled:bool, action:String, callable:Callable)->void:
		if is_unhandled:
			unhandled_signal_obj.disconnect(action, callable)
		else:
			handled_signal_obj.disconnect(action, callable)

	func add_action_link(event_id:int, action)->void:
		var action_list = action_links.get(event_id)
		if action_list == null:
			action_links[event_id] = [action]
		else:
			action_list.append(action)
