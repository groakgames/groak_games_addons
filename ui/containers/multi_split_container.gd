#@tool
class_name MultiSplitContainer extends SplitContainer


## Similar to [SplitContainer] but allows for multiple splits based on the
## number of children.


## When resized whether to keep proporional sizes for controls or to keep
## absolute offsets.
@export var keep_proporton: bool = true

## Removes this node when this node is in the tree and the last [Control] child
## is removed.
@export var remove_when_empty: bool = false



var _sizes: PackedInt32Array:
	get: return _sizes
	set(value): _sizes = value; queue_sort()

var _current_drag_gap: int = -1

var _is_sorting: bool = false
#
# Public functions
#


#
# Private functions
#

var _readied: bool = false

func _init()->void:
	remove_child(get_child(0,true)) # remove the built-in dragger
	# freeing would cause crash later


func _ready()->void:
	prev_size = size
	child_entered_tree.connect(_on_child_entering_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)

	_controls = []
	for node in get_children():
		if node is Control:
			_node_visibility_connections[node] = _on_control_visibility_changed.bind(node)
			node.visibility_changed.connect(_node_visibility_connections[node])
			if node.visible:
				_control_added_helper(node, false)
	_sizes = get_even_sizes(_controls, size, get_theme_constant("separation"), vertical)
	_readied = true
	add_theme_icon_override("grabber", get_theme_icon("v_grabber" if vertical else "h_grabber"))

func _set(property: StringName, value)->bool:
	if property == &"vertical":
		vertical = value
		add_theme_icon_override("grabber", get_theme_icon("v_grabber" if vertical else "h_grabber"))
		_sizes = get_even_sizes(_controls, size, get_theme_constant("separation"), vertical)
		return true
	elif property == &"split_offset":
			# _set appears to only be called outside of this class

#			if _controls.size() > 2:
#				split_offset = move_gap(0, value)
#				if _sizes[0] != split_offset:
#					_sizes[0] = split_offset
#			else:
#				split_offset = value
			return true
	return false


func _get_min_size()->Vector2:
	var min_sz := Vector2()
	var max_h := 0
	var v: int = int(vertical)
	var h: int = 1-int(vertical)
	var count: int = 0
	var separation: int = get_theme_constant("separation")
	for c in get_children():
		if c is Control and c.visible:
			var sz: Vector2 = c.get_combined_minimum_size()
			min_sz[v] += sz[v] + separation
			max_h = maxi(max_h, sz[h])
			min_sz[h] = max_h
			count += 1
	if count > 1:
		min_sz[v] -= separation
	return min_sz


var prev_size := Vector2()

var old_split_offset: int = 0

var _sorting: bool = false
func _notification(what:int)->void:
	if what == NOTIFICATION_RESIZED:
		#_removed_control_pixels = size[int(vertical)] - prev_size[int(vertical)]
		if _readied:
			_sizes = get_sizes_after_container_size_change(_controls, _sizes, vertical, (size-prev_size)[int(vertical)])
			prev_size = size
	elif what == NOTIFICATION_SORT_CHILDREN: # _absolute should be updated before this gets hit
#		if old_split_offset != split_offset:
#			move_gap(0, split_offset - old_split_offset)
#			old_split_offset = split_offset

		_is_sorting = true
		var separation: int = get_theme_constant("separation")
		var grab_thickness: int = max(get_theme_constant("minimum_grab_thickness"), separation)
		var grab_thickness_dif: Vector2 = (grab_thickness - separation)/2 * (Vector2.DOWN if vertical else Vector2.RIGHT)

		if _controls.size() <= 0:
			split_offset = 0
		elif _controls.size() == 1:
			_sizes[0] = size[int(vertical)]
			split_offset = _sizes[0]
		var control_size: Vector2 = size
		var control_pos: Vector2 = Vector2.ZERO
		var ncontrols := _controls.size()
		for i in ncontrols:
			var control: Control = _controls[i]
			control_size[int(vertical)] = _sizes[i]
			fit_child_in_rect(control, Rect2(control_pos, control_size))
			control_pos[int(vertical)] += _sizes[i]
			if i < ncontrols-1:
				control_size[int(vertical)] = grab_thickness
				fit_child_in_rect(_grabbers[i], Rect2(control_pos-grab_thickness_dif, control_size))
			control_pos[int(vertical)] += separation
		_is_sorting = false

#
# Signal handlers
#
func _on_child_entering_tree(node:Node)->void:
	if node is Control and node.get_parent() == self and not node in _grabbers:
		_node_visibility_connections[node] = _on_control_visibility_changed.bind(node)
		node.visibility_changed.connect(_node_visibility_connections[node])
		if node.visible:
			_control_added_helper(node)



func _on_control_visibility_changed(node:Control)->void:
	if node.visible: # becoming visible
		_control_added_helper(node)
	else: # becoming invisible
		var idx: int = _controls.find(node)
		if idx >= 0:
			_control_removed_helper(node, idx)

