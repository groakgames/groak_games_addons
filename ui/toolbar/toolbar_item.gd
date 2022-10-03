extends Resource
class_name ToolbarItem

enum ToolBarButtonType {
	NORMAL,
	CHECK,
	RADIO,
}

@export var path: String
@export var button_type:ToolBarButtonType = ToolBarButtonType.NORMAL
@export var shortcut:Shortcut
@export var icon:Texture
@export var handler: Resource

