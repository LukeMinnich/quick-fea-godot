extends Control

var _window_selection_extents : Rect2

const WINDOW_SELECTION_COLOR_1 := Color(0.8, 0.8, 0.2)
const WINDOW_SELECTION_COLOR_2 := Color(0.2, 0.2, 0.8)

var _min_window_size : int

func _ready():
	var _success = ViewEvents.connect("select_within", self, "_on_window_selection_end")
	_success = ViewEvents.connect("select_dynamic_window", self, "_on_window_selection_update")
	
	_min_window_size = ModelInteraction.MIN_WINDOW_SELECTION_SIZE


func _draw():
	if _window_selection_extents && _window_selection_extents.size.length() >=_min_window_size:
		draw_rect(_window_selection_extents, WINDOW_SELECTION_COLOR_1, false, 1, true)
		# Add additional rect for better visual contrast
		draw_rect(Rect2(
			_window_selection_extents.position + Vector2(1, 1), 
			_window_selection_extents.size - Vector2(2, 2)),
			WINDOW_SELECTION_COLOR_2, false, 1.0, true)


func _on_window_selection_update(rect: Rect2):
	_window_selection_extents = rect
	update()


func _on_window_selection_end(_mode: int , _rect: Rect2):
	_window_selection_extents = Rect2()
	update()
