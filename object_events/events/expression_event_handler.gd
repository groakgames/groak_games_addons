@tool
class_name ExpressionEventHandler extends EventHandler

@export var expression_args: Dictionary = {}:
	get: return expression_args
	set(value):
		for v in value: if not v is String: value.erase(v)
		expression_args = value

var expression: String = ""

@export var base_instance_finder: Resource = null

@export var print_error: bool = false

func handle_event(args:Array[Variant] = [])->int:
	if not _initalized:
		var exp_arg: Array = expression_args.keys()
		exp_arg.append("event_args")
		var err := _expression.parse(expression, exp_arg)
		if err:
			push_error("Failed to parse expression: ", expression)
			return err
		_initalized = true

	var base_instance: Object = null
	if base_instance_finder:
		base_instance = base_instance_finder.find()
		if not base_instance:
			return ERR_DOES_NOT_EXIST
	var exp_arg_values: Array = expression_args.values()
	exp_arg_values.append(args)
	_expression.execute(exp_arg_values, base_instance, false)
	if _expression.has_execute_failed():
		if print_error:
			push_error(_expression.get_error_text())
		return ERR_SCRIPT_FAILED
	return OK

var _initalized: bool = false
var _expression: Expression = Expression.new()

func _get_property_list()->Array[Dictionary]:
	return [{
		"name": "expression",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_EXPRESSION,
	}]
