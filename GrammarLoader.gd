@tool

extends ResourceFormatLoader
class_name GrammarLoader

var loaded = {}

func _exists(path: String) -> bool:
	return true

func _get_recognized_extensions() -> PackedStringArray:
	return ["grammar"]
	
func _get_resource_script_class(path: String) -> String:
	return "Grammar"
	
func _get_resource_type(path: String) -> String:
	return "Resource"
	
func _handles_type(type: StringName) -> bool:
	return type == "Resource"

func _load(path: String, original_path: String, _use_sub_threads: bool, cache_mode: int) -> Variant:
	if loaded.has(path) and cache_mode != CacheMode.CACHE_MODE_REPLACE:
		return self.loaded[path]
		
	else:
		var file = FileAccess.open(path, FileAccess.READ)
		
		if file == null:
			return Error.ERR_FILE_CANT_OPEN
		
		var len = file.get_length()
		file.seek(0)
		var packed = file.get_var()
		
		var grammar_resource = Grammar.new()
		grammar_resource.unpack(packed)
		
		self.loaded[path] = grammar_resource
		
		return grammar_resource