func _on_child_exiting_tree(node:Node)->void:
	if node is Control and not node in _grabbers:
		node.visibility_changed.disconnect(_node_visibility_connections[node])
		#_node_visibility_connections.erase(node)
		var idx := _controls.find(node)
		if idx >= 0:
			_control_removed_helper(node, idx)

var _node_visibility_connections := {}

#
# Private
#

## Controls that get sorted by the
var _controls: Array[Control]

var _grabbers: Array[Control]


#
# Helper functions
#

## Moves a gap by a given delta
func move_gap(gap_idx:int, delta:int)->int:
	var result: Array = get_sizes_after_gap_move(_controls, _sizes, vertical, gap_idx, delta)
	_sizes = result[1]
	return _sizes[0]


func _control_added_helper(node:Control, fix_sizes := true)->void:
	_controls.append(node)
	if fix_sizes:
		_sizes = get_even_sizes(_controls, size, get_theme_constant("separation"), vertical)
	if _controls.size() >= 2: # create new gap
		var msd = MultiSplitDragger.new(_grabbers.size())
		_grabbers.append(msd)
		add_child(msd, false, Node.INTERNAL_MODE_BACK)
	custom_minimum_size = _get_min_size()



func _control_removed_helper(node:Control, control_idx:int)->void:
	var pix_removed := _sizes[control_idx] + get_theme_constant("separation")
	_controls.remove_at(control_idx)
	_sizes.remove_at(control_idx)
	if _controls.size() > 0:
		_sizes = get_sizes_after_container_size_change(_controls, _sizes, vertical, pix_removed)
	if _grabbers.size() > 1:
		remove_child(_grabbers.back())
		_grabbers.pop_back()
	custom_minimum_size = _get_min_size()

# returns [real_delta, new_sizes]
static func get_sizes_after_gap_move(controls:Array[Control], old_sizes:PackedInt32Array, vertical:bool, gap_idx:int, delta:int)->Array:
	assert(controls.size() == old_sizes.size())
	if delta == 0: return [0, old_sizes]
	var ncontrols: int = controls.size()
	var temp_delta: int = delta
	var delta_sign: int = sign(delta)
	for i in range(gap_idx+1, ncontrols) if delta > 0 else range(gap_idx, -1, -1):
		var amount_shrank: int = mini(
			# pixels availbe to remove
			old_sizes[i] - controls[i].get_combined_minimum_size()[int(vertical)],
			abs(temp_delta) # amount wanted to move
		)
		old_sizes[i] -= amount_shrank
		temp_delta -= delta_sign * amount_shrank
		if temp_delta == 0: break
	delta -= temp_delta
	if delta > 0:
		old_sizes[gap_idx] += delta
	else:
		old_sizes[gap_idx+1] -= delta
	return [delta, old_sizes]


# when the container increases or reduces in size
static func get_sizes_after_container_size_change(controls:Array[Control], old_sizes:PackedInt32Array, vertical:bool, delta:int)->PackedInt32Array:
	assert(controls.size() != 0 and controls.size() == old_sizes.size())
	if delta == 0: return old_sizes

	var ncontrols: int = controls.size()
	var pix_per_ctrl: int = delta / ncontrols
	var remainder: int = delta % ncontrols
	var remainder_val: int = signi(delta)

	if delta < 0: # shrink
		# Create min_szs an array of vec2i with x being a control index
		# and y being the control min size in the direction of the
		# split container.
		# Elements are sorted from largest to smallest minimum size
		var min_szs: Array[Vector2i] = []
		for i in ncontrols:
			min_szs.append(Vector2i(i, controls[i].get_combined_minimum_size()[int(vertical)]))
		min_szs.sort_custom(func(a:Vector2i,b:Vector2i)->bool: return a.y > b.y)

		# check if the delta would cause the control with the largest minimum to go past that minimum
		if min_szs[0].y > old_sizes[min_szs[0].x]+pix_per_ctrl:
			var distribute_start: int = 0
			# use parts of delta up
			for next_idx in range(1, ncontrols):
				var min_data := min_szs[next_idx-1]
				var a: int = (old_sizes[min_data.x] - min_data.y)
				delta += a
				distribute_start = next_idx
				old_sizes[min_data.x] = min_data.y
				if min_szs[next_idx].y <= old_sizes[min_szs[next_idx].x]+(delta/ncontrols):
					break # we can distribute the rest! break!
			# distribute the rest
			pix_per_ctrl = delta / (ncontrols-distribute_start)
			remainder = delta % (ncontrols-distribute_start)
			if remainder != 0:
				var remainder_start: int = randi() % ncontrols + distribute_start
				for i in range(remainder_start, remainder_start+abs(remainder)):
					old_sizes[min_szs[i % ncontrols].x] -=  1
			if pix_per_ctrl != 0:
				for i in range(distribute_start, ncontrols):
					old_sizes[min_szs[i].x] += pix_per_ctrl
			return old_sizes

	if remainder != 0:
		var remainder_start: int = randi() % ncontrols
		for i in range(remainder_start,remainder_start+abs(remainder)):
			old_sizes[i % ncontrols] += remainder_val
	if pix_per_ctrl != 0:
		for i in ncontrols:
			old_sizes[i] += pix_per_ctrl
	return old_sizes


