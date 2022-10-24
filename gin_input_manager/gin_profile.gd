class_name GinProfile extends Resource

var actions: Array # Array[Action]

func _get_property_list():
	return [{
		"name": "actions",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_NO_EDITOR
	}]

func to_configfile()->ConfigFile:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "name", resource_name)
	for action in actions:
		var section: String = "actions." + action.resource_name
		if action is GinActionScalar:
			cfg.set_value(section, "type", "scalar")
			var actions := []
			for ie in action.get_inputs():
				actions.append(Gin.input_int_to_dict(ie))
			cfg.set_value(section, "inputs", actions)
		elif action is GinActionVector:
			cfg.set_value(section, "type", "vector")
			var actions := []
			for ie in action.forward_inputs:
				actions.append(Gin.input_int_to_dict(ie))
			cfg.set_value(section, "forward", actions)

			actions = []
			for ie in action.back_inputs:
				actions.append(Gin.input_int_to_dict(ie))
			cfg.set_value(section, "back", actions)

			actions = []
			for ie in action.left_inputs:
				actions.append(Gin.input_int_to_dict(ie))
			cfg.set_value(section, "left", actions)

			actions = []
			for ie in action.right_inputs:
				actions.append(Gin.input_int_to_dict(ie))
			cfg.set_value(section, "right", actions)

			actions = []
			for ie in action.native_inputs:
				actions.append(Gin.input_int_to_dict(ie))
			cfg.set_value(section, "native", actions)
	return cfg


func from_configfile(cfg:ConfigFile)->bool:
	actions = []

	var sections := cfg.get_sections()
	resource_name = str(cfg.get_value("profile", "name", ""))

	for section in sections:
		if section.substr(0, 8) == "actions.":
			var action_name: String = section.substr(8)
			var type := str(cfg.get_value(section, "type", "")).to_upper()

			var inputs_keys: Array
			if type == "SCALAR":
				inputs_keys = ["inputs"]
			elif type == "VECTOR":
				inputs_keys = ["forward", "back", "left", "right", "native"]
			else:
				push_error("Malformed config file profile @ [%s] : type (value: %s) expected 'scalar' or 'vector'" % [section, type])
				return false

			var inputs := {}
			for input_key in inputs_keys:
				inputs[input_key] = []
				var inputs_raw = cfg.get_value(section, input_key, [])
				if typeof(inputs_raw) == TYPE_ARRAY:
					for d in inputs_raw:
						if typeof(d) == TYPE_DICTIONARY:
							var ie = Gin.dict_to_input_int(d)
							if ie == 0:
								push_error("Malformed config file profile @ [%s] : %s (value: %s)" % [section, "inputs", str(d)])
								return  false
							inputs[input_key].append(ie)
						else:
							push_error("Malformed config file profile @ [%s] : %s (value: %s) expected dictionary" % [section, "inputs", str(d)])
							return  false

			if type == "SCALAR":
				var action := GinActionScalar.new()
				action.resource_name = action_name
				action.inputs = inputs.inputs
				actions.append(action)
			elif type == "VECTOR":
				var action := GinActionVector.new()
				action.resource_name = action_name
				action.forward_inputs = inputs.forward
				action.back_inputs = inputs.back
				action.left_inputs = inputs.left
				action.right_inputs = inputs.right
				action.native_inputs = inputs.native
				actions.append(action)
	return true
