class_name GinAction extends Resource

export var deadzone: float = 0.01

enum VECTOR_INPUT_TYPE {
	UP
	RIGHT
	DOWN
	LEFT
	NATIVE_INPUT_START
	ABSOLUTE # absolute native input
	RELATIVE # relative native input
}
