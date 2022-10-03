@tool
class_name NodeFinder extends Finder

@export var path: String = ""

func find()->Object:
	var obj: Node = Engine.get_main_loop().root.get_node_or_null(NodePath(path))
	return obj if not enforce_type_mode or _check_type(obj) else null