# Evens out the sizes as much as possible
static func get_even_sizes(controls:Array[Control], container_size:Vector2i, separation:int, vertical:bool)->PackedInt32Array:
	var ncontrols := controls.size()
	if ncontrols == 0: return PackedInt32Array()
	# Create min_szs an array of vec2i with x being a control index
	# and y being the control min size in the direction of the
	# split container.
	# Elements are sorted from largest to smallest minimum size
	var min_szs: Array[Vector2i] = []
	for i in ncontrols:
		min_szs.append(Vector2i(i, controls[i].get_combined_minimum_size()[int(vertical)]))
	min_szs.sort_custom(func(a:Vector2i,b:Vector2i)->bool: return a.y > b.y)

	var pix_to_distribute: int = container_size[int(vertical)] - ((ncontrols - 1) * separation)
	var pix_per_ctrl: int = pix_to_distribute / ncontrols
	var remainder: int = pix_to_distribute % ncontrols
	var final_sizes: PackedInt32Array = []
	final_sizes.resize(ncontrols)

	if min_szs[0].y <= pix_per_ctrl:
		# if the evenly distributed amount is greater than the largest minimum size
		# just use pix_per_ctrl
		var start := 0

		if pix_per_ctrl != 0:
			for i in range(ncontrols):
				final_sizes[i] = pix_per_ctrl
		if remainder != 0:
			var remainder_start: int = randi() % ncontrols
			for i in range(remainder_start,remainder_start+remainder):
				final_sizes[i % ncontrols] += 1
	else:
		var distribute_start: int = 0
		# reserve portions of pix_to_distribute for the largest minimum sizes
		# until the rest can be distributed to the other controls
		for next_idx in range(1, ncontrols):
			var min_data := min_szs[next_idx-1]
			pix_to_distribute -= min_data.y
			distribute_start = next_idx
			final_sizes[min_data.x] = min_data.y
			if min_szs[next_idx].y <= pix_to_distribute / (min_szs.size()-distribute_start):
				break # we can distribute the rest! break!
		# distribute the rest
		pix_per_ctrl = pix_to_distribute / (min_szs.size()-distribute_start)
		remainder = pix_to_distribute % (min_szs.size()-distribute_start)
		if pix_per_ctrl != 0:
			for i in range(distribute_start, ncontrols):
				final_sizes[min_szs[i].x] = pix_per_ctrl
		if remainder != 0:
			var remainder_start: int = randi() % ncontrols
			for i in range(remainder_start,remainder_start+remainder):
				final_sizes[i % ncontrols] += 1
	return final_sizes



class MultiSplitDragger:
	extends Control

	var _gap_idx: int = -1
	var _dragging: bool = false
	var _mouse_inside: bool = false

	func _init(gap_idx := -1)->void:
		_gap_idx = gap_idx

	func _ready()->void:
		var parent: MultiSplitContainer = get_parent()
		if parent.vertical:
			anchor_right = 1
		else:
			anchor_bottom = 1

	func _input(event:InputEvent)->void:
		if _dragging and event is InputEventMouseMotion:
			var parent: MultiSplitContainer = get_parent()
			var actual: int = parent.move_gap(_gap_idx, (event.global_position - global_position)[int(parent.vertical)])
			if actual:
				position[int(parent.vertical)] += actual

	func _gui_input(event:InputEvent)->void:
		if event is InputEventMouseButton:
			var parent: MultiSplitContainer = get_parent()
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed and parent._current_drag_gap == -1:
					_dragging = true
					mouse_default_cursor_shape = CURSOR_VSPLIT if parent.vertical else CURSOR_HSPLIT
					parent._current_drag_gap = _gap_idx
				elif not event.pressed and _dragging:
					_dragging = false
					mouse_default_cursor_shape = CURSOR_ARROW
					parent._current_drag_gap = -1
					queue_redraw()

	func _draw()->void:
		if _dragging or (_mouse_inside and get_parent()._current_drag_gap == -1):
			var parent: MultiSplitContainer = get_parent()
			var grabber_tex := parent.get_theme_icon("v_grabber" if parent.vertical else "h_grabber")
			draw_texture(grabber_tex, (size - grabber_tex.get_size())/2)

	func _notification(what:int)->void:
		match what:
			NOTIFICATION_MOUSE_ENTER:
				_mouse_inside = true
				mouse_default_cursor_shape = CURSOR_VSPLIT if get_parent().vertical else CURSOR_HSPLIT
				queue_redraw()
			NOTIFICATION_MOUSE_EXIT:
				_mouse_inside = false
				if not _dragging:
					mouse_default_cursor_shape = Control.CURSOR_ARROW
				queue_redraw()
