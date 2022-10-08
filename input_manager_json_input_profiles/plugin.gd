tool
extends EditorPlugin

const CUSTOM_TYPES: Array = [
	["JsonInputProfileUtil", "Reference", preload("json_input_profile_util.gd"), null],
	["ResourceFormatLoaderJSONInputProfile", "ResourceFormatLoader", preload("resouce_format_loader_json_input_profile.gd"), null],
	["ResourceFormatSaverJSONInputProfile", "ResourceFormatSaver", preload("resouce_format_saver_json_input_profile.gd"), null],
]


var json_import_plugin: EditorImportPlugin


func _enter_tree()->void:
	var local_path: String = (get_script() as Script).resource_path.get_base_dir()
	
	# Remove plugins
	json_import_plugin = preload("editor_import_plugins/input_profile_import_plugin.gd").new()
#	add_import_plugin(json_import_plugin)
	
	# Add Custom Types
	for type_info in CUSTOM_TYPES:
		callv("add_custom_type", type_info)
		
	


func _exit_tree()->void:
	var local_path: String = (get_script() as Script).resource_path.get_base_dir()

	# Remove plugins
	remove_import_plugin(json_import_plugin)
	json_import_plugin = null

	# Remove Custom Types
	for type_info in CUSTOM_TYPES:
		remove_custom_type(type_info[0])
		
	


func add_custom_type(type:String, base:String, script:Script, icon:Texture)->void:
	if type_exists(type):
		printerr("Could not add type %s, Already Exists! " % type)
	.add_custom_type(type, base, script, icon)
