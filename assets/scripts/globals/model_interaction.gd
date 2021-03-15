extends Node

enum PointerDevice {FREE, HOVER, DRAGGING}
enum SelectionModifierKey {NONE, ADD_ITEM, REMOVE_ITEM}

var _pointer_device_state: int = PointerDevice.FREE
var _selection_modifier_key_state: int = SelectionModifierKey.NONE

var _hovering_over : Node
var _drag_start : Vector2
var _drag_dirty : bool
var _selected = []		# TODO replace with Dictionary once FeaBase has ids

const MIN_WINDOW_SELECTION_SIZE := 10		# pixels

func _ready():
	var _success = ViewEvents.connect("hovered_over", self, "_on_hovered_over")
	_success = ViewEvents.connect("hovered_from", self, "_on_hovered_from")
	_success = ViewEvents.connect("select_many", self, "_on_select_many")


func _unhandled_input(event: InputEvent):
	_selection_modifier_key_state = transition_modifier_key_state(event)
	_pointer_device_state = transition_pointer_device_state(event)


""" MODEL ELEMENT SELECTION LOGIC """

func select_single(element: FeaBase):
	element.select()
	_selected.append(element)


func deselect_single(element: FeaBase):
	element.deselect()
	var element_index = _selected.find(element)
	if element_index >= 0:
		_selected.remove(element_index)
	

func clear_selection():
	for item in _selected:
		var element = item as FeaBase
		if element:
			element.deselect()
	_selected = []


func select_by_mode(mode: int, element: FeaBase) -> void:
	match mode:
		ModelInteraction.SelectionModifierKey.NONE:
			select_single(element)		
		ModelInteraction.SelectionModifierKey.ADD_ITEM:
			if not _selected.has(element):
				select_single(element)		
		ModelInteraction.SelectionModifierKey.REMOVE_ITEM:
			deselect_single(element)		
		_:
			assert(false, "Invalid model interaction state.")


func _on_select_single(mode: int, element: FeaBase) -> void:	
	if mode == ModelInteraction.SelectionModifierKey.NONE:
		clear_selection()
	
	select_by_mode(mode, element)


func _on_select_many(mode: int, elements: Array) -> void:
	print("tried to select ", elements.size())
	if mode == ModelInteraction.SelectionModifierKey.NONE:
		clear_selection()
	
	for item in elements:
		var element = item as FeaBase
		if not element:
			continue		
		select_by_mode(mode, element)


func _on_selection_clear() -> void:
	clear_selection()


func _on_selection_clear_maybe(mode: int) -> void:
	match mode:		
		ModelInteraction.SelectionModifierKey.NONE:
			clear_selection()
		ModelInteraction.SelectionModifierKey.ADD_ITEM, \
		ModelInteraction.SelectionModifierKey.REMOVE_ITEM:
			pass
		_:
			assert(false, "Invalid model interaction state.")


func _on_hovered_over(element: Node) -> void:
	_hovering_over = element


func _on_hovered_from(element: Node) -> void:
	if _hovering_over == element:
		_hovering_over = null


""" STATE TRANSITIONS """

func transition_pointer_device_state(event: InputEvent) -> int:
	match _pointer_device_state:
		
		PointerDevice.FREE:
			if event.is_action_pressed("ui_cancel"):
				_on_selection_clear()
				mark_input_as_handled()
			
			if event.is_action_pressed("pointer_device_select"):
				reset_drag(event)
				mark_input_as_handled()
				ViewEvents.emit_signal("disable_camera_movement")
				return PointerDevice.DRAGGING
			
			if _hovering_over:
				return PointerDevice.HOVER
			
			return PointerDevice.FREE	
			
		PointerDevice.HOVER:
			if event.is_action_pressed("ui_cancel"):
				_on_selection_clear()
				mark_input_as_handled()
				
			if event.is_action_pressed("pointer_device_select"):
				reset_drag(event)
				mark_input_as_handled()
				ViewEvents.emit_signal("disable_camera_movement")
				return PointerDevice.DRAGGING
			
			if not _hovering_over:
				return PointerDevice.FREE
				
			return PointerDevice.HOVER
				
		PointerDevice.DRAGGING:
			if event.is_action_pressed("ui_cancel"):
				# Drag will not be committed, but do not clear selection as this simply indicates the user
				# cancelled the drag activity
				_drag_dirty = true
				mark_input_as_handled()
			
			if event.is_action_released("pointer_device_select"):
				if not _drag_dirty:
					var drag_end = event.position
					if _drag_start.distance_to(drag_end) < MIN_WINDOW_SELECTION_SIZE:
						# Attempts a single selection
						if _hovering_over:
							_on_select_single(_selection_modifier_key_state, _hovering_over)
						else:
							_on_selection_clear_maybe(_selection_modifier_key_state)
						ViewEvents.emit_signal("enable_camera_movement")
					else:
						# Attempts a window selection
						ViewEvents.emit_signal("select_within", _selection_modifier_key_state, Rect2(_drag_start, drag_end - _drag_start))
					
				mark_input_as_handled()
				return PointerDevice.HOVER if _hovering_over else PointerDevice.FREE
			
			if event is InputEventMouseMotion:
				ViewEvents.emit_signal("select_dynamic_window", Rect2(_drag_start, event.position - _drag_start))
				mark_input_as_handled()
			
			return PointerDevice.DRAGGING
			
		_:
			assert(false, "Invalid pointer device state.")
			return PointerDevice.FREE


func transition_modifier_key_state(event: InputEvent) -> int:
	match _selection_modifier_key_state:
		
		SelectionModifierKey.NONE:
			if event.is_action_pressed("keydown_add_to_selection"):
				mark_input_as_handled()
				return SelectionModifierKey.ADD_ITEM
			if event.is_action_pressed("keydown_remove_from_selection"):
				mark_input_as_handled()
				return SelectionModifierKey.REMOVE_ITEM
			
			return SelectionModifierKey.NONE
			
		SelectionModifierKey.ADD_ITEM:
			if event.is_action_released("keydown_add_to_selection"):
				mark_input_as_handled()
				return SelectionModifierKey.NONE
			
			return SelectionModifierKey.ADD_ITEM
			
		SelectionModifierKey.REMOVE_ITEM:
			if event.is_action_released("keydown_remove_from_selection"):
				mark_input_as_handled()
				return SelectionModifierKey.NONE
			
			return SelectionModifierKey.REMOVE_ITEM
		
		_:
			assert(false, "Invalid modifier key state")
			return SelectionModifierKey.NONE

func mark_input_as_handled():
	get_tree().set_input_as_handled()
	

func reset_drag(event: InputEvent):
	_drag_start = event.position
	_drag_dirty = false
