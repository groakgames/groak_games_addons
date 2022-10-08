extends Node
# AutoLoad GGInput

enum {
	DEVICE_MIDI = -4
	DEVICE_KEYBOARD = -3
	DEVICE_MOUSE = -2
	DEVICE_TOUCH = -1 # Any touch input, gestures, emulated mouse, input from touch screen
	DEVICE_JOYPAD_START = 0
}

const NON_JOYPAD_DEVICE_NAMES := {
	DEVICE_MIDI: "midi",
	DEVICE_KEYBOARD: "keyboard",
	DEVICE_MOUSE: "mouse",
	DEVICE_TOUCH: "touch"
}

const MIDI_ENABLED_PLATFORMS := PoolStringArray(["X11", "OSX", "Windows"])

signal device_connection_changed(gg_device_id, connected)


var profile_directory: String = "user://input_profiles"
var default_profile: InputProfile


func claim_device(input_player_id, device:int)->bool:
	var player: InputPlayer = _players.get(input_player_id)
	if player:
		if device in player.claimed_devices:
			return false
		# poolarrays pass by value D: remove in 4.0
		var claimed_dev: PoolIntArray = player.claimed_devices
		claimed_dev.append(device)
		player.claimed_devices = claimed_dev
		var device_list: Array = _device_to_player_map.get(device, [])
		if not _device_to_player_map.has(device):
			_device_to_player_map[device] = device_list
		device_list.append(player)
		return true
	return false


func connect_input(player_id, action:String, target:Object, method:String, binds:=[], flags := 0)->int:
	var player: InputPlayer =_players.get(player_id)
	if player:
		return player.profile.connect_input(action, target, method, binds, flags)
	return ERR_DOES_NOT_EXIST


func connect_unhandled_input(player_id, action:String, target:Object, method:String, bind:Array=[], flags:int=0)->int:
	assert(false)
	return ERR_BUG


# returns false if player has been created with given id
func create_player(id, input_profile: InputProfile = null, devices: PoolIntArray = [])->bool:
	if _players.has(id):
		return false
	if input_profile:
		ResourceLoader.has_cached(input_profile.resource_path)
		if not input_profile.resource_path.empty() and load(input_profile.resource_path) == input_profile:
			input_profile = input_profile.duplicate()
	else:
		input_profile = default_profile.duplicate()
	input_profile.initialize()
	var input_player = InputPlayer.new()
	_players[id] = input_player
	input_player.id = id
	input_player.profile = input_profile
	for device in devices:
		claim_device(id, device)
	return true


func delete_player(input_player_id)->bool:
	var player: InputPlayer = _players.get(input_player_id)
	if player:
		for device in player.claimed_devices:
			(_device_to_player_map[device] as Array).erase(player.id)
		return _players.erase(input_player_id)
	return false


## Returns gg_device_ids for all connected/enabled devices
func get_device_ids()->PoolIntArray:
	var rv := PoolIntArray([DEVICE_MOUSE, DEVICE_KEYBOARD])
	if OS.has_touchscreen_ui_hint():
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


func get_device_players(device)->Array:
	var players: Array = _device_to_player_map.get(device, [])
	var player_ids := []
	for p in players:
		player_ids.append(p.id)
	return player_ids


func get_player_devices(player_id)->PoolIntArray:
	var player: InputPlayer = _players.get(player_id)
	if player:
		return PoolIntArray(player.claimed_devices)
	return PoolIntArray()


func load_saved_profiles()->void:
	var dir := Directory.new()
	if dir.open(profile_directory) == OK:
		dir.list_dir_begin(true, true)
		var file_name := dir.get_next()
		while file_name:
			if not dir.current_is_dir():
				var profile: InputProfile = ResourceLoader.load(dir.get_current_dir() + "/" + file_name, "InputProfile", true)
				if profile:
					_profile_map[profile.resource_name] = profile
			file_name = dir.get_next()
		dir.list_dir_end()


func save_player_profile(input_player_id)->int:
	var player: InputPlayer = _players.get(input_player_id)
	if player:
		return ResourceSaver.save(profile_directory+"/"+player.profile.resource_name, player.profile)
	return ERR_DOES_NOT_EXIST


func set_midi_enabled(enabled:bool)->void:
	if _midi_enabled != enabled and OS.get_name() in MIDI_ENABLED_PLATFORMS:
		_midi_enabled = enabled
		if enabled:
			OS.open_midi_inputs()
		else:
			OS.close_midi_inputs()
		emit_signal("device_connection_chanaged", DEVICE_MIDI, enabled)


func set_player_profile(input_player_id, profile:InputProfile)->bool:
	var player: InputPlayer = _players.get(input_player_id)
	if player:
		player.profile = profile
		return true
	return false


func unclaim_device(input_player_id, gg_device_id:int)->bool:
	var player: InputPlayer = _players.get(input_player_id)
	if player and gg_device_id in player.claimed_devices:
		var temp := Array(player.claimed_devices)
		temp.erase(gg_device_id)
		player.claimed_devices = PoolIntArray(temp)
		_device_to_player_map[gg_device_id].erase(player)
		return true
	return false


#
# Private
#


var _device_to_player_map: Dictionary = {
	DEVICE_MIDI: [],
	DEVICE_KEYBOARD: [],
	DEVICE_MOUSE: [],
	DEVICE_TOUCH: []
}
var _midi_enabled: bool = false
var _players: Dictionary
var _profile_map: Dictionary = {}


func _ready()->void:
	Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")


func _input(event:InputEvent)->void:
	# Get players which claim the device associated with the event.
	var players: Array
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		players = _device_to_player_map.get(event.device, [])
	elif event is InputEventScreenDrag or event is InputEventScreenTouch:
		players = _device_to_player_map.get(DEVICE_TOUCH)
	elif event is InputEventWithModifiers: # InputEventGesture , InputEventKey , InputEventMouse
		if event is InputEventKey:
			players = _device_to_player_map.get(DEVICE_KEYBOARD)
		elif event is InputEventGesture:
			players = _device_to_player_map.get(DEVICE_TOUCH)
		elif event is InputEventMouse:
			players = _device_to_player_map.get(DEVICE_TOUCH if event.device == DEVICE_TOUCH else DEVICE_MOUSE)
		else:
			push_warning("Unhandled input! %s" % event.as_text())
			return
	elif event is InputEventMIDI:
		players = _device_to_player_map.get(DEVICE_MIDI)
	else:
		push_warning("Unhandled input! %s" % event.as_text())
		return

	for p in players:
		p.profile.process_input(event)


func _on_joy_connection_changed(gg_device_id:int, connected:bool)->void:
	emit_signal("device_connection_changed", gg_device_id, connected)



class InputPlayer:
	extends Reference
	var id
	var claimed_devices:= PoolIntArray([])
	var profile
