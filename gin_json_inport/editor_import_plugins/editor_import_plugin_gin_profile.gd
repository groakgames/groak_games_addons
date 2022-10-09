tool
extends EditorImportPlugin

func get_importer_name()->String:
	return "groak.games.gin.profile"

func get_visible_name()->String:
	return "Gin input profile"

func get_recognized_extensions()->Array:
	return ["ginprofile", "json"]

func get_save_extension()->String:
	return "ginprofile"

func get_resource_type()->String:
	return "Resource"

func get_preset_count()->int:
	return 1

func get_preset_name(i:int)->String:
	return "Default"

func get_import_options(i:int)->Array:
	return [{"name": "my_option", "default_value": false}]

func import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array)->int:
	var file = File.new()
	if file.open(source_file, File.READ) != OK:
		return FAILED

	var ginprofile := GinProfile.new()
	# Fill the Mesh with data read in "file", left as an exercise to the reader

	var filename = save_path + "." + get_save_extension()
	return ResourceSaver.save(filename, ginprofile)
