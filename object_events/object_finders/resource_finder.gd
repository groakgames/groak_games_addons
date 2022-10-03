@tool
class_name ResourceFinder extends Finder

enum CachedMode {
	ANY,
	CACHED_ONLY,
	NOT_CACHED_ONLY
}

## File path or uid
@export_file var path: String = ""
@export var cache_mode: CachedMode = CachedMode.ANY


func find()->Object:
	if cache_mode != CachedMode.ANY:
		var is_cached: bool = ResourceLoader.has_cached(path)
		if (is_cached and cache_mode == CachedMode.NOT_CACHED_ONLY) or (not is_cached and cache_mode == CachedMode.CACHED_ONLY):
			return null
	var obj: Resource = ResourceLoader.load(path)
	return obj if not enforce_type_mode or _check_type(obj) else null
