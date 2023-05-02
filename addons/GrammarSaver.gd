@tool

extends ResourceFormatSaver
class_name GrammarSaver

func _get_recognized_extensions(resource):
	return ["grammar"]
	
func _recognize(resource):
	return resource is Grammar

func _save(resource, path, flags):
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	var pack = resource.pack()
	file.seek(0)
	file.store_var(pack)
	file.close()

	return Error.OK
