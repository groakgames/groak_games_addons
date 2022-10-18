tool
extends EditorPlugin

const CUSTOM_TYPES: Array = [
	["GinProfile",      "Resource", preload("gin_profile.gd"),               null],
	["GinAction",       "Resource", preload("actions/gin_action.gd"),        null],
	["GinActionScalar", "Resource", preload("actions/gin_action_scalar.gd"), null],
	["GinActionVector", "Resource", preload("actions/gin_action_vector.gd"), null],
]

const CUSTOM_AUTOLOADS: Array = [
	PoolStringArray(["Gin", "/gin.gd"])
]

func _enter_tree()->void:
	var local_path: String = (get_script() as Script).resource_path.get_base_dir()

	# Add Autoloads
	for autoload_info in CUSTOM_AUTOLOADS:
		add_autoload_singleton(autoload_info[0],local_path+autoload_info[1])

	# Add Custom Types
	for type_info in CUSTOM_TYPES:
		callv("add_custom_type", type_info)


func _exit_tree()->void:
	var local_path: String = (get_script() as Script).resource_path.get_base_dir()

	# Remove Autoloads
	for autoload_info in CUSTOM_AUTOLOADS:
		remove_custom_type(autoload_info[0])

	# Remove Custom Types
	for type_info in CUSTOM_TYPES:
		remove_custom_type(type_info[0])


func add_custom_type(type:String, base:String, script:Script, icon:Texture)->void:
	if type_exists(type):
		printerr("Could not add type %s, Already Exists! " % type)
	.add_custom_type(type, base, script, icon)
